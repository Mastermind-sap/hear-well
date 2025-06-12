# Audio Equalizer Testing Guide

## Prerequisites
1. **Android Device**: The equalizer only works on Android (uses native Android Equalizer API)
2. **Audio Output**: Connect headphones or Bluetooth speakers for best testing experience
3. **Microphone**: Device microphone should be working for audio loopback
4. **Permissions**: Ensure RECORD_AUDIO permission is granted

## Step-by-Step Testing Process

### Step 1: Start Native Audio Loopback
1. Open the app and go to the **Home Screen**
2. Look for the "Native Audio Loopback" card at the bottom
3. Tap the **"Start Loopback"** button
4. If prompted, grant microphone permission
5. Verify the button changes to **"Stop Loopback"** and status shows "Active"

### Step 2: Test Basic Audio
1. With loopback active, speak into the microphone
2. You should hear your voice through the speakers/headphones
3. The waveform visualizer should show audio activity
4. Check that the decibel level indicator responds to your voice

### Step 3: Access Audio Controls
1. Navigate to **Settings** → **Audio Controls** (or use navigation drawer)
2. You should see the equalizer interface with sliders
3. Check that "Audio Status" shows "Native Audio Loopback is Active"

### Step 4: Test Volume Control
1. Adjust the **Volume** slider while speaking
2. You should hear the volume change immediately
3. Test from 0% (should be very quiet) to 100% (loudest)

### Step 5: Test Equalizer
1. While speaking or playing audio, adjust individual frequency bands:
   - **Low frequencies (60Hz-230Hz)**: Affects bass/deep sounds
   - **Mid frequencies (910Hz-3.6kHz)**: Affects vocals/speech clarity
   - **High frequencies (14kHz)**: Affects treble/sharp sounds

2. **Test each band individually**:
   - Set one band to +12dB, others to 0dB
   - Speak into microphone and notice the frequency emphasis
   - Reset to 0dB and test the next band

3. **Test extreme settings**:
   - Set all bands to +12dB (should sound very loud and distorted)
   - Set all bands to -12dB (should sound very quiet)
   - Use "Reset Equalizer" button to return to 0dB

### Step 6: Test Noise Gate
1. Adjust the **Noise Gate** threshold
2. Lower values should cut out background noise
3. Higher values should let more quiet sounds through
4. Test by whispering vs speaking normally

## Troubleshooting

### Method Channel Error: "No implementation found for method..."
**This error means the Flutter and Android sides are using different channel names:**
1. **Rebuild the app**: Clean and rebuild the Android project with `flutter clean && flutter build apk`
2. **Check channel names**: All methods should use `com.example.hear_well/check` channel
3. **Restart app**: Force close and restart the application completely
4. **Check logs**: Use `adb logcat | grep MainActivity` to see if methods are being called
5. **Hot restart**: Try hot restart (Ctrl+Shift+F5 in VSCode) instead of hot reload

### Platform Exception: "isNativeLoopbackActive"
**If you see this specific error:**
1. **Use correct channel**: Audio controls should use `com.example.hear_well/check` not `/control`
2. **Rebuild project**: The method was recently added, rebuild with `flutter clean && flutter build apk`
3. **Check MainActivity**: Ensure `isNativeLoopbackActive` method exists in MainActivity.kt

### No Sound Changes When Adjusting Equalizer
**Check these items:**
1. **Native Loopback Status**: Ensure "Native Audio Loopback is Active" in Audio Controls
2. **Audio Output**: Use headphones/speakers, not just device speaker
3. **Volume**: Ensure device volume and app volume are up
4. **Microphone**: Speak clearly into the microphone
5. **Refresh**: Use the refresh button in Audio Controls to check status

### Audio Issues
1. **Crackling/Distortion**: Lower the volume or reduce extreme equalizer settings
2. **No Audio**: Check microphone permission and device audio settings
3. **Lag**: This is normal for real-time audio processing
4. **Echo**: Use headphones instead of speakers to prevent feedback

### Equalizer Not Responding
1. **Restart Loopback**: Stop and start the native audio loopback
2. **Check Logs**: Look for "Equalizer bands updated" in Android logs
3. **Device Compatibility**: Some devices may not support all equalizer features

## Expected Behavior

### Volume Control
- Should affect output volume linearly
- 0% = very quiet, 100% = loudest
- Changes should be immediate

### Equalizer Bands
- **60Hz**: Deep bass (drums, bass guitar)
- **230Hz**: Low-mid (male vocals, guitar body)
- **910Hz**: Mid-range (speech clarity)
- **3.6kHz**: Upper-mid (vocal presence)
- **14kHz**: High treble (cymbals, air)

### Noise Gate
- Should cut out background noise below threshold
- Useful for reducing ambient noise in quiet environments

## Testing with Different Audio Sources

### Voice Testing
1. Speak in different tones (deep voice, high voice)
2. Whisper vs normal speech vs shouting
3. Test speech clarity with mid-range adjustments

### Music Testing (if available)
1. Play music near the microphone
2. Test bass with low-frequency adjustments
3. Test treble with high-frequency adjustments

## Android Logcat Debugging

To see detailed logs:
```bash
adb logcat | grep MainActivity
```

Look for these log messages:
- "Equalizer initialized with X bands"
- "Equalizer bands updated: [values]"
- "Audio loopback started successfully"
- "AudioTrack state after init"

## Device Compatibility Notes

- **Android 5.0+**: Required for Equalizer API
- **Real Device**: Emulator may not support audio loopback properly
- **Hardware**: Some devices have hardware-accelerated equalizers
- **OEM Modifications**: Some manufacturers modify Android's audio system

## Performance Tips

1. **Use Headphones**: Prevents audio feedback loops
2. **Close Other Audio Apps**: Avoid conflicts with other audio applications
3. **Stable Environment**: Test in a quiet room for best results
4. **Battery**: Audio processing can drain battery quickly

## Common Test Scenarios

### Scenario 1: Speech Enhancement
1. Set mid-range (910Hz, 3.6kHz) to +6dB
2. Set low frequencies to -3dB
3. Speak normally - speech should sound clearer

### Scenario 2: Bass Boost
1. Set low frequencies (60Hz, 230Hz) to +9dB
2. Keep others at 0dB
3. Speak in low voice - should sound deeper

### Scenario 3: Treble Boost
1. Set high frequency (14kHz) to +9dB
2. Keep others at 0dB
3. Make sharp sounds (like "S" sounds) - should be more pronounced

Remember: The equalizer affects the audio in real-time, so you should hear changes immediately when adjusting the sliders while audio is playing through the loopback.