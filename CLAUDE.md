# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
Flutter AI assistant app that uses Groq API for fast AI chat responses and transcription. Features voice interaction, image analysis, and context-aware responses based on loaded documents.

## Setup & Common Commands

```bash
# Development
flutter pub get                    # Install dependencies
flutter run                       # Run app (hot reload available)
flutter build [ios|android]       # Build for specific platform

# Testing
flutter test                      # Run all tests
flutter analyze                   # Run static analysis
flutter test test/[filename].dart # Run specific test file

# Formatting/Linting
flutter format lib              # Format code
flutter test --coverage         # Run tests with coverage
```

## Architecture Overview

**Core Directory Structure:**
- `lib/main.dart` - Main app with stateful chat UI
- `lib/services/` - Service layer (ChatService, AudioService, ImageService, etc.)
- `lib/widget/` - Reusable widgets (HomePage)
- `lib/util/` - Utilities (Cloudinary, Preferences)
- `groq-dart-sdk-master/` - Local Groq Dart SDK package

**Key Components:**
- **Chat Service** (`lib/services/chat_service.dart:35`) - Manages Groq API interactions
- **Audio Service** - Handles voice recording/transcription
- **Image Service** - Manages image capture and Cloudinary upload
- **Provider** pattern used for state management
- **Preferences** - SharedPreferences for user settings

**APIs Used:**
- Groq API for AI chat models (llama-33-70b-versatile, meta-llama-4-maverick)
- OpenAI API for transcription fallback
- Cloudinary for image storage

**Configuration:**
- API keys in `main.dart:111` and `chat_service.dart:6` - hardcoded (security issue)
- Models: llama-33-70b-versatile (chat), meta-llama-4-maverick (vision)
- Audio: Whisper-large-v2-turbo for transcribe
- Voice: Tagalog/English language support

## Key Files to Know
- `main.dart` - Main UI and audio capture logic
- `chat_service.dart` - AI service abstraction with Groq SDK
- `services/audio_service.dart` - Recording/monitoring features
- `services/image_service.dart` - Photo capture with Cloudinary integration