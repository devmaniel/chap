# Chapter — AWS Technical Implementation & Hackathon Checklist

**Product:** Flutter-native AI social simulation with fictional friends, messaging, image sharing, and in-app voice calls.  
**Planned primary track:** Alexa+ (self-hosted MCP server route).  
**Planned mini challenge:** AWS Builder (documented Amazon Bedrock integration).  
**Deadline:** October 24, 2026, **3:00 AM Philippine time** (October 23, 12:00 PM PDT).  
**Status:** Planning checklist; nothing is marked complete yet.

> **Eligibility gate:** The official competition requires individual entrants to be at least the legal age of majority where they reside. Building Chapter independently is still possible if an individual isn't eligible to enter. See the official rules before submitting.

## 1. Scope — what must work

- [ ] Create/select a fictional AI friend with name, persona, interests, and voice preference.
- [ ] Add the friend to an inbox and open a 1-to-1 conversation.
- [ ] Send a text message and receive a persona-consistent AI response.
- [ ] Attach an image and receive a response grounded in the image.
- [ ] Start and end a real-time in-app **AI audio** call (not a cellular telephone call).
- [ ] Continue a conversation after switching between text and audio.
- [ ] Retrieve an earlier conversation detail with permission, using a real MCP tool call.
- [ ] Clearly label every character as AI, and let users delete chats and opt out of saved memory.

**Not required for MVP:** public feed, human-to-human messaging, likes, game levels, proactive attention-seeking notifications, group calls, video calls, recommendation algorithm.

## 2. Proposed architecture

```text
Flutter mobile app
  |-- REST/HTTPS: friends, messages, images, preferences
  |-- WebSocket: live audio frames / playback
  v
Node.js / TypeScript API + audio gateway
  |-- Amazon Bedrock Nova 2 Lite: text + image understanding
  |-- Amazon Bedrock Nova 2 Sonic: bidirectional speech
  |-- MCP client ----(Streamable HTTP)---> Chapter MCP server
  |                                     |-- get_friend_profile
  |                                     |-- get_conversation_context
  |                                     '-- save_approved_memory
  |-- PostgreSQL: users, friends, messages, memories, call sessions
  '-- S3: uploaded images (optional persistence)
```

**Important:** A Node backend using ordinary functions is not *automatically* an MCP implementation. The MCP server must expose an actual, testable MCP protocol endpoint, and Chapter must genuinely invoke it. The Flutter app is the product UI; a separate web simulator is not required for the chosen MCP route according to the official FAQ, but a small MCP test client is useful evidence.

## 3. AWS setup — must test early

- [ ] Create or access an AWS account with permitted billing and appropriate credentials.
- [ ] Configure an IAM role/user with narrowly scoped Bedrock and, if used, S3 permissions.
- [ ] Keep AWS keys and credentials on the server, never inside the Flutter app or GitHub repo.
- [ ] Set AWS Budgets / cost alerts and understand Bedrock's consumption pricing.
- [ ] Confirm model availability, account access, quotas, and applicable Region **before building around them**.
- [ ] Make one real text request to **Nova 2 Lite** (`amazon.nova-2-lite-v1:0`).
- [ ] Make one real bidirectional voice test with **Nova 2 Sonic** (`amazon.nova-2-sonic-v1:0`).
- [ ] Test the actual language(s) and accent(s) you intend to support; do not assume Tagalog/Taglish works well.
- [ ] Add timeouts, retries where appropriate, and clear UI errors when an AI request fails.
- [ ] Record AWS services/models used for the mandatory product-feedback field.

**Budget note:** The hackathon rules say promotional credit codes were exhausted on October 7, 2026; don't assume credits will be available. A real AWS call may incur charges.

## 4. Backend and data

- [ ] Implement authentication and isolate every user's data from other accounts.
- [ ] Create basic tables: `users`, `ai_friends`, `conversations`, `messages`, `approved_memories`, `call_sessions`.
- [ ] Give each AI character a stable persona record; apply the same persona in messages and calls.
- [ ] Create endpoints for friends, messages, image uploads, call session setup, and data deletion.
- [ ] Use server-generated IDs, access checks, and input limits on every operation.
- [ ] Store conversation turns to retain current-session context.
- [ ] Only save enduring memories with the user's permission; provide review/delete controls.
- [ ] Define retention behavior for voice transcripts, images, and chat history.

## 5. Text and image messaging — Bedrock Nova 2 Lite

- [ ] `POST /messages`: verify user + conversation ownership, load friend persona and recent context, invoke Bedrock, save response.
- [ ] Support streaming text responses if practical; otherwise show clear loading status.
- [ ] `POST /media`: validate image file type and size, upload securely, associate it with the message.
- [ ] Pass the image to a vision-capable model; verify the AI can describe what was *actually* in the image.
- [ ] Prevent accidental long-term storage of personal images unless the user chooses it.
- [ ] Test unsupported images, upload failures, and model hallucinations.

## 6. Voice calls — Bedrock Nova 2 Sonic

- [ ] Ask microphone permission only when a call begins.
- [ ] Capture microphone audio in the supported format (reference integration uses mono PCM, 16 kHz input).
- [ ] Stream audio **Flutter ↔ backend ↔ Bedrock**, and play returning audio (reference uses 24 kHz output).
- [ ] Show connecting / listening / speaking / muted / ended states.
- [ ] Support mute, hang up, interruption / turn taking, network loss, and resource cleanup.
- [ ] Pass the selected AI friend's persona and allowed context when the call starts.
- [ ] Preserve useful chat-to-call context; save only consented summaries or transcripts afterward.
- [ ] Handle the documented **8-minute connection limit** by ending gracefully or using the renewal approach.
- [ ] Test latency and audio stability on an actual phone, not only a desktop simulator.

