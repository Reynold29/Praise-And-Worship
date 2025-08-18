### Product Requirements Document (PRD): Worship Companion

#### Overview
Worship Companion is an offline-first Flutter app for browsing, searching, and performing Christian worship songs. It provides curated English and Kannada catalogs synced from Supabase to an encrypted local database, fast search (including Kannada transliteration), favorites management, detailed song view with optional chords and live transposition, personalized theming, and AI-assisted song capture from images (Google Vision + Gemini). Users can also submit songs for review to expand the collection.

#### Goals & Objectives
- Deliver a fast, reliable, offline-capable worship songbook on mobile and desktop.
- Provide high-quality reading/performing UX: adjustable text size, toggle chords, transpose.
- Support multilingual access, starting with English and Kannada (with transliteration search).
- Enable safe community growth via AI-assisted capture and review-based submission.
- Respect privacy and reliability: local encryption, minimal blocking on network failures.

#### Features
- **Catalog and search**
  - English and Kannada catalogs synced from Supabase to local encrypted DBs
  - Global search with filters (language, sort); transliteration-assisted search for Kannada
  - Alphabetical filter bars for English (A–Z) and Kannada alphabets
- **Favorites**
  - Mark/unmark songs; favorites view by language; quick clear per tab
- **Song detail**
  - Lyrics with optional chord lines; chord display toggle
  - Live transposition in semitones; key display derived from DB or first chord
  - Adjustable reading font size; modern, legible layout
- **Personalization and onboarding**
  - Onboarding asks for username; optional profile photo (cropping, local-only)
  - Dynamic Material 3 theming; custom seed color; AMOLED black; light/dark toggle
- **AI-powered capture and submission**
  - Scan song images (camera/gallery), OCR via Google Vision, structure via Gemini
  - Prefill manual form; submit to Supabase `pending_songs` for review
- **Sync and reliability**
  - Background sync from Supabase when online; realtime updates for `english_data`
  - Offline-first operation with encrypted local storage (SQLCipher)
  - Connectivity checks; resilient startup if env/remote services fail
- **Developer utilities**
  - In-app update checks (Android)
  - Developer options to clear local encrypted DBs

#### User Personas
- **Worship Leader/Musician**: Needs reliable, readable lyrics with chords, transposition, and quick search at services and rehearsals, often offline.
- **Volunteer/Choir Member**: Wants favorites and readable fonts to follow along.
- **Song Curator/Admin**: Collects new songs via scanning/manual entry; submits for review.
- **Multilingual Worshipper**: Searches Kannada songs using Latin input via transliteration.

#### Technical Requirements
- **Platforms**: Flutter (Android, iOS, macOS, Windows, Linux, Web)
- **Core packages**:
  - State/UI: `flutter`, `provider`, `dynamic_color`, `lottie`, `animated_text_kit`
  - Storage/security: `sqflite_sqlcipher`, `flutter_secure_storage`, `shared_preferences`, `path_provider`
  - Networking/services: `supabase_flutter`, `http`, `flutter_dotenv`, `connectivity_plus`
  - Media/permissions: `image_picker`, `permission_handler`, `image_cropper`
  - Language: `inditrans` (transliteration for Kannada)
  - Platform: `in_app_update`, `url_launcher`
- **Backend**: Supabase (tables: `english_data`, `kannada_data`, `pending_songs`; realtime channel for `english_data`)
- **Environment variables (`.env`)**:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_VISION_API_KEY`, `GEMINI_API_KEY`
- **Data model (`Song`)**: id, createdAt/updatedAt, title, lyrics, chords (optional), category/language, authorName, genre, keySignature, bpm, youtubeLink
- **Local persistence**: two encrypted SQLite DBs: `songs_encrypted.db` (English), `kannada_songs_encrypted.db` (Kannada); keys via `flutter_secure_storage`
- **Privacy and offline**: profile data and images are local-only; sync is pull-only; favorites in `SharedPreferences`

#### Milestones
- **M1: Offline English catalog** — Local encrypted DB; initial sync from Supabase; basic reading
- **M2: Kannada support** — Separate Kannada DB; transliteration-based search and alphabet filter
- **M3: Favorites and global search** — Favorites provider; global search UI with language filters/sorts
- **M4: Chords and transposition** — Toggle chords; live transpose; better alignment (see chord guide)
- **M5: AI scan and manual submission** — Image OCR (Vision), parse (Gemini), handoff to manual form; submit to `pending_songs`
- **M6: Theming and settings** — Dynamic color, custom seed, AMOLED black, dark/light toggle; developer options
- **M7: Realtime updates and polish** — Expand realtime to Kannada; improve error UX; performance tuning; store screenshots/docs

#### Success Metrics
- **Engagement**: DAU/WAU, sessions per user, median session length
- **Feature usage**: searches/day, favorites added/removed, chord toggle rate, transpose actions
- **AI capture funnel**: scan starts → OCR success → Gemini success → submission completion
- **Reliability**: sync success rate, crash-free sessions, startup time, offline success rate
- **Content quality**: approved submissions/week, review turnaround time
- **Internationalization**: Kannada search success and retention among Kannada users


