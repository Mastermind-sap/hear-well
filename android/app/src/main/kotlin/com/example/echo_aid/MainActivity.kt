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
import org.tensorflow.lite.Interpreter
import java.io.BufferedReader // Import BufferedReader
import java.io.FileInputStream
import java.io.InputStreamReader // Import InputStreamReader
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.abs
import kotlin.math.min // Import min for minOf

class MainActivity : FlutterActivity() {
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
    @Volatile private var noiseGateThreshold: Short = 1000 // 16-bit PCM amplitude threshold
    @Volatile private var enableNoiseGate: Boolean = false

    @Volatile private var eqBassGain: Float = 1.0f
    @Volatile private var eqMidGain: Float = 1.0f
    @Volatile private var eqTrebleGain: Float = 1.0f

    private val SAMPLE_RATE = 44100 // Your current sample rate for recording
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

    // --- YAMNet Integration Members ---
    private var interpreter: Interpreter? = null
    private val YAMNET_MODEL_PATH = "yamnet.tflite"
    private val YAMNET_SAMPLE_RATE = 16000 // YAMNet expects 16 kHz
    private val YAMNET_INPUT_SIZE = 15600 // Corresponds to 0.975 seconds of 16kHz mono audio (16000 * 0.975)
    private var yamnetLabels: List<String>? = null
    private val YAMNET_CHANNEL_NAME = "com.example.hear_well/yamnet_events"
    private var yamnetEventSink: EventChannel.EventSink? = null
    private var audioBufferForYamnet: ShortArray? = null // Buffer to accumulate audio for YAMNet
    private var bufferIndexForYamnet: Int = 0

    // IMPORTANT: YAMNet outputs 521 classes. This must match the model's actual output.
    private val YAMNET_NUM_CLASSES = 521