## 7. Alexa+ track — real MCP integration (**mandatory for this route**)

- [ ] Build a self-hosted MCP server supporting **MCP specification 2025-11-25 or newer**.
- [ ] Use **Streamable HTTP**, not legacy standalone HTTP+SSE transport.
- [ ] Implement MCP initialization and `tools/list`, `tools/call` behavior through an MCP SDK.
- [ ] Expose useful tools, e.g. `get_friend_profile`, `get_conversation_context`, `save_approved_memory`.
- [ ] Define tool schemas and validate inputs. Check authorization by user/conversation for each call.
- [ ] Have the main backend act as a real MCP client, invoking tools at runtime when the AI needs context.
- [ ] Demonstrate one actual tool invocation with an observable result (not a hardcoded transcript).
- [ ] Test malformed inputs, wrong-user access, missing memories, and duplicates.
- [ ] Run the server on a reachable HTTPS endpoint for testing, or provide a clearly runnable local test setup. The event FAQ says permanent hosting after submission is not required.
- [ ] Capture MCP traces or logs for documentation, without exposing user secrets.

**Do not confuse these:** An AWS Bedrock request qualifies toward the AWS Builder mini challenge, **not by itself** for the Alexa+ primary track. The real MCP server satisfies the chosen Alexa+ integration route.

## 8. Safety, privacy, and reliability

- [ ] Label characters as fictional AI, never human users.
- [ ] Avoid manipulative relationship mechanics or guilt-based re-engagement.
- [ ] Add straightforward moderation / safe-response handling for text, images, and calls.
- [ ] Avoid recording or preserving raw call audio by default.
- [ ] Let users view/delete history and any long-term saved memories.
- [ ] Protect backend endpoints, S3 objects, MCP tools, logs, and API credentials.
- [ ] Validate data separation between users and between characters.
- [ ] Test denied microphone permission, airplane mode, interrupted streams, model errors, and quota/budget failures.

## 9. End-to-end demonstration test

- [ ] Open Chapter in Flutter on a phone or emulator.
- [ ] Create or choose a friend with a distinct persona.
- [ ] Send a message and receive a real Nova 2 Lite answer.
- [ ] Upload a photo and ask the AI about visible details.
- [ ] Initiate a live Nova 2 Sonic voice call; talk, hear its answer, and end it.
- [ ] Return to the same chat; verify session continuity.
- [ ] Ask about something deliberately saved previously; show the actual MCP request and returned context.
- [ ] Verify the friend remains consistently identified as AI throughout.

## 10. Official submission checklist

- [ ] Verify competition eligibility and rules (**age of majority required for individual entrants**).
- [ ] Choose **Alexa+** as primary track and **AWS Builder** as mini challenge.
- [ ] Submit a **GitHub** repo with full Flutter, backend, MCP server, setup steps, and assets.
- [ ] Repository is **public with an open-source license** or **private with reviewer access**.
- [ ] If private, follow the official rules/FAQ for Amazon and Devpost collaborator invitations; send invitations around submission time because they expire.
- [ ] README explains how to configure environment variables, run Flutter/backend/MCP, and make real Bedrock and MCP calls.
- [ ] Demo video is **under 3 minutes**, public on **YouTube or Vimeo**, in English, and shows the running project.
- [ ] Video clearly demonstrates the genuine MCP runtime integration, not just that Chapter has a chat/call feature.
- [ ] Provide a text description of the actual product and how it works.
- [ ] Provide **product feedback for every Amazon tool/API/SDK used**: usage, onboarding, positives, friction, and whether you'd use it again.
- [ ] In AWS Builder feedback, explicitly describe the AWS services and how they work in Chapter.
- [ ] If using a preexisting project, clearly explain what was built/updated during this hackathon.
- [ ] Ensure any demo media/avatars/music are original or used with permission.
- [ ] Provide simple judge testing instructions and access where applicable.
- [ ] Optional: submit actionable **friction logs**, which can contribute up to a 10% judging bonus.
- [ ] Submit before **October 24, 2026, 3:00 AM PHT**.

## 11. Suggested build order

1. **Proof of AWS access:** one Nova Lite response; one Nova Sonic round-trip.
2. **Core product:** AI friend profiles, chat, stable personality, stored sessions.
3. **MCP:** real Streamable HTTP server, tool discovery, runtime calls for context.
4. **Image sharing:** secure upload and multimodal response.
5. **Voice calling:** Flutter microphone, stream relay, playback, reconnect/end handling.
6. **Polish & submission:** error paths, privacy controls, demo video, README, feedback.

**Scope rule:** Don't add social feeds, public friend matching, real-user messaging, group calls, or gamification before one full friend → message → photo → call → memory journey works.

## Official references (checked October 15, 2026)

- Hackathon rules: https://amazonappdev2026.devpost.com/rules
- Hackathon FAQs: https://amazonappdev2026.devpost.com/details/faqs
- Alexa+ MCP quickstart/reference: https://www.developer.amazon.com/docs/alexaplus/add-ons/mcp-toolkit-quickstart.html
- Nova 2 Lite multimodal docs: https://docs.aws.amazon.com/nova/latest/nova2-userguide/using-multimodal-models.html
- Nova 2 Sonic getting started: https://docs.aws.amazon.com/nova/latest/nova2-userguide/sonic-getting-started.html
- Nova 2 Sonic model card: https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-amazon-nova-2-sonic.html
