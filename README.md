# UniCall

UniCall is an accessibility-first calling interface designed to let blind, deaf, hard-of-hearing, and non-disabled users communicate together in a single call experience.

This repo currently contains an **Android-first realtime MVP** built with **Flutter**:
- **1:1 realtime audio calls** via **WebRTC**
- **Realtime on-device captions** via **`sherpa_onnx`** (offline STT; model files required)
- **In-call text** + **TTS** for typed messages and system announcements
- **Accessibility by default**: labeled controls, logical focus order, scalable captions, high-contrast mode, haptics

## What’s in the app

### Core screens
- **Home**: Create call (generates a call code) / Join call (paste a call code)
- **In-call**: unified surface with captions + chat + controls (Mute, Speaker, Captions, TTS, Read last message, End)
- **Settings**: contrast, caption size, speech rate, toggles

### Key implementation files
- **App orchestration**: `lib/services/app_controller.dart`
- **Firebase signaling**: `lib/services/signaling/firebase_signaling.dart`
- **WebRTC engine**: `lib/services/webrtc/call_engine_webrtc.dart`
- **Offline captions (sherpa)**: `lib/services/stt/caption_engine_sherpa.dart`, `lib/services/stt/sherpa_model_loader.dart`

## Prerequisites
- Flutter SDK installed and working (`flutter doctor`)
- Android device(s) or emulator

### Windows (required)
This project uses Flutter plugins that require symlink support on Windows.

Enable **Developer Mode**:
- Settings → Privacy & security → For developers → **Developer Mode** (ON)

## Firebase setup (required for realtime calling)
WebRTC signaling is done via **Firestore**.

1. Create a Firebase project
2. Add an **Android app** to the project
3. Download `google-services.json`
4. Place it here:

`android/app/google-services.json`

You must also ensure Firestore is enabled in your Firebase project.

## Offline captions setup (required for realtime captions)
Captions use `sherpa_onnx` streaming ASR and require model files.

Place a streaming model in these exact paths (or update constants in `SherpaModelLoader`):

- `assets/models/sherpa_streaming/encoder.onnx`
- `assets/models/sherpa_streaming/decoder.onnx`
- `assets/models/sherpa_streaming/joiner.onnx`
- `assets/models/sherpa_streaming/tokens.txt`

The app will still run without these files, but captions will show a banner saying they’re not configured.

## Run
From the project root:

```bash
flutter pub get
flutter run
```

## Two-device test (recommended)
1. Install and run on **Device A** → tap **Create call** → copy the call code → **Start call**
2. Install and run on **Device B** → paste the code into **Join call** → **Join**
3. Verify:
   - audio is bidirectional
   - captions appear (after adding the sherpa model)

## Notes / current limitations
- Signaling uses Firestore and assumes both devices can reach Firebase.
- Captions are **local to each device** (each device transcribes its own mic input).
- Proper user accounts, contact discovery, and push notifications for “incoming calls” are not implemented yet (manual call code join is used for MVP testing).

## License
Apache-2.0 (see `LICENSE`).
