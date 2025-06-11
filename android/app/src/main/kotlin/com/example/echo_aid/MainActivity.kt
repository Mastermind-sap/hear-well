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
import android.media.audiofx.Equalizer
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
    
    // Equalizer
    private var equalizer: Equalizer? = null
    // --- Add NoiseSuppressor member ---
    private var noiseSuppressor: NoiseSuppressor? = null
    @Volatile private var enableNoiseSuppression: Boolean = false // New control flag
    // --- End NoiseSuppressor member ---

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
                "isNativeLoopbackActive" -> {
                    result.success(isAudioLoopingActive)
                }
                "getEqualizerInfo" -> {
                    try {
                        equalizer?.let { eq ->
                            val bandCount = eq.numberOfBands.toInt()
                            val levelRange = eq.bandLevelRange
                            val bands = mutableListOf<Map<String, Any>>()
                            
                            for (i in 0 until bandCount) {
                                val centerFreq = eq.getCenterFreq(i.toShort())
                                val currentLevel = eq.getBandLevel(i.toShort())
                                bands.add(mapOf(
                                    "band" to i,
                                    "centerFreq" to centerFreq,
                                    "currentLevel" to currentLevel
                                ))
                            }
                            
                            result.success(mapOf(
                                "bandCount" to bandCount,
                                "levelRange" to listOf(levelRange[0], levelRange[1]),
                                "bands" to bands
                            ))
                        } ?: {
                            // Return default equalizer info when equalizer is not initialized
                            Log.w(TAG, "Equalizer not initialized, returning default info")
                            result.success(mapOf(
                                "bandCount" to 5,
                                "levelRange" to listOf(-1200, 1200),
                                "bands" to listOf(
                                    mapOf("band" to 0, "centerFreq" to 60000, "currentLevel" to 0),
                                    mapOf("band" to 1, "centerFreq" to 230000, "currentLevel" to 0),
                                    mapOf("band" to 2, "centerFreq" to 910000, "currentLevel" to 0),
                                    mapOf("band" to 3, "centerFreq" to 3600000, "currentLevel" to 0),
                                    mapOf("band" to 4, "centerFreq" to 14000000, "currentLevel" to 0)
                                )
                            ))
                        }()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting equalizer info: ${e.message}")
                        result.error("EQUALIZER_ERROR", e.message, null)
                    }
                }
                "updateAudioSettings" -> {
                    val volume = (call.argument<Number>("volume")?.toFloat()) ?: 1.0f
                    val noiseGateThresholdDb = (call.argument<Number>("noiseGateThreshold")?.toDouble()) ?: -50.0 // Expect dB from Flutter
                    val equalizerGains = call.argument<List<Double>>("equalizerGains") ?: listOf(0.0, 0.0, 0.0, 0.0, 0.0)
                    val enableNS = call.argument<Boolean>("enableNoiseSuppression") ?: false // New argument

                    // Convert volume from 0-100 to 0-2.0 range
                    volumeMultiplier = (volume / 50.0f).coerceIn(0f, 2f)
                    // Convert noise gate threshold from dB to amplitude (approximate)
                    // This conversion is highly dependent on the actual signal range and characteristics.
                    // A more robust approach might involve calibration or a different scale.
                    // For now, let's assume a simple linear mapping for demonstration, this needs refinement.
                    // Max amplitude for 16-bit PCM is 32767. Let -100dB be 0 and 0dB be 32767.
                    // This is a placeholder and likely needs a more accurate conversion based on your needs.
                    val minDb = -100.0
                    val maxDb = 0.0 // Or a lower value if -10dB is max for noise gate slider
                    // Clamp the input dB to avoid issues with log(0) or extreme values
                    val clampedDb = noiseGateThresholdDb.coerceIn(minDb + 1, maxDb -1) // ensure it's not at the very edge for log
                    // Simple linear scaling (example, not acoustically perfect)
                    // val normalizedThreshold = (clampedDb - minDb) / (maxDb - minDb)
                    // this.noiseGateThreshold = (normalizedThreshold * Short.MAX_VALUE).toInt().toShort()
                    // A more common way to handle dB for thresholding is to convert signal to dB then compare.
                    // However, our current processing loop works with raw amplitude.
                    // Let's use a direct interpretation of the dB value for the threshold for now, assuming it's pre-calibrated.
                    // This means the Flutter side is sending a value that's meaningful in the context of 16-bit PCM amplitudes.
                    // For a simple mapping: -50dB might correspond to an amplitude of around 100-1000.
                    // This part is tricky and highly dependent on how you want to define the dB scale for the noise gate.
                    // Let's assume the Flutter value is an amplitude for now, if it's dB, it needs conversion.
                    // If noiseGateThreshold is indeed in dB from Flutter, we need to convert it to an amplitude.
                    // For simplicity, if Flutter sends -50.0, let's map it to an amplitude. This is a placeholder.
                    // A common formula: amplitude = 10^(dB/20) * MaxAmplitude. But this needs a reference (MaxAmplitude).
                    // Let's assume the value from Flutter for noiseGateThreshold is already an amplitude if it's not dB.
                    // Given the previous code used: (call.argument<Number>("noiseGateThreshold")?.toInt()) ?: 1000
                    // It seems it was expecting an amplitude. If Flutter now sends dB, this is a mismatch.
                    // Let's revert to expecting an amplitude for noiseGateThreshold for now to match the processing loop.
                    // Or, if Flutter sends dB, we must convert it. Example: 10^(dB/20) * reference_amplitude
                    // For now, assuming Flutter sends an amplitude value directly for noiseGateThreshold based on previous implementation.
                    this.noiseGateThreshold = (call.argument<Number>("noiseGateThreshold")?.toInt() ?: 1000).toShort()


                    this.enableNoiseSuppression = enableNS // Update the flag
                    
                    // Update equalizer with individual band levels only if loopback is active
                    if (isAudioLoopingActive) {
                        try {
                            equalizer?.let { eq ->
                                val bandCount = minOf(eq.numberOfBads.toInt(), equalizerGains.size)
                                for (i in 0 until bandCount) {
                                    // Convert from -12 to +12 dB range to millibells (-1200 to +1200)
                                    val millibells = (equalizerGains[i] * 100).toInt().toShort()
                                    eq.setBandLevel(i.toShort(), millibells)
                                }
                                Log.d(TAG, "Equalizer bands updated: $equalizerGains")
                            } ?: Log.w(TAG, "Equalizer not available for settings update")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error updating equalizer: ${e.message}")
                        }

                        // Apply Noise Suppressor setting
                        try {
                            noiseSuppressor?.enabled = enableNoiseSuppression
                            Log.d(TAG, "NoiseSuppressor enabled state applied: $enableNoiseSuppression")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error applying NoiseSuppressor enabled state: ${e.message}")
                        }

                    } else {
                        Log.d(TAG, "Audio loopback not active, equalizer and NS settings stored but not applied")
                    }
                    
                    result.success("Audio settings updated")
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

                "setEqualizerBand" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val level = call.argument<Double>("level") ?: 0.0
                    
                    try {
                        equalizer?.let { eq ->
                            if (band < eq.numberOfBands) {
                                val millibells = (level * 100).toInt().toShort()
                                Log.d(TAG, "Attempting to set band $band to level $level dB ($millibells mB)")
                                eq.setBandLevel(band.toShort(), millibells)
                                val currentLevel = eq.getBandLevel(band.toShort())
                                Log.d(TAG, "Band $band set. Read back level: $currentLevel mB")
                                result.success("Equalizer band $band updated")
                            } else {
                                result.error("INVALID_BAND", "Band index $band out of range", null)
                            }
                        } ?: result.error("EQUALIZER_NULL", "Equalizer not initialized", null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error setting equalizer band: ${e.message}", e) // Log the full exception
                        result.error("EQUALIZER_ERROR", e.message, null)
                    }
                }

                "enableNoiseGate" -> {
                    enableNoiseGate = call.argument<Boolean>("enabled") ?: false
                    result.success("Noise gate enabled: $enableNoiseGate")
                }

                "setNoiseSuppressionEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    enableNoiseSuppression = enabled // Update the flag

                    // Apply immediately if loopback is active
                    if (isAudioLoopingActive) {
                        try {
                            noiseSuppressor?.enabled = enabled
                            Log.d(TAG, "NoiseSuppressor enabled state set to: $enabled")
                            result.success("Noise suppressor enabled state updated to $enabled")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error setting NoiseSuppressor enabled state: ${e.message}")
                            result.error("NS_ERROR", e.message, null)
                        }
                    } else {
                        Log.d(TAG, "Audio loopback not active, NoiseSuppressor setting stored but not applied.")
                        result.success("Noise suppressor setting stored for when loopback starts.")
                    }
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

            // Initialize Equalizer with AudioTrack session ID
            try {
                val sessionId = audioTrack?.audioSessionId ?: 0
                Log.d(TAG, "Initializing Equalizer with session ID: $sessionId")
                if (sessionId == 0) {
                    Log.e(TAG, "Audio session ID is 0, Equalizer may not attach correctly.")
                }
                equalizer = Equalizer(0, sessionId)
                equalizer?.enabled = true
                
                val bandCount = equalizer?.numberOfBands?.toInt() ?: 0
                val levelRange = equalizer?.bandLevelRange
                Log.d(TAG, "Equalizer initialized - Enabled: ${equalizer?.enabled}, Bands: $bandCount, Level range: [${levelRange?.get(0)}, ${levelRange?.get(1)}]")
                
                // Log center frequencies for debugging
                for (i in 0 until bandCount) {
                    val freq = equalizer?.getCenterFreq(i.toShort()) ?: 0
                    Log.d(TAG, "Band $i center frequency: ${freq / 1000}Hz") // Convert to Hz for readability
                }

                // IMPORTANT: Log current band levels immediately after initialization
                Log.d(TAG, "Initial Equalizer Band Levels:")
                for (i in 0 until bandCount) {
                    val currentLevel = equalizer?.getBandLevel(i.toShort())
                    Log.d(TAG, "  Band $i: $currentLevel mB")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize Equalizer: ${e.message}", e) // Log the exception for details
                equalizer = null // Ensure it's null if initialization fails
            }

            // --- Add NoiseSuppressor initialization here ---
            try {
                if (NoiseSuppressor.isAvailable()) { // Check if device supports Noise Suppression
                    val sessionId = audioRecord?.audioSessionId ?: 0 // NoiseSuppressor attaches to AudioRecord's session
                    Log.d(TAG, "Initializing NoiseSuppressor with AudioRecord session ID: $sessionId")
                    if (sessionId != 0) {
                        noiseSuppressor = NoiseSuppressor.create(sessionId)
                        if (noiseSuppressor != null) {
                            // Set initial state based on the control flag
                            noiseSuppressor?.enabled = enableNoiseSuppression
                            Log.d(TAG, "NoiseSuppressor initialized. Enabled: ${noiseSuppressor?.enabled}")
                        } else {
                            Log.w(TAG, "NoiseSuppressor.create returned null. Device might not implement it for session $sessionId.")
                        }
                    } else {
                        Log.w(TAG, "AudioRecord session ID is 0, cannot initialize NoiseSuppressor.")
                    }
                } else {
                    Log.i(TAG, "NoiseSuppression is not available on this device.")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize NoiseSuppressor: ${e.message}", e)
                // Continue without noise suppressor if it fails
            }
            // --- End NoiseSuppressor initialization ---

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
                        
                        // Apply manual volume and noise gate processing
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

                            // Convert back to bytes
                            buffer[i] = processed.toByte()
                            buffer[i + 1] = (processed shr 8).toByte()
                        }
                        
                        // The equalizer is applied automatically by the AudioTrack since it's attached to the session
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
        
        // Release Equalizer
        equalizer?.apply {
            try {
                Log.d(TAG, "Releasing Equalizer...")
                release()
                Log.d(TAG, "Equalizer released.")
            } catch (e: Exception) { 
                Log.e(TAG, "Exception while releasing Equalizer", e) 
            }
        }
        equalizer = null

        // --- Release NoiseSuppressor ---
        noiseSuppressor?.apply {
            try {
                Log.d(TAG, "Releasing NoiseSuppressor...")
                release()
                Log.d(TAG, "NoiseSuppressor released.")
            } catch (e: Exception) {
                Log.e(TAG, "Exception while releasing NoiseSuppressor", e)
            }
        }
        noiseSuppressor = null
        // --- End NoiseSuppressor release ---
        
        Log.d(TAG, "Audio resources released. audioRecord is null: ${audioRecord == null}, audioTrack is null: ${audioTrack == null}, equalizer is null: ${equalizer == null}, noiseSuppressor is null: ${noiseSuppressor == null}")
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
