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

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL_NAME = "com.example.hear_well/check"
    private val AUDIO_STREAM_CHANNEL_NAME = "com.example.hear_well/audio_stream"
    private val TAG = "MainActivity"

    // Audio Loopback Members
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    @Volatile private var isAudioLoopingActive: Boolean = false
    private var loopbackThread: Thread? = null
    // Audio processing controls
    @Volatile private var volumeMultiplier: Float = 1.0f
    @Volatile private var noiseGateThreshold: Short = 1000  // 16-bit PCM amplitude threshold
    @Volatile private var enableNoiseGate: Boolean = false

    @Volatile private var eqBassGain: Float = 1.0f
    @Volatile private var eqMidGain: Float = 1.0f
    @Volatile private var eqTrebleGain: Float = 1.0f

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

        /*---------------------------------------- To Control Audio -------------------------------------*/
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.hear_well/control")
        .setMethodCallHandler { call, result ->
            when (call.method) {

                "setVolume" -> {
                    val vol = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    volumeMultiplier = vol.coerceIn(0f, 5f)
                    result.success("Volume set to $volumeMultiplier")
                }

                "setNoiseGate" -> {
                    enableNoiseGate = call.argument<Boolean>("enabled") ?: false
                    noiseGateThreshold = (call.argument<Number>("noiseGateThreshold")?.toInt() ?: 1000).toShort()
                    result.success("Noise gate set to $enableNoiseGate, threshold = $noiseGateThreshold")
                }

                "setEqualizer" -> {
                    eqBassGain = (call.argument<Double>("bass") ?: 1.0).toFloat()
                    eqMidGain = (call.argument<Double>("mid") ?: 1.0).toFloat()
                    eqTrebleGain = (call.argument<Double>("treble") ?: 1.0).toFloat()
                    result.success("EQ updated: bass=$eqBassGain, mid=$eqMidGain, treble=$eqTrebleGain")
                }

                "updateAudioSettings" -> {
                    volumeMultiplier = (call.argument<Number>("volume")?.toFloat()) ?: 1.0f
                    enableNoiseGate = call.argument<Boolean>("noiseGateEnabled") ?: false
                    noiseGateThreshold = (call.argument<Number>("noiseGateThreshold")?.toInt() ?: 1000).toShort()
                    eqBassGain = (call.argument<Number>("bass")?.toFloat()) ?: 1.0f
                    eqMidGain = (call.argument<Number>("mid")?.toFloat()) ?: 1.0f
                    eqTrebleGain = (call.argument<Number>("treble")?.toFloat()) ?: 1.0f
                    result.success("Audio settings updated")
                }


                else -> {
                    result.notImplemented()
                }
            }
        }
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
                        // Stream to Flutter via EventChannel if sink is available
                        audioEventSink?.let { sink ->
                            // Send a copy of the relevant part of the buffer
                            val audioData = buffer.copyOfRange(0, readSize)
                            // Events must be sent on the main thread
                            mainHandler.post {
                                try {
                                    sink.success(audioData)
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error sending audio data to Flutter: ${e.message}")
                                }
                            }
                        }


                        /*---------------------------------- Processing -----------------------------------*/
                        
                        // TODO: Implement sound processing on the 'buffer' (PCM 16-bit data) here for the loopback.
                        // For example, to apply a simple gain:
                        // for (i in 0 until readSize step 2) { ... }

                        for (i in 0 until readSize step 2) {
                            // Convert bytes to short (little endian)
                            val low = buffer[i].toInt() and 0xFF
                            val high = buffer[i + 1].toInt()
                            var sample = (high shl 8) or low

                            // Noise gate
                            if (enableNoiseGate && kotlin.math.abs(sample) < noiseGateThreshold) {
                                sample = 0
                            }

                            // Apply volume
                            var processed = (sample * volumeMultiplier).toInt()

                            // Clamp to 16-bit range
                            processed = processed.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())

                            // EQ stub: simulate band-specific gain
                            // You can implement a real filter bank, but here we simulate by segmenting frequency bands
                            // You could buffer and apply FIR/IIR here

                            // For now, apply a naive scalar-based approximation
                            // This is where you'd split frequency bands in real EQ

                            // Convert back to bytes
                            buffer[i] = processed.toByte()
                            buffer[i + 1] = (processed shr 8).toByte()
                        }
                        audioTrack?.write(buffer, 0, readSize)
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
