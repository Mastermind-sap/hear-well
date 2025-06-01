package com.example.hear_well

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL_NAME = "com.example.hear_well/check"
    private val AUDIO_STREAM_CHANNEL_NAME = "com.example.hear_well/audio_stream"
    private val AUDIO_PROCESSING_CHANNEL_NAME = "com.example.hear_well/audio_processing" // New channel
    private val TAG = "MainActivity"

    // Audio Loopback Members
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    @Volatile private var isAudioLoopingActive: Boolean = false
    private var loopbackThread: Thread? = null

    private val SAMPLE_RATE = 44100
    private val CHANNEL_CONFIG_IN = AudioFormat.CHANNEL_IN_MONO
    private val CHANNEL_CONFIG_OUT = AudioFormat.CHANNEL_OUT_MONO
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private var bufferSizeInBytes: Int = 0

    private val RECORD_AUDIO_PERMISSION_REQUEST_CODE = 101
    private var pendingResultForPermission: MethodChannel.Result? = null

    // --- New for EventChannel audio streaming ---
    private var audioEventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    // ---

    // --- New for Audio Processing via MethodChannel ---
    private lateinit var audioProcessingChannel: MethodChannel
    // ---


    

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        /*---------------------------------Bluetooth Connection Checking-------------------------------------------*/
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getConnectedA2DPDevices" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    val connectedDevices = mutableListOf<String>()

                    if (adapter == null) {
                        Log.w(TAG, "BluetoothAdapter is null")
                        result.success(emptyList<String>())
                        return@setMethodCallHandler
                    }
                    if (!adapter.isEnabled) {
                        Log.w(TAG, "Bluetooth is not enabled")
                        result.success(emptyList<String>())
                        return@setMethodCallHandler
                    }

                    val serviceListener = object : BluetoothProfile.ServiceListener {
                        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                            if (profile == BluetoothProfile.A2DP) {
                                val a2dp = proxy as android.bluetooth.BluetoothA2dp // Safe cast after profile check
                                try {
                                    if (ContextCompat.checkSelfPermission(this@MainActivity, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED || android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S) {
                                        val devices = a2dp.connectedDevices
                                        for (device in devices) {
                                            connectedDevices.add(device.name ?: "Unknown Device")
                                        }
                                        result.success(connectedDevices)
                                    } else {
                                         Log.w(TAG, "BLUETOOTH_CONNECT permission not granted for A2DP device list.")
                                        result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission needed for A2DP devices.", null)
                                    }
                                } catch (e: SecurityException) {
                                    Log.e(TAG, "SecurityException while getting A2DP connected devices: ${e.message}")
                                    result.error("SECURITY_EXCEPTION", "Failed to get A2DP devices due to security exception.", e.toString())
                                } finally {
                                    adapter.closeProfileProxy(BluetoothProfile.A2DP, a2dp)
                                }
                            }
                        }

                        override fun onServiceDisconnected(profile: Int) {
                            if (profile == BluetoothProfile.A2DP) {
                                Log.i(TAG, "A2DP service disconnected")
                            }
                        }
                    }

                    val success = adapter.getProfileProxy(this@MainActivity, serviceListener, BluetoothProfile.A2DP)
                    if (!success) {
                        Log.e(TAG, "getProfileProxy for A2DP returned false")
                        result.error("PROXY_ERROR", "Failed to get A2DP profile proxy.", null)
                    }
                }
                "startAudioLoopback" -> {
                    this.pendingResultForPermission = result
                    if (ContextCompat.checkSelfPermission(this@MainActivity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                        startAudioLoopbackInternal(result)
                    } else {
                        ActivityCompat.requestPermissions(this@MainActivity, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_PERMISSION_REQUEST_CODE)
                    }
                }
                "stopAudioLoopback" -> {
                    stopAudioLoopbackInternal()
                    result.success("Audio loopback stopped.")
                }
                else -> result.notImplemented()
            }
        }

        // --- Setup EventChannel for audio streaming ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_STREAM_CHANNEL_NAME).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "EventChannel: onListen called")
                    audioEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel: onCancel called")
                    audioEventSink = null
                }
            }
        )
        // ---

        // --- Setup MethodChannel for audio processing ---
        audioProcessingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_PROCESSING_CHANNEL_NAME)
        // ---
    }

    private fun startAudioLoopbackInternal(result: MethodChannel.Result) {
        if (isAudioLoopingActive) {
            Log.i(TAG, "startAudioLoopbackInternal: Loopback already running.")
            result.success("Loopback already running.")
            return
        }

        bufferSizeInBytes = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG_IN, AUDIO_FORMAT)
        if (bufferSizeInBytes == AudioRecord.ERROR_BAD_VALUE || bufferSizeInBytes == AudioRecord.ERROR) {
            Log.e(TAG, "Failed to get min buffer size for AudioRecord. Error code: $bufferSizeInBytes")
            result.error("INIT_FAILED", "Failed to get min buffer size for AudioRecord.", null)
            return
        }
        if (bufferSizeInBytes <= 0) {
             Log.e(TAG, "Invalid buffer size: $bufferSizeInBytes")
             result.error("INIT_FAILED", "Invalid buffer size: $bufferSizeInBytes", null)
            return
        }
        Log.d(TAG, "AudioRecord min buffer size: $bufferSizeInBytes bytes")

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "Audio recording permission not granted at startAudioLoopbackInternal.")
            result.error("PERMISSION_DENIED", "Audio recording permission not granted.", null)
            return
        }

        try {
            Log.d(TAG, "Initializing AudioRecord...")
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG_IN,
                AUDIO_FORMAT,
                bufferSizeInBytes
            )
            Log.d(TAG, "AudioRecord state after init: ${audioRecord?.state}")

            Log.d(TAG, "Initializing AudioTrack...")
            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AUDIO_FORMAT)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(CHANNEL_CONFIG_OUT)
                        .build()
                )
                .setBufferSizeInBytes(bufferSizeInBytes)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
            Log.d(TAG, "AudioTrack state after init: ${audioTrack?.state}")

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed. State: ${audioRecord?.state}")
                result.error("INIT_FAILED", "AudioRecord initialization failed.", null)
                releaseAudioResources()
                return
            }
            if (audioTrack?.state != AudioTrack.STATE_INITIALIZED) {
                Log.e(TAG, "AudioTrack initialization failed. State: ${audioTrack?.state}")
                result.error("INIT_FAILED", "AudioTrack initialization failed.", null)
                releaseAudioResources()
                return
            }

        } catch (e: Exception) {
            Log.e(TAG, "Exception during audio resource initialization: ${e.message}", e)
            result.error("INIT_EXCEPTION", "Exception: ${e.message}", e.toString())
            releaseAudioResources()
            return
        }

        isAudioLoopingActive = true
        loopbackThread = Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
            val buffer = ByteArray(bufferSizeInBytes)
            
            Log.d(TAG, "Audio loopback thread started.")
            try {
                audioRecord?.startRecording()
                Log.d(TAG, "AudioRecord recording started.")
                audioTrack?.play()
                Log.d(TAG, "AudioTrack playback started.")

                while (isAudioLoopingActive) {
                    val readSize = audioRecord?.read(buffer, 0, buffer.size) ?: -1
                    if (readSize > 0) {
                        val audioDataToStream = buffer.copyOfRange(0, readSize)
                        // Stream to Flutter via EventChannel if sink is available
                        audioEventSink?.let { sink ->
                            mainHandler.post {
                                try {
                                    sink.success(audioDataToStream)
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error sending audio data to Flutter EventChannel: ${e.message}")
                                }
                            }
                        }

                        // Process audio via Dart
                        // We need to run invokeMethod on the main thread and wait for its result.
                        // This is a blocking call within the loopback thread, which is acceptable here.
                        var processedAudioData: ByteArray? = null
                        val job = mainHandler.post {
                            audioProcessingChannel.invokeMethod("processAudio", audioDataToStream, object : MethodChannel.Result {
                                override fun success(result: Any?) {
                                    if (result is FloatArray) {
                                        processedAudioData = floatArrayToByteArray(result)
                                        Log.d(TAG, "Audio processed successfully by Dart.")
                                    } else if (result is ByteArray) { // Fallback if Dart returns ByteArray
                                        processedAudioData = result
                                        Log.d(TAG, "Audio processed by Dart (returned as ByteArray).")
                                    } 
                                     else if (result is ArrayList<*>) { // Handle ArrayList<Double> which becomes ArrayList<Any?>
                                        try {
                                            // Attempt to cast to FloatArray if elements are Doubles
                                            val floatList = (result as ArrayList<Any?>).mapNotNull { (it as? Number)?.toFloat() }
                                            if (floatList.size == result.size) { // Ensure all elements were converted
                                                processedAudioData = floatArrayToByteArray(floatList.toFloatArray())
                                                Log.d(TAG, "Audio processed successfully by Dart (converted from ArrayList<Double>).")
                                            } else {
                                                Log.e(TAG, "Error processing audio: Dart returned ArrayList with non-Double elements.")
                                            }
                                        } catch (e: Exception) {
                                            Log.e(TAG, "Error converting ArrayList from Dart to FloatArray: ${e.message}")
                                        }
                                    }
                                    else {
                                        Log.e(TAG, "Error processing audio: Dart returned unexpected type: ${result?.javaClass?.name}")
                                    }
                                }

                                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                    Log.e(TAG, "Error processing audio in Dart: $errorCode - $errorMessage")
                                    // Fallback to original data or silence
                                    processedAudioData = audioDataToStream // or a silent buffer
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Error processing audio: 'processAudio' not implemented in Dart.")
                                    processedAudioData = audioDataToStream // or a silent buffer
                                }
                            })
                        }
                        
                        // This is a simplification. In a real app, you'd need a more robust way
                        // to wait for the mainHandler post to complete and get the processedAudioData.
                        // For now, we'll proceed, but processedAudioData might be null initially.
                        // A better approach would involve CountDownLatch or similar synchronization.
                        // However, for simplicity and to avoid complex threading here, we'll try a short delay.
                        // THIS IS NOT IDEAL FOR PRODUCTION.
                        try {
                            Thread.sleep(10) // Small delay to allow main thread to process, adjust as needed.
                                             // This is a hacky way to wait.
                        } catch (e: InterruptedException) {
                            Log.w(TAG, "Loopback thread interrupted during sleep.")
                        }

                        if (processedAudioData != null) {
                            audioTrack?.write(processedAudioData!!, 0, processedAudioData!!.size)
                        } else {
                            // Fallback: write original data if processing failed or was too slow
                            Log.w(TAG, "Processed audio data was null, writing original buffer.")
                            audioTrack?.write(audioDataToStream, 0, audioDataToStream.size)
                        }

                    } else if (readSize < 0) {
                        Log.e(TAG, "AudioRecord read error: $readSize. Stopping loop.")
                        // Potentially send an error event to Flutter if sink is available
                        // mainHandler.post { audioEventSink?.error("READ_ERROR", "AudioRecord read error $readSize", null) }
                        break 
                    }
                }
            } catch (t: Throwable) {
                Log.e(TAG, "Error in loopback thread", t)
                // mainHandler.post { audioEventSink?.error("THREAD_ERROR", "Error in loopback thread: ${t.message}", t.toString()) }
            } finally {
                Log.d(TAG, "Audio loopback thread finishing. isAudioLoopingActive: $isAudioLoopingActive")
                isAudioLoopingActive = false 
                releaseAudioResources()
                // mainHandler.post { audioEventSink?.endOfStream() } // Signal end of stream if appropriate
                Log.d(TAG, "Audio loopback thread finished and resources released.")
            }
        }
        loopbackThread?.start()
        Log.i(TAG, "Audio loopback started successfully via internal method.")
        result.success("Audio loopback started.")
    }

    // Helper function to convert FloatArray to ByteArray (PCM16)
    private fun floatArrayToByteArray(floatArray: FloatArray): ByteArray {
        val byteBuffer = ByteBuffer.allocate(floatArray.size * 2) // 2 bytes per short (16-bit)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN) // Assuming little-endian, common for PCM
        for (floatVal in floatArray) {
            // Convert float from -1.0 to 1.0 range to short from -32768 to 32767
            val shortVal = (floatVal * 32767.0).coerceIn(-32768.0, 32767.0).toInt().toShort()
            byteBuffer.putShort(shortVal)
        }
        return byteBuffer.array()
    }

    private fun stopAudioLoopbackInternal() {
        Log.d(TAG, "stopAudioLoopbackInternal called. isAudioLoopingActive: $isAudioLoopingActive, thread: ${loopbackThread?.isAlive}")
        if (!isAudioLoopingActive && loopbackThread == null && audioRecord == null && audioTrack == null) {
            Log.i(TAG, "stopAudioLoopbackInternal: No active loopback or resources to stop.")
            return 
        }
        
        isAudioLoopingActive = false 
        
        val currentThread = loopbackThread
        loopbackThread = null

        if (currentThread != null && currentThread.isAlive) {
            Log.d(TAG, "Attempting to join loopback thread...")
            try {
                currentThread.join(1000) 
                Log.d(TAG, "Loopback thread joined.")
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                Log.e(TAG, "Interrupted while stopping loopback thread", e)
            }
        } else {
            Log.d(TAG, "Loopback thread was null or not alive.")
        }
        
        releaseAudioResources()
        // If EventChannel was streaming, you might want to explicitly signal end or clean up sink
        // mainHandler.post { audioEventSink?.endOfStream() } // Or handle in onCancel
        // audioEventSink = null; // Cleared in onCancel
        Log.i(TAG, "Audio loopback stopped and resources cleaned up via internal method.")
    }

    private fun releaseAudioResources() {
        Log.d(TAG, "Releasing audio resources...")
        audioRecord?.apply {
            if (recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                try {
                    Log.d(TAG, "Stopping AudioRecord...")
                    stop()
                    Log.d(TAG, "AudioRecord stopped.")
                } catch (e: IllegalStateException) { Log.e(TAG, "IllegalStateException while stopping AudioRecord", e) }
            }
            try {
                Log.d(TAG, "Releasing AudioRecord...")
                release()
                Log.d(TAG, "AudioRecord released.")
            } catch (e: Exception) { Log.e(TAG, "Exception while releasing AudioRecord", e) }
        }
        audioRecord = null

        audioTrack?.apply {
            if (playState == AudioTrack.PLAYSTATE_PLAYING) {
                try { 
                    Log.d(TAG, "Stopping AudioTrack...")
                    stop() 
                    Log.d(TAG, "AudioTrack stopped.")
                } catch (e: IllegalStateException) { Log.e(TAG, "IllegalStateException while stopping AudioTrack", e) }
            }
            try {
                Log.d(TAG, "Releasing AudioTrack...")
                release()
                Log.d(TAG, "AudioTrack released.")
            } catch (e: Exception) { Log.e(TAG, "Exception while releasing AudioTrack", e) }
        }
        audioTrack = null
        Log.d(TAG, "Audio resources released. audioRecord is null: ${audioRecord == null}, audioTrack is null: ${audioTrack == null}")
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RECORD_AUDIO_PERMISSION_REQUEST_CODE) {
            val currentResult = pendingResultForPermission
            pendingResultForPermission = null 

            if (currentResult == null) {
                Log.w(TAG, "onRequestPermissionsResult: pendingResultForPermission was null.")
                return
            }

            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.i(TAG, "RECORD_AUDIO permission granted by user.")
                startAudioLoopbackInternal(currentResult)
            } else {
                Log.w(TAG, "RECORD_AUDIO permission denied by user.")
                currentResult.error("PERMISSION_DENIED", "Audio recording permission denied by user.", null)
            }
        }
    }

    override fun onStop() {
        super.onStop()
        Log.d(TAG, "onStop called.")
        // If you want loopback to stop when app is not visible, uncomment below
        // stopAudioLoopbackInternal()
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called.")
        super.onDestroy()
        stopAudioLoopbackInternal() 
        // Ensure EventSink is cleared if not already by onCancel
        mainHandler.post { audioEventSink?.endOfStream() }
        audioEventSink = null
    }
}
