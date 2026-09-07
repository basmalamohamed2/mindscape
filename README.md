# MindScape

**MindScape** is a Flutter mind-mapping app for organizing thoughts, planning projects, and brainstorming — solo or in real time with collaborators. Built as a full-stack mobile project on Firebase, with real-time sync, offline support, media attachments, AI-assisted brainstorming, and task reminders.

> Note: this is Android-focused for now. See [Known Limitations](#known-limitations--future-work).

---

## Features

### Authentication
- Google Sign-In
- Email/Password sign-up and sign-in
- Forgot password (email reset link)
- Email verification on registration
- Persistent session (works offline once signed in)

### Mind Map Library (Home)
- Live list of your maps, synced in real time from Firestore
- Create, rename, and delete maps
- Client-side search
- **Share a map** with another MindScape user by email — they get full edit access

### Canvas
- Interactive node graph: drag to reposition, tap to edit, pinch to zoom/pan
- Add child ideas, recolor nodes, delete a branch (with confirmation)
- Deleting a root node auto-promotes a child instead of orphaning the tree
- **Photo attachments** on any node (via Cloudinary)
- **AI-powered suggestions** — generate related sub-ideas for any node (via Gemini) and add them with one tap
- **Convert any node into a task** with a due date — schedules a local reminder notification, tappable to jump straight back to that node

### Real-Time Collaboration
- Multiple people can edit the same map at the same time
- Each node is stored as its own Firestore document, so concurrent edits to *different* nodes never overwrite each other (a common bug in naive "one big array" mind-map implementations)

### Offline Support
- Firestore's local cache means the app works fully offline: view, edit, and create
- Clear "you're offline" banner
- Per-item "syncing…" indicator once you're back online, until pending writes are confirmed by the server

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter |
| State management | Riverpod (manual providers — no code generation) |
| Backend | Firebase Auth, Cloud Firestore |
| Media storage | Cloudinary (unsigned client uploads) |
| AI suggestions | Google Gemini API |
| Local notifications | `flutter_local_notifications` + `timezone` |
| Fonts | Google Fonts (Fraunces, Inter, JetBrains Mono) |

### Why not Firebase Storage / Cloud Functions?
Both require Firebase's paid **Blaze** plan (a linked card), even for near-zero usage. This project uses free-tier alternatives instead — Cloudinary for images, and on-device local notifications instead of server-triggered FCM push. Both are documented as deliberate trade-offs in the relevant source files, with a note on how to swap in the "proper" version later.

---

## Architecture

Clean Architecture per feature (`logic/` / `screens/` / `widgets/`). Nodes live in a `nodes` subcollection per map (not a single array field), so collaborators editing different nodes at once never overwrite each other. Full breakdown in [PROJECT_REPORT.md](./PROJECT_REPORT.md).

---

## Setup

Needs a Firebase project (Auth + Firestore), a Cloudinary account (unsigned upload preset), and a Gemini API key — plug them into the constants at the top of `node_media_repository.dart` and `ai_suggestions_repository.dart`, add your own `google-services.json`, then `flutter pub get && flutter run`.

---

## Known Limitations & Future Work

- **Android only** for now — no `firebase_options.dart` is checked in; iOS/Web would need `flutterfire configure`.
- **API keys are embedded client-side** (Cloudinary upload preset, Gemini key). Fine for a demo/personal project; before any real launch, proxy the Gemini calls through a Cloud Function so the key never ships inside the app.
- **No Dark/Light theme toggle.** All colors are compile-time `const` values for performance — supporting a live theme switch would mean removing `const` across most of the app's widgets. Deliberately deferred.
- **Canvas pan vs. node drag** can occasionally conflict (a fast drag may pan the whole canvas instead of moving a node) — a known trade-off of using `InteractiveViewer` alongside per-node gesture detectors.
- **Image deletion from Cloudinary** isn't automated (would require a signed server-side request); removing a node's photo drops the reference but the file itself needs manual cleanup in the Cloudinary dashboard.

---

## License

Personal / educational project.