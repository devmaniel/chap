# Chap

AI friends you can message and call.

![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-4.1-6DB33F?logo=springboot&logoColor=white)
![Java](https://img.shields.io/badge/Java-21-ED8B00?logo=openjdk&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Gemini](https://img.shields.io/badge/Google_Gemini-chat-8E75B2?logo=googlegemini&logoColor=white)
![ElevenLabs](https://img.shields.io/badge/ElevenLabs-voice-000000?logo=elevenlabs&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Demo

[![Watch the Chap demo](https://img.youtube.com/vi/RTo7CPfReVE/hqdefault.jpg)](https://youtu.be/RTo7CPfReVE)

▶ [Watch the demo on YouTube](https://youtu.be/RTo7CPfReVE) (2 min)

## What it is

Chap is a small, fictional social world on your phone. You discover AI characters, each with
their own name, personality, interests and voice, and add them as friends. Then you talk to
them the way you would with anyone else: send messages, share a photo, or call them by voice.
Come back later and the conversation picks up where it left off.

The friends are clearly fictional and clearly AI. There are no points or streaks, just the
conversation and the character.

Built for [Build With AI: Basics](https://devpost.com) on Devpost. The planning docs from the
hackathon skills are in [`devpost/`](devpost/): [scope](devpost/scope.md),
[PRD](devpost/prd.md) and [spec](devpost/spec.md).

## Tech stack

| Part | Built with |
|---|---|
| Mobile app (iOS + Android) | Flutter, Dart |
| Server | Spring Boot 4, Java 21 |
| Database | PostgreSQL 17 (Docker), Flyway migrations |
| Friend replies | Google Gemini |
| Voice calls | ElevenLabs Conversational AI |

## How to run

You need Flutter 3.41+ with an iOS simulator or Android emulator, Docker, and JDK 21.

1. Create `server/.env` (all optional: without the AI keys the server still starts, and only
   the features that need them are unavailable):

   ```sh
   GEMINI_API_KEY=your-key
   ELEVENLABS_API_KEY=your-key
   ELEVENLABS_AGENT_ID=your-agent-id
   ```

2. Start the database and server:

   ```sh
   cd server
   docker compose up -d       # PostgreSQL on localhost:5434
   ./mvnw spring-boot:run     # applies migrations, serves on localhost:8080
   ```

3. Start the app and create an account on the sign-up screen:

   ```sh
   cd mobile
   flutter pub get
   flutter run
   ```

   On a real phone, point it at your computer:
   `flutter run --dart-define=API_BASE_URL=http://<your-computer-ip>:8080`

More detail: [server/README.md](server/README.md) and [mobile/README.md](mobile/README.md).

### Tests

```sh
cd server && ./mvnw verify     # server tests (starts its own throwaway database)
cd mobile && flutter test      # app tests
```

## Repo layout

```
mobile/     Flutter app
server/     Spring Boot API
devpost/    hackathon planning docs: scope, PRD, spec
openspec/   build specs, one slice at a time
docs/       product PRD and build plan
```

## License

[MIT](LICENSE) © 2026 Melco Gulbe
