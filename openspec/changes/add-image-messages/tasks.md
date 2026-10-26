## 1. Database

- [x] 1.1 Migration: `message_images` table with `updated_at` trigger
- [x] 1.2 Regenerate the schema snapshot and run the replay-vs-snapshot diff

## 2. Server

- [x] 2.1 `MessageImage` entity and repository; send accepts `imageRefs` (max 4, text may be empty when refs exist); messages return `imageRefs`
- [x] 2.2 Reply endpoint accepts multipart `images` (max 4, type and 5 MB checks, `invalid_image`)
- [x] 2.3 `GeminiClient` sends images as `inlineData` on the latest user turn; older photo messages become "(shared N photos)" text
- [x] 2.4 Tests: photo-only send, 5 refs rejected, bad type/size rejected, images reach the stubbed Gemini request, nothing image-related persisted beyond refs
- [x] 2.5 `./mvnw verify` passes

## 3. Mobile

- [x] 3.1 `ChatRepositoryRemote.sendMessage` sends `imagePaths` as `imageRefs`
- [x] 3.2 `getReply` attaches the latest own message's photos, downscaled to 1600 px JPEG, skipping missing files
- [x] 3.3 Message bubble shows a placeholder for a missing local photo, if not already handled
- [x] 3.4 Tests for send with images and reply with multipart
- [x] 3.5 `flutter analyze` and `flutter test` pass

## 4. Verify

- [ ] 4.1 With a real Gemini key on a device: send a photo, ask about a visible detail, the reply matches the photo
