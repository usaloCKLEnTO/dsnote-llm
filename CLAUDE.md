# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Speech Note (dsnote) is a multi-platform application for offline speech-to-text, text-to-speech, and machine translation. The codebase is primarily C++ with Qt/QML for the UI, supporting both desktop Linux and Sailfish OS platforms.

## Essential Commands

### Build System (CMake)
- `cmake ../ -DCMAKE_BUILD_TYPE=Release -DWITH_DESKTOP=ON` - Configure for desktop build
- `cmake ../ -DCMAKE_BUILD_TYPE=Release -DWITH_SFOS=ON -DWITH_PY=OFF` - Configure for Sailfish OS build
- `make` - Build the project
- `make test` - Run unit tests (if WITH_TESTS=ON)

### Testing
- Individual test files are in `tests/` directory: `cpu_tools_test.cpp`, `gpu_tools_test.cpp`, `stt_engine_test.cpp`, `text_tools_test.cpp`, `vad_test.cpp`
- Use CMake option `-DWITH_TESTS=ON` to enable test compilation

### Package Building
- **Flatpak**: Use manifests in `flatpak/` directory with `flatpak-builder`
- **Arch Linux**: Use `PKGBUILD` files in `arch/git/` or `arch/release/`
- **RPM**: Use `fedora/make_rpm.sh` script
- **Sailfish OS**: Use `sfdk` build system with `sfos/harbour-dsnote.spec`

## Architecture and Code Structure

### Core Engine Architecture
The application uses a plugin-based architecture for different speech processing engines:

#### Speech-to-Text (STT) Engines
- `stt_engine.hpp/cpp` - Base STT engine interface
- `whisper_engine.hpp/cpp` - Whisper.cpp integration
- `vosk_engine.hpp/cpp` - Vosk engine integration  
- `ds_engine.hpp/cpp` - Coqui/DeepSpeech engine
- `fasterwhisper_engine.hpp/cpp` - Faster Whisper Python integration
- `april_engine.hpp/cpp` - April ASR integration

#### Text-to-Speech (TTS) Engines
- `tts_engine.hpp/cpp` - Base TTS engine interface
- `piper_engine.hpp/cpp` - Piper TTS integration
- `espeak_engine.hpp/cpp` - eSpeak-ng integration
- `rhvoice_engine.hpp/cpp` - RHVoice integration
- `coqui_engine.hpp/cpp` - Coqui TTS integration
- `mimic3_engine.hpp/cpp` - Mimic3 integration
- `whisperspeech_engine.hpp/cpp` - WhisperSpeech integration
- `kokoro_engine.hpp/cpp` - Kokoro TTS integration
- `parler_engine.hpp/cpp` - Parler-TTS integration
- `f5_engine.hpp/cpp` - F5-TTS integration
- `sam_engine.hpp/cpp` - S.A.M. TTS integration

#### Machine Translation
- `mnt_engine.hpp/cpp` - Bergamot translator integration

### Key Application Components
- `dsnote_app.h/cpp` - Main application controller
- `speech_service.h/cpp` - Core speech processing service
- `speech_config.h/cpp` - Configuration management
- `settings.h/cpp` - Settings persistence
- `models_manager.h/cpp` - Model download and management
- `app_server.hpp/cpp` - Application server for CLI/D-Bus integration

### Audio Processing
- `recorder.hpp/cpp` - Audio recording functionality
- `audio_device_manager.hpp/cpp` - Audio device enumeration
- `mic_source.h/cpp` - Microphone audio source
- `file_source.h/cpp` - File-based audio source
- `vad.hpp/cpp` - Voice Activity Detection
- `denoiser.hpp/cpp` - Audio denoising using RNNoise

### Platform Integration
- `fake_keyboard.hpp/cpp` - Virtual keyboard input for "insert into active window"
- `global_hotkeys_manager.hpp/cpp` - System-wide keyboard shortcuts
- `tray_icon.hpp/cpp` - System tray integration
- D-Bus integration files: `dbus_*.cpp/h` - Linux desktop integration

### Utility Components
- `downloader.hpp/cpp` - Model and resource downloading
- `text_tools.hpp/cpp` - Text processing utilities
- `gpu_tools.hpp/cpp` - GPU detection and configuration
- `cpu_tools.hpp/cpp` - CPU feature detection
- `comp_tools.hpp/cpp` - Compression/decompression utilities
- `checksum_tools.hpp/cpp` - File integrity verification

### Build Configuration
The project uses extensive CMake configuration with modular dependency building:
- Each major dependency has its own `.cmake` file in `cmake/` directory
- Build options control which engines and features are compiled
- Support for static linking of most dependencies for distribution
- Cross-platform compatibility (Linux desktop, Sailfish OS)

### Model Management
- Models are defined in `config/models.json`
- Runtime model configuration stored in user data directory
- Support for local file URLs and HTTP downloads
- Automatic checksum verification
- Compressed archive support (gz, xz, zip, tar formats)

## Important Development Notes

### Multi-Platform Support
- Desktop version uses Qt Widgets/QML with desktop-specific features
- Sailfish OS version has different UI (`sfos/qml/`) and limited feature set
- Conditional compilation using `USE_SFOS`, `WITH_DESKTOP`, etc.

### Python Integration
- Optional Python engine support for advanced TTS/STT models
- `py_executor.hpp/cpp` handles Python script execution
- `py_tools.hpp/cpp` provides Python environment management
- Build-time option `WITH_PY` controls Python feature compilation

### Engine Plugin System
Engines implement common interfaces and are dynamically loaded based on:
- Available models
- Hardware capabilities (CPU/GPU features)
- User configuration

### Memory and Performance
- Extensive use of smart pointers and RAII
- Audio processing happens in separate threads
- Models are loaded/unloaded on demand to manage memory usage
- GPU acceleration support for compatible engines