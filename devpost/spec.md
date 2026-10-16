---
doc: spec
status: draft
sources:
  - docs/PRD.md
  - AGENTS.md
  - mobile/pubspec.yaml
  - docs/IMPLEMENTATION.md
---

# Chap — Technical Specification

## How This Works, In Plain Language

The Flutter phone app shows fictional friends and conversations. The planned server receives messages, retrieves the selected friend's personality and permitted conversation context, asks an AI service for a reply, and returns it to the phone. PostgreSQL stores the information needed to reopen conversations later.

Image sharing adds the selected image to the AI request. Voice calls need a live audio connection to an AI speech service. The AI provider, image storage, and audio connection details still need confirmation. This is a draft blueprint derived from existing plans, not a claim that these integrations are implemented.

## Planning Basis and Authority

- [prd.md](prd.md) carries the existing [product PRD](../docs/PRD.md) into the required Devpost filename, without changing its product content.
- [scope.md](scope.md) summarizes that PRD's existing boundary. No smaller hackathon slice has been approved.
- [AGENTS.md](../AGENTS.md) defines the current server and mobile architecture.
- [mobile/pubspec.yaml](../mobile/pubspec.yaml) records the existing Flutter dependencies and bundled Nunito fonts.
- [docs/IMPLEMENTATION.md](../docs/IMPLEMENTATION.md) is an older AWS-oriented proposal for another competition. Its Node.js backend conflicts with the current Spring Boot rule. Its providers and MCP integration are not treated as newly approved choices for this submission.

The `devpost/` workspace was empty when these plans were prepared. There is an existing Flutter project; no `server/` directory was present. These documents do not certify that planning preceded development or that the learning skills were previously completed. No learner profile or personal learning goals have been invented.

## The Core Journey Through the System

Implements `prd.md > Core Experience`.

1. **Discover:** the app obtains predefined character profiles through a repository and displays them in Discover.
2. **Add:** the user's selection passes through the view model to a repository, then to the server for persistence. The inbox reflects the added friend.
3. **Message:** the server combines the selected persona with allowed conversation context, obtains a real AI reply, and persists the conversation turns.
4. **Share an image:** the app submits an image for that conversation. A vision-capable AI receives the image and context, and its reply appears in the conversation. Storage and retention remain open decisions.
5. **Call:** the app connects microphone input and audio playback to the same character's AI voice session through the server. The specific transport and persistence of call context remain unresolved.
6. **Return:** repositories reload saved friends and conversation history. Only context allowed by the user's memory choices is used.
7. **Control:** conversation deletion and memory changes go through the same service and repository boundaries as other writes. Exact deletion and retention rules must be decided before implementation.

## Stack

| Area | Established basis | Constraint or unresolved choice |
| --- | --- | --- |
| Client | Flutter and Dart; iOS and Android only | No web client; existing Dart SDK constraint is `^3.11.0` |
| Navigation | Existing `go_router` dependency, `^17.5.0` | Follow the existing routing layer |
| Dependency wiring | Existing `provider` dependency, `^6.1.5+1` | Follow the existing configuration layer |
| Server | Spring Boot, Java 21, Maven | Required by AGENTS.md; base package and dependency versions remain unspecified |
| Persistence | PostgreSQL, Flyway, JPA | Migrations own the schema; Hibernate validates rather than generates it |
| AI | Text, image understanding, and real-time speech are required capabilities | Provider and SDK are unconfirmed |

Versions above are repository declarations, not a recommendation to upgrade or a claim about current releases. No new libraries are selected by this draft.