    // ---

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        loadYamnetModel()
        loadYamnetLabels() // Load labels when the activity is created
    }

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

        // --- Setup EventChannel for YAMNet audio classification ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, YAMNET_CHANNEL_NAME).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "YAMNet EventChannel: onListen called")
                    yamnetEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "YAMNet EventChannel: onCancel called")
                    yamnetEventSink = null
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

    private fun loadYamnetModel() {
        try {
            val fileDescriptor = assets.openFd(YAMNET_MODEL_PATH)
            val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
            val fileChannel = inputStream.channel
            val startOffset = fileDescriptor.startOffset
            val declaredLength = fileDescriptor.declaredLength
            val modelBuffer: MappedByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)

            val options = Interpreter.Options()
            // options.setNumThreads(4) // Optional: Set number of threads for inference
            // options.setUseNNAPI(true) // Optional: Enable NNAPI for hardware acceleration
            interpreter = Interpreter(modelBuffer, options)
            Log.d(TAG, "YAMNet model loaded successfully.")

            // Allocate buffer for YAMNet input
            audioBufferForYamnet = ShortArray(YAMNET_INPUT_SIZE)
            bufferIndexForYamnet = 0

        } catch (e: Exception) {
            Log.e(TAG, "Error loading YAMNet model: ${e.message}", e)
        }
    }

    private fun loadYamnetLabels() {
        try {
            val labelsList = mutableListOf<String>()
            // Assuming yamnet_class_map.csv actually contains one label per line,
            // or you've renamed yamnet_label_list.txt to yamnet_class_map.csv
            assets.open("yamnet_class_map.csv").bufferedReader().useLines { lines ->
                lines.forEach { line ->
                    // For a simple list of labels, one per line:
                    labelsList.add(line.trim())

                    // If it was truly a CSV with index,mid,display_name, you'd use:
                    // val parts = line.split(",")
                    // if (parts.size >= 3) {
                    //     labelsList.add(parts[2].trim()) // Get the display_name
                    // }
                }
            }
            yamnetLabels = labelsList
            Log.d(TAG, "YAMNet labels loaded successfully. Total labels: ${yamnetLabels?.size}")

            // --- IMPORTANT VALIDATION ---
            // Verify the loaded labels count matches the expected output size from the model.
            if (yamnetLabels?.size != YAMNET_NUM_CLASSES) {
                Log.e(TAG, "Mismatch: YAMNet labels size (${yamnetLabels?.size}) does not match expected model output (${YAMNET_NUM_CLASSES}).")
                // Consider throwing an error or handling this more gracefully
            }
            // ---

        } catch (e: Exception) {
            Log.e(TAG, "Error loading YAMNet labels: ${e.message}", e)
        }
    }

    private fun runYamnetInference(audioData: FloatArray) {
        if (interpreter == null || yamnetLabels == null || yamnetLabels!!.size != YAMNET_NUM_CLASSES) { // Added size check
            Log.e(TAG, "YAMNet interpreter, labels, or labels size mismatch. Cannot run inference.")
            return
        }

        try {
            val inputBuffer = ByteBuffer.allocateDirect(YAMNET_INPUT_SIZE * 4) // Float (4 bytes)
            inputBuffer.order(ByteOrder.nativeOrder())
            inputBuffer.asFloatBuffer().put(audioData) // Efficiently put all floats
            inputBuffer.rewind()

            // Ensure outputScores array size matches YAMNET_NUM_CLASSES (521)
            val outputScores = Array(1) { FloatArray(YAMNET_NUM_CLASSES) } // Output shape: (1, 521)

            interpreter?.run(inputBuffer, outputScores)

            val classScores = outputScores[0]
            val topK = 5 // Get top 5 predictions
            val sortedPredictions = classScores
                .mapIndexed { index, score -> Pair(yamnetLabels!![index], score) }
                .sortedByDescending { it.second }
                .take(topK)

            // Prepare predictions with labels and scores
            val resultList = sortedPredictions.map { mapOf("label" to it.first, "score" to it.second) }
            mainHandler.post {
                yamnetEventSink?.success(resultList)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error running YAMNet inference: ${e.message}", e)
            mainHandler.post {
                yamnetEventSink?.error("INFERENCE_ERROR", "Error running YAMNet inference: ${e.message}", null)
            }
        }
    }

    private fun resampleAudio(inputBuffer: ShortArray, inputSize: Int, outputSampleRate: Int, inputSampleRate: Int): FloatArray {
        if (inputSampleRate == outputSampleRate) {
            // No resampling needed, just convert ShortArray to FloatArray and normalize
            return FloatArray(inputSize) { i -> inputBuffer[i].toFloat() / 32768.0f }
        }

        // Simple linear interpolation for resampling (can be improved for quality)
        val ratio = outputSampleRate.toDouble() / inputSampleRate.toDouble()
        val outputSize = (inputSize * ratio).toInt()
        val outputBuffer = FloatArray(outputSize)

        for (i in 0 until outputSize) {
            val inputIndex = (i / ratio)
            val lowerIndex = inputIndex.toInt()
            val upperIndex = lowerIndex + 1
            val fraction = inputIndex - lowerIndex

            val sample1 = if (lowerIndex >= 0 && lowerIndex < inputSize) inputBuffer[lowerIndex].toFloat() / 32768.0f else 0.0f
            val sample2 = if (upperIndex >= 0 && upperIndex < inputSize) inputBuffer[upperIndex].toFloat() / 32768.0f else 0.0f

            // Linear interpolation
            outputBuffer[i] = sample1 + fraction.toFloat() * (sample2 - sample1)
        }
        return outputBuffer
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
            val shortBuffer = ShortArray(bufferSizeInBytes / 2) // For 16-bit PCM

            Log.d(TAG, "Audio loopback thread started.")
            try {
                audioRecord?.startRecording()
                Log.d(TAG, "AudioRecord recording started.")
                audioTrack?.play()
                Log.d(TAG, "AudioTrack playback started.")

                while (isAudioLoopingActive) {
                    val readSize = audioRecord?.read(buffer, 0, buffer.size) ?: -1
                    if (readSize > 0) {
                        // Convert ByteArray to ShortArray for processing
                        ByteBuffer.wrap(buffer).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(shortBuffer, 0, readSize / 2)

                        // Stream to Flutter via EventChannel if sink is available (raw audio)
                        audioEventSink?.let { sink ->
                            val audioData = buffer.copyOfRange(0, readSize) // Send raw bytes
                            mainHandler.post {
                                try {
                                    sink.success(audioData)
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error sending audio data to Flutter: ${e.message}")
                                }
                            }
                        }

                        /*---------------------------------- Processing -----------------------------------*/

                        for (i in 0 until readSize / 2) { // Iterate over short samples
                            var sample = shortBuffer[i].toInt()

                            // Noise gate
                            if (enableNoiseGate && abs(sample) < noiseGateThreshold) {
                                sample = 0
                            }

                            // Apply volume
                            var processed = (sample * volumeMultiplier).toInt()

                            // Clamp to 16-bit range
                            processed = processed.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())

                            // EQ stub: simulate band-specific gain (This is a very rudimentary approximation)
                            // A proper EQ requires implementing a filter bank (e.g., IIR or FIR filters)
                            // This is for demonstration and might not sound like a real EQ.
                            when {
                                // Simple frequency band approximation based on sample index (not accurate)
                                i < (readSize / 2 * 0.2) -> processed = (processed * eqBassGain).toInt() // "Bass"
                                i >= (readSize / 2 * 0.2) && i < (readSize / 2 * 0.8) -> processed = (processed * eqMidGain).toInt() // "Mid"
                                else -> processed = (processed * eqTrebleGain).toInt() // "Treble"
                            }


                            shortBuffer[i] = processed.toShort()
                        }

                        // Convert processed ShortArray back to ByteArray for AudioTrack
                        val processedBuffer = ByteArray(readSize)
                        ByteBuffer.wrap(processedBuffer).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().put(shortBuffer, 0, readSize / 2)
                        audioTrack?.write(processedBuffer, 0, readSize)

                        /*---------------------------------- YAMNet Processing -----------------------------------*/

                        // Accumulate audio for YAMNet
                        val shortsRead = readSize / 2
                        if (audioBufferForYamnet != null) {
                            val remainingSpace = YAMNET_INPUT_SIZE - bufferIndexForYamnet
                            val samplesToCopy = minOf(shortsRead, remainingSpace)

                            System.arraycopy(shortBuffer, 0, audioBufferForYamnet!!, bufferIndexForYamnet, samplesToCopy)
                            bufferIndexForYamnet += samplesToCopy

                            if (bufferIndexForYamnet >= YAMNET_INPUT_SIZE) {
                                // Full YAMNet input buffer, process it
                                Log.d(TAG, "Running YAMNet inference...")
                                val resampledAudio = resampleAudio(audioBufferForYamnet!!, YAMNET_INPUT_SIZE, YAMNET_SAMPLE_RATE, SAMPLE_RATE)
                                runYamnetInference(resampledAudio)

                                // Reset buffer for next chunk, potentially copy remaining data
                                val remainingAfterYamnet = shortsRead - samplesToCopy
                                if (remainingAfterYamnet > 0) {
                                    System.arraycopy(shortBuffer, samplesToCopy, audioBufferForYamnet!!, 0, remainingAfterYamnet)
                                    bufferIndexForYamnet = remainingAfterYamnet
                                } else {
                                    bufferIndexForYamnet = 0
                                }
                            }
                        }
                    } else if (readSize < 0) {
                        Log.e(TAG, "AudioRecord read error: $readSize. Stopping loop.")
                        break
                    }
                }
            } catch (t: Throwable) {
                Log.e(TAG, "Error in loopback thread", t)
            } finally {
                Log.d(TAG, "Audio loopback thread finishing. isAudioLoopingActive: $isAudioLoopingActive")
                isAudioLoopingActive = false
                releaseAudioResources()
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
        interpreter?.close() // Release TFLite interpreter resources
        Log.d(TAG, "YAMNet interpreter closed.")
    }
}