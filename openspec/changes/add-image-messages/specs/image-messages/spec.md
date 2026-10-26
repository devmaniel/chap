## ADDED Requirements

### Requirement: Send photos
A user SHALL be able to send a message with 1 to 4 photos from their phone, with or without text.

#### Scenario: Photo with a caption
- **WHEN** a user sends a photo of their lunch with "Look what I made"
- **THEN** the message shows the photo and the caption as theirs

#### Scenario: Photo only
- **WHEN** a user sends a photo with no text
- **THEN** the message is accepted and shows the photo

#### Scenario: Too many photos
- **WHEN** a user tries to send 5 photos in one message
- **THEN** the server rejects it with `invalid_request`

### Requirement: Reply about the photo
The friend's reply to a photo message SHALL be based on what the photo actually shows, in the friend's own personality.

#### Scenario: Ask about a detail
- **WHEN** a user sends Momo a photo of a red bicycle and asks "What color is it?"
- **THEN** Momo's reply says it is red

#### Scenario: Unsupported file
- **WHEN** the reply request carries a file that is not JPEG, PNG, WebP or HEIC, or is over 5 MB
- **THEN** the server responds `400` with `invalid_image` and saves no reply

### Requirement: Photos stay on the phone
The server SHALL NOT store photo contents. It SHALL only store which phone photos belong to which message.

#### Scenario: After the reply
- **WHEN** the friend has replied to a photo message
- **THEN** the server holds no copy of the photo, and the chat on that phone still shows it

#### Scenario: Photo deleted from the phone
- **WHEN** a user deletes a shared photo from their phone and reopens the chat
- **THEN** the message shows a missing-photo placeholder instead of crashing