Official implementation references: [Flutter app architecture](https://docs.flutter.dev/app-architecture), [go_router](https://pub.dev/packages/go_router), [provider](https://pub.dev/packages/provider), [Spring Boot](https://docs.spring.io/spring-boot/index.html), [Maven](https://maven.apache.org/guides/), [PostgreSQL](https://www.postgresql.org/docs/), and [Flyway](https://documentation.red-gate.com/fd). These links were checked while preparing the draft; provider-specific contracts remain unverified.

## Where It Runs and How Someone Tries It

The client runs on an iOS or Android device or emulator. The target setup also needs a running PostgreSQL database, the planned Java server, and access to the selected AI provider. Provider configuration and the phone-to-server address must be documented once chosen.

The current client can be started from `mobile/` with:

```sh
flutter pub get
flutter run
```

Open the installed app on the selected phone or emulator. These commands start the client; they do not establish that the full product journey works.

The server command required by AGENTS.md is, from the future `server/` directory:

```sh
./mvnw spring-boot:run
```

That command is a planned run instruction: there is no server scaffold yet. Exact database startup, environment variables, provider credentials, and migration setup remain to be defined. The full-stack setup is not yet runnable from these instructions alone.

Based on the supplied event description and the learning skills, submission needs a public GitHub repository, these planning files, and a short demo video. Deployment is optional; no hosting platform is selected here. Record the real running journey described under `scope.md > What "Working" Looks Like`.

## Look and Feel

Implements `prd.md > Product Principles` and the Messenger-style direction under `prd.md > Core Experience`.

Use familiar friends, inbox, conversation, and call surfaces. Existing bundled typography is Nunito; this draft does not introduce a new visual system. Colors come from the Flutter theme, and spacing, radii, and tap targets come from `Dimens` as required by AGENTS.md.

Verify layouts at 360dp width and text scaling 2.0. Preserve the repository's contrast, text overflow, SVG semantics, loading announcements, and constrained-copy rules. Exact layouts and interaction states still need product review.

## Components

### Friend Discovery and Membership

Implements `prd.md > Essential Features` — Friends.

Profiles carry a character's name, personality, interests, and voice. Discover and the user's friends list are separate concerns: selecting a predefined character does not create a custom character. The server's controller, service, and repository layers handle discovery and add/remove operations; mobile repositories expose the corresponding data to view models.

### Inbox and Text Conversations

Implements `prd.md > Essential Features` — Chats and Continuity.

The mobile view renders conversation data and invokes commands. Its view model uses repositories, never external services directly. The server service orchestrates persona/context retrieval, AI requests, and persistence. Controllers accept and return DTO records; entities stay inside the service boundary.

### Image Sharing

Implements `prd.md > Essential Features` — Image sharing.

The server submits actual image content to a vision-capable provider with the relevant conversation. Upload contracts, storage location, supported formats, and retention are unresolved. No permanent image archive or cloud bucket is selected here.

### Voice Calls

Implements `prd.md > Essential Features` — Voice calls.

The client captures microphone audio and plays the AI's response; the server mediates the provider connection. The character's persona must remain consistent. Audio format, streaming transport, permissions flow, interruptions, and chat/call context transfer need an agreed contract before implementation.

### History and Memory Controls

Implements `prd.md > Essential Features` — Continuity and User control, and `prd.md > Product Principles` — Privacy by choice.

Conversation history and enduring memory are distinct concerns. Reopening a chat must not imply permission to turn all personal reflections or images into permanent memories. The persistence and AI-context paths must honor the chosen review, deletion, and memory controls. Their exact semantics are not established in the source PRD.

## Data Model

This is a conceptual model, not an approved SQL schema or authorization to create migrations.

| Entity or data | Role and persistence |
| --- | --- |
| AI character | Predefined persona, interests, and voice used in discovery and AI requests |
| User-to-friend association | Records an added friend; removing it changes the friends list. The effect on existing chats is unresolved |
| Conversation | Connects its participant and fictional character; reloads on return |
| Message | User or AI turn belonging to a conversation; persists as conversation history |
| Shared image | Input associated with a conversation turn; storage and deletion policy unresolved |
| Approved memory | Context retained according to explicit user controls; exact consent model unresolved |
| Live call context | Audio/session data needed during a call; whether anything persists afterward is unresolved |

Account identity and authentication are undecided. The older checklist proposes accounts, but the product PRD does not define that experience. Do not silently add an account system or assume a single shared user.

When the schema is agreed, apply AGENTS.md: primary keys; database-defaulted creation/update timestamps; explicit foreign-key delete behavior; indexes for real filters and joins; named, constrained state values; normalized facts; and UTC timestamp types. Version migrations and regenerate the schema snapshot from them. Do not hand-edit the snapshot.

## File Structure

Existing architecture conventions, with `server/` shown as planned. Feature-specific filenames and the Java base package remain to be finalized; angle-bracket entries are placeholders rather than literal directories.

```text
devpost-app/
├── devpost/
│   ├── scope.md                # Product boundary distilled from the existing PRD
│   ├── prd.md                  # Required submission copy of the product PRD
│   └── spec.md                 # This technical draft
├── docs/
│   ├── PRD.md                  # Existing locked product source
│   └── IMPLEMENTATION.md       # Existing older competition proposal
├── mobile/
│   ├── pubspec.yaml            # Existing client dependencies and assets
│   ├── lib/
│   │   ├── main.dart           # runApp entrypoint
│   │   ├── config/             # Environment and dependency wiring
│   │   ├── routing/            # Router and route names
│   │   ├── ui/
│   │   │   ├── core/           # Shared theme and widgets
│   │   │   └── <feature>/      # Per-feature view_model/ and widgets/
│   │   ├── domain/models/      # Immutable domain data
│   │   ├── data/
│   │   │   ├── repositories/   # Entity sources of truth; raw-data conversion
│   │   │   └── services/       # External-source wrappers
│   │   └── utils/              # Result and Command utilities
│   └── test/                   # Mirrors lib/ paths
└── server/                     # Planned; not present at draft creation
    ├── pom.xml                 # Maven build and dependencies
    ├── src/main/java/<base-package>/
    │   ├── controller/         # HTTP and DTO validation
    │   ├── service/            # Business rules and transactions
    │   ├── repository/         # Database access
    │   ├── entity/             # JPA mappings
    │   ├── dto/                # Request and response records
    │   ├── config/             # Configuration beans
    │   └── util/               # Stateless helpers, only where needed
    └── src/main/resources/db/
        ├── migration/          # Append-only Flyway migrations
        └── schema/schema.sql   # Generated snapshot
```

## External Services and Dependencies

The older implementation proposal names Amazon Bedrock for text/images and speech, S3 as optional image storage, and MCP for a separate competition track. These are candidate decisions from that document, not verified service contracts for this specification. An MCP server is not added to this scope merely because that earlier competition requested one.

Before provider-dependent work, confirm the provider and document its official references, exact request/response contracts, authentication, model access, audio transport, supported formats, limits, and costs. Until then, no endpoint, model ID, quota, pricing, or service availability is asserted here. PostgreSQL connection configuration and credentials handling also remain to be specified.

## Important Failure Modes

Product responses have not been agreed, so these are unresolved design points rather than new behavior requirements:

- **AI request failure:** failure/loading/retry presentation must be specified before messaging implementation.
- **Image or microphone access failure:** permission and upload failure behavior must be specified before those integrations.
- **Interrupted voice session:** visible end state, cleanup, and what happens to context must be specified before calls.

## Verification

Once implemented, exercise `scope.md > What "Working" Looks Like` using real AI responses, image understanding, and audio. Check add/remove, return-to-chat continuity, conversation deletion, and memory choices against the reviewed behavior. Sample or simulated behavior must be identified and cannot stand in for the core AI interactions.

For code changes, AGENTS.md requires `flutter analyze` and `flutter test` from `mobile/`, and `./mvnw verify` from `server/` once it exists. Schema changes also require generated snapshot/migration equivalence. No application checks are claimed from creating these Markdown plans.

## Decisions and Open Issues

Established decisions come from the existing PRD, AGENTS.md, and manifest, not a newly conducted learner interview. No personal learning uncertainty has been established.

Resolve before calling this spec approved or build-ready:

1. **POC boundary:** retain the whole existing journey or explicitly approve a smaller submission slice.
2. **AI provider:** confirm whether the older AWS proposal remains intended for text, images, and speech, within the current Spring Boot architecture.
3. **Identity and data ownership:** define who owns saved conversations and whether accounts are needed for the proof.
4. **Privacy semantics:** define consent, retention, memory editing/deletion, conversation deletion, and the effect of removing a friend.
5. **Interaction details:** specify first-use, empty, loading, error, image, and call states without inventing screens.
6. **Integration contracts:** finalize schema, API payloads, streaming audio, image storage, configuration, and fully reproducible startup steps.

The PRD uses “Chap,” while the existing mobile manifest says “Chaps” and the older implementation checklist says “Chapter.” This draft retains the locked PRD's name; it does not rename the app.
