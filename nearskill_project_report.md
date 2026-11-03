# PROJECT REPORT: NEARSKILL - LOCAL SKILLS MARKETPLACE

---

## 1. ABSTRACT
The problem of finding reliable, skilled local service providers swiftly remains a challenge despite the prevalence of digital platforms. Frequently, consumers face fragmented information, unverified reviews, and complex booking procedures, while skilled workers lack accessible platforms geographically optimized to connect them to immediate local demand without paying exorbitant commission fees. "NearSkill" is proposed as a comprehensive, location-based service marketplace designed to bridge the gap between service seekers and nearby skilled professionals in real-time.

Developed using the Flutter framework for a high-performance cross-platform mobile experience and Supabase as a robust, open-source Backend-as-a-Service (BaaS), NearSkill implements a highly scalable and reactive architecture. The application leverages real-time geolocation mapping (via OpenStreetMap and Leaflet integration) to discover and cluster workers within conversational proximity, enabling an immediate and seamless connection. The platform integrates custom remote procedure call (RPC) authentication, low-latency WebSocket messaging, secure service request (booking) administration, a fully transparent review/rating engine, and an extensive administrative dashboard to manage user roles, ID verifications, and service disputes. 

By eliminating intermediaries and enhancing transparency through proximity-based searches and mathematically validated ratings, NearSkill significantly optimizes local gig-economy interactions. It serves as an empowering digital ecosystem, equipping the service provider (worker) seeking immediate employment and offering instant relief to the user requiring immediate technical assistance or labor.

---

## 2. LIST OF FIGURES
1. **Figure 1**: Three-Tier System Architecture Diagram (Client layer, BaaS layer, Database layer)
2. **Figure 2**: Level 0 Data Flow Diagram (Contextual boundaries of NearSkill)
3. **Figure 3**: Level 1 Data Flow Diagram (Internal process modeling and data stores)
4. **Figure 4**: User Activity Diagram (End-to-end booking flow)
5. **Figure 5**: Worker Activity Diagram (Availability toggling and request acceptance)
6. **Figure 6**: Admin Activity Diagram (System moderation and dispute resolution)
7. **Figure 7**: Overall System Use Case UML Diagram (Actor interactions)
8. **Figure 8**: Entity Relationship (ER) / Database Schema Diagram
9. **Figure 9**: User Authentication & Onboarding UI Interface
10. **Figure 10**: Nearby Workers Discovery (Interactive Map & Coordinate Translation)
11. **Figure 11**: Real-time Chat Interface (Text and Image Media Bubbles)
12. **Figure 12**: Admin Dashboard & Support Ticket Resolution Interface

*(Note: The actual graphical UML diagrams and UI screenshots are to be appropriately attached in the final printed document submission as per the placeholders)*

---

## 3. ABBREVIATIONS
* **API**: Application Programming Interface
* **BaaS**: Backend as a Service
* **BLOB**: Binary Large Object
* **DB**: Database
* **DFD**: Data Flow Diagram
* **ERD**: Entity Relationship Diagram
* **GPS**: Global Positioning System
* **JSON**: JavaScript Object Notation
* **OEM**: Original Equipment Manufacturer
* **OSM**: OpenStreetMap
* **PK/FK**: Primary Key / Foreign Key
* **RLS**: Row Level Security
* **RPC**: Remote Procedure Call
* **SRS**: Software Requirements Specification
* **UI/UX**: User Interface / User Experience
* **UML**: Unified Modeling Language
* **UUID**: Universally Unique Identifier

---

## 4. CHAPTER 1: INTRODUCTION

### 1.1 BACKGROUND
The gig economy and localized freelance service sectors have expanded exponentially over the last decade, fueled by widespread smartphone adoption and the normalization of app-based labor (such as ride-sharing and food delivery). However, when individuals require immediate assistance for domestic chores, plumbing, electrical work, carpentry, or local tutoring, the solutions are significantly less elegant. Traditionally, populations rely on neighborhood word-of-mouth or disorganized classified directories. These methods are inherently slow, notoriously unreliable, and lack basic quality assurance. 

Existing digital solutions in the labor market are often heavily centralized corporations that charge massive commission fees to the worker, obscuring communication to force payments through their proprietary gateways, or they focus too broadly on regional search rather than emphasizing hyper-local, instant discovery. There is an evident market failure in providing a low-friction conduit between neighborhood supply and localized demand.

NearSkill stems from the necessity to construct an empowering, decentralized-feeling platform that acts strictly as a geographical facilitator connecting nearby demand directly with local supply. By focusing on distance vectors and unfiltered user reviews, NearSkill fosters community engagement and provides a direct, unmediated communication channel between the employer and the professional.

### 1.2 SCOPE
The scope of NearSkill is meticulously bounded to the discovery, communication, geographical tracking, and status administration of service agreements between a standard consumer (User) and a service provider (Worker). 
The application will encompass:
* **Custom Identity Management**: Complex dual-mode profile creation for Users and Workers, sidestepping standard auth to enforce database-level relational constraints upon sign-up.
* **Geospatial Processing**: Map-centric real-time plotting of available workers utilizing the device's hardware GPS, converting latitude/longitude matrices into interactive map clusters.
* **Algorithmic Filtering**: Advanced sub-querying of workers by their registered skills and maximum hourly rates.
* **Real-time Engine**: Socket-based text and media chat for instant negotiation without exposing private phone numbers, preserving user privacy.
* **Lifecycle State Machine**: A complete booking lifecycle tracking system transitioning states from strictly `Pending -> Confirmed -> Completed -> Cancelled`.
* **Trust Mechanism**: A post-service rating and review aggregation engine preventing fraudulent or unassociated reviews.
* **System Administration**: An administrative portal for overseeing support tickets, manually verifying worker official ID cards, and deploying account bans for ecosystem health.

*Out of Scope*: Direct integration of third-party payment gateways (Stripe/PayPal) is currently deferred. Transactions and agreements are established via the platform, while actual monetary exchanges occur out-of-band locally between the user and worker.

### 1.3 OBJECTIVE
The primary objectives underpinning the software engineering of the NearSkill project are:
1. **Seamless Delivery**: To develop a cross-platform mobile application natively compiled using Flutter that provides a 60-fps, responsive UI for rapid service discovery regardless of the target OS (Android/iOS).
2. **Instant Matching**: To utilize real-time geolocation hardware and Haversine distance formulas to match users with the nearest available active workers accurately.
3. **Robust Backend**: To implement a secure, scalable backend architecture utilizing PostgreSQL hosted via Supabase, bypassing traditional REST APIs for direct edge-secured socket connections.
4. **Meritocratic Trust Validation**: To establish an immutable, transparent review system directly tied strictly to completed cryptographic service request IDs, building a verifiable metric of trust for independent gig workers.
5. **Frictionless Communication**: To construct a real-time, low-latency communication interface streamlining job negotiations safely.

### 1.4 PROPOSED SYSTEM
The proposed NearSkill system operates on a decoupled multi-tier architecture. Instead of positioning an agency as an intermediary authority, NearSkill puts the operational control entirely in the hands of the end-users. 
- **The Users (Consumers)** log in, authorize location hardware permissions, and are immediately presented with a map overlay populated with colored pins representing nearby workers. Interaction is immediate; they select a pin, read the worker's historical performance, evaluate the hourly rate, and initiate an asynchronous chat or direct booking request.
- **The Workers (Service Providers)** maintain a detailed digital asset representing their skills. They toggle a boolean "Availability" state. When active, background and foreground loops broadcast their geospatial coordinates to the cloud, placing them dynamically on the consumer discovery map. They possess an Inbox to respond to incoming local bids.
- **The Admins (Moderators)** operate from a hidden, elevated role dashboard. They do not participate in the gig economy directly but act as the judiciary of the platform, resolving support disputes, verifying the authenticity of worker identification documents uploaded to the cloud, and sanitizing the ecosystem by permanently suspending bad actors.

---

## 5. CHAPTER 2: SRS (SOFTWARE REQUIREMENTS SPECIFICATION)

### 2.1 PRODUCT OVERVIEW
NearSkill is architecturally a mobile-first, reactive application focused on hyper-local empowerment. It is built as a self-contained ecosystem encompassing location tracking, relational database management, cloud blob-storage, and immediate WebSockets-based messaging. The application state on the client side is fully deterministic and managed via Riverpod (a reactive caching and data-binding framework), ensuring UI frames instantly reflect the shifting cloud database state without requiring pull-to-refresh mechanics.

### 2.2 PRODUCT FUNCTIONALITY (ACTOR PERSPECTIVES)
**1. Unauthenticated User (Guest):**
* Capability to view the Splash screen and navigate the Auth tree.
* Can submit registration payloads categorized as either 'Client' or 'Provider'.

**2. Authenticated End-User (Client):**
* View a dynamically updated map powered by OpenStreetMap rendering worker vector pins.
* Filter the map rendering based on specific string-keyed skills (e.g., 'Plumbing', 'Electrical').
* Probe a worker profile, viewing aggregated star ratings (`AVG()` queries) and reading historical comments.
* Generate a `service_request` tuple attached to a worker ID.
* Chat synchronously via an instant messaging interface.
* Create a `review` entity upon the `service_request` reaching a 'completed' state.

**3. Authenticated Worker (Provider):**
* Access to all Baseline Client features.
* A specialized Dashboard displaying metric cards (Total Earnings, Request Volume, Active Rating).
* Manage their `worker_skills` bridging table, adding or dropping available services.
* A 'Go Online / Offline' toggle that manipulates the `availability_status` column, instantly updating their map visibility globally.
* Accept or Reject incoming pending network `service_requests`.
* Upload binary photo payloads for ID Verification (`id_card_url`).

**4. Authenticated Administrator:**
* View full list of registered UUIDs across the platform.
* Manually flip `verification_status` strings from 'pending' to 'approved' or 'rejected'.
* Manipulate the `is_banned` boolean on any user intercepting their login RPC constraint.
* Read and provide text responses to system `support_tickets`.

### 2.3 DESIGN AND IMPLEMENTATION CONSTRAINTS
* **Location Dependency & Hardware Reliance**: The application's core unique selling proposition relies entirely on the device's hardware GPS module. Users denying `ACCESS_FINE_LOCATION` will experience severely degraded app functionality and will be prompted to grant permissions recursively.
* **Network Latency & Persistence**: A continuous internet connection is mandatory. NearSkill does not support offline mutation of data; however, UI state caching via SharedPreferences prevents catastrophic crashes during temporary packet loss.
* **Storage Limits & Quotas**: Managing large image uploads (profile photos, uncompressed ID cards, high-res chat images) requires client-side image compression strategies to prevent hitting Supabase free-tier Storage bucket limits prematurely.
* **Authentication Constraints**: Due to the heavily relational nature of a worker profile relying on a standard user profile constraint, standard OAuth providers are disabled in favor of heavily guarded PostgreSQL Remote Procedure Calls (RPC) mapping transactions across multiple tables atomized during account creation.

### 2.4 HARDWARE REQUIREMENTS
**Server Side (Cloud Infrastructure):**
* Hosted seamlessly by Supabase Infrastructure.
* **Database Engine**: PostgreSQL 15.
* **Connection Pooling**: PgBouncer configuration to handle thousands of simultaneous mobile client connections.
* **Realtime**: Elixir-based real-time engine processing WAL (Write-Ahead Log) mutations and broadcasting via WebSockets.

**Client Side (Mobile Device iOS/Android):**
* **Processor (CPU)**: Minimum Quad-core architecture (1.4 GHz+).
* **Memory (RAM)**: Minimum 2 GB (4 GB recommended for smooth map tile rendering).
* **Storage**: Minimum 50 MB to 100 MB free space for the compiled binary and persistent cache (images/map tiles).
* **Sensors**: Hardware GPS module, Network location provider.

### 2.5 SOFTWARE REQUIREMENTS
**Development Environment Details:**
* **OS**: Windows 10/11 / macOS (latest) / Linux (Ubuntu 20.04+).
* **SDK Ecosystem**: Flutter SDK (^3.5.0), Dart Language SDK (^3.5.0).
* **IDE**: Visual Studio Code or Android Studio with Flutter/Dart analysis plugins.

**Application Stack Versions:**
* **BaaS Integration**: `supabase_flutter` (^2.8.0).
* **Mapping Framework**: `flutter_map` (^7.0.2), `latlong2` (^0.9.1).
* **Hardware Interfacing**: `geolocator` (^13.0.1), `geocoding` (^3.0.0), `image_picker` (^1.1.2), `permission_handler` (^11.3.1).
* **State Management**: `flutter_riverpod` (^2.5.1).
* **Target Deployment SDKs**: Android (Min SDK 21 - Lollipop), iOS (Deployment Target 12.0+).

### 2.6 COMPREHENSIVE FUNCTIONAL REQUIREMENTS
* **FR-01 (Transactional Auth)**: The system shall capture user registration inputs and execute a custom `register_custom_user` RPC. If the user marks `isWorker = true`, the RPC must guarantee the creation of a child constraint in the `worker_profiles` table or rollback the entire transaction to prevent orphaned identities.
* **FR-02 (Secure Sessions)**: The mobile application must preserve the encrypted session token locally and utilize it to re-hydrate the application state upon cold restarts.
* **FR-03 (Spatial Broadcasting)**: The system must, when a worker is online, capture `.getCurrentPosition()` events and `UPDATE` the `worker_profiles.current_latitude / longitude` columns to update map vectors.
* **FR-04 (Low-Latency Chat Engine)**: The system shall support bidirectional transmission of JSON text schemas and image URL blobs via the `chat_messages` table logic. Subscribed clients must listen to the database streams to append bubbles to the screen in <200ms.
* **FR-05 (Immutable Booking Lifecycle)**: The system must disallow deletion of a `service_request`. It can only mutate through designated status phase gates to preserve the integrity of the work history logs.
* **FR-06 (Restricted Reviewing)**: The system must functionally restrict the creation of a row in the `reviews` table until a corresponding `service_request` exists matching the `request_id` with a status of 'completed'.
* **FR-07 (Administrative Authority)**: The system shall provide a `role='admin'` check bypassing standard UI routers, directing authorized users to a specialized data-grid view capable of executing DELETE statements on flagged accounts.

### 2.7 NON-FUNCTIONAL REQUIREMENTS
* **NFR-01 (Performance)**: Map tile rendering and worker pin clustering must render at a sustained 60 Frames Per Second (FPS) on average mid-range hardware to prevent perceived UI lag.
* **NFR-02 (Security)**: All Remote Procedure Calls (RPCs) utilizing `pgcrypto` must encrypt passwords using standard `crypt()` algorithms with high cost-factors before insertion into the `users` table. Client traffic must be strictly HTTPS/WSS.
* **NFR-03 (Scalability)**: The database architecture must rely on B-Tree indexed Foreign Keys to guarantee rapid query resolution even as the `chat_messages` table expands logarithmically.
* **NFR-04 (Usability)**: The design system must enforce contrast-checked, large-typography UI elements ("Glassmorphic" themes utilizing `GoogleFonts.inter`) to ensure readability outdoors under direct sunlight where real-world gigs typically occur.

---

## 6. CHAPTER 3: MATERIAL AND METHODS

### 3.1 DESIGN METHODOLOGY AND UX PHILOSOPHY
The software engineering design phase adhered to an iterative Agile workflow. Before database schema construction began, UI mockup wireframes analyzed user journey bottlenecks. The primary philosophy was "Minimum Time to Discovery." 
Consequently, the UI logic defaults to landing the user directly on the interactive map (`NearbyWorkersScreen`) immediately following authentication, rather than a generic text dashboard.

The overarching design system utilizes a stark layout based heavily on modern, accessible geometry. We utilized `GoogleFonts.outfit` for major display headers and `GoogleFonts.inter` for highly legible body copy. Components like buttons and input fields feature 16px border radii, mimicking premium, smooth native operating system components while retaining identity.

### 3.2 DATA FLOW DIAGRAMS (DFD)
**Level 0 DFD (System Context):**
In the Context process, the overarching central node is `NearSkill Cloud System`.
* External Entity A: **Client User** -> Sends (Search Queries, Auth Credentials, Booking Requests, Chat Payload) -> Receives (Map Coordinates, UI Updates, Worker Profiles, Socket Confirmations).
* External Entity B: **Worker Provider** -> Sends (Availability Toggle, GPS Strings, Accept/Reject Bids, ID Photos) -> Receives (Job Alerts, Messages, Payout Instructions).
* External Entity C: **Administrator** -> Sends (Ban Hooks, ID Approvals, Support Responses) -> Receives (Aggregated User Lists, Flagged System Logs).

**Level 1 DFD (Internal Modules):**
The primary system breaks down into distinct subprocesses:
1. **Module 1.0 Account Management**: Encrypts standard payloads. Validates against User relation tables.
2. **Module 2.0 Spatial Engine**: Retrieves latitude/longitude. Queries `worker_profiles` where `availability_status = true`. Calculates relative bounds using `flutter_map` viewport vectors.
3. **Module 3.0 Messaging Socket**: Routes a message payload through the `chat_messages` schema. Triggers the PostgreSQL Real-time engine. Pushes WebSocket frame updates to listening clients scoped exclusively to the relevant `request_id`.
4. **Module 4.0 Transaction Controller**: Validates state changes on `service_requests`. Allows the `reviews` Module 5.0 to unlock once the final completion timestamp is parsed.

### 3.3 ACTIVITY DIAGRAMS (PROCESS WORKFLOWS)
**User Node End-to-End Activity Flow:**
1. Execute binary initialization. Check SharedPreferences for session UUID.
2. If Null, enter Auth stack. Provide email/pass. Enter system.
3. SDK requests `ACCESS_FINE_LOCATION`. User Grants.
4. UI presents OSM Tile map. System polls `getAvailableWorkers()` array.
5. User selects "Electrician" filter chip. State updates map markers.
6. User taps specific 'Electrician Marker'. Bottom sheet reveals summary.
7. User navigates to profile. Taps 'Message/Book'.
8. Enters chat interface -> Agrees on flat rate of $50 -> Taps 'Book Now'.
9. Wait state triggered -> Polling for worker acceptance.
10. Worker Accepts. State is 'Confirmed'. Physical job occurs.
11. Worker marks 'Completed'.
12. User Prompted to leave Review -> Enters 4 Stars and context string -> Finishes lifecycle.

**Worker Node Activity Flow:**
1. Authenticate -> Reroute to `WorkerDashboardScreen`.
2. Toggle "Online" Switch. Hardware GPS begins emitting vectors to DB.
3. Local device listener catches `INSERT` trigger on `service_requests` table pointing to their ID.
4. Notification presented. Opens Inbox -> Views client logic.
5. Agrees to terms -> Updates `service_requests` status to 'Confirmed'.
6. Travels to client GPS parameters -> Resolves issue -> Clicks Complete Button.

### 3.4 USE CASE UML DIAGRAM DESCRIPTIONS
The Unified Modeling Language (UML) Use Case diagram isolates system boundaries.
* **Core Subsystems**: Authentication, Discovery, Transaction, Communication, Administration.
* **Use Case: Search Local Workers**: Actor User initiates. `<<includes>>` Use Case: Fetch GPS Hardware. 
* **Use Case: Upload Identification**: Actor Worker initiates. `<<extends>>` Use Case: View Profile. Utilizes Supabase Storage Bucket module.
* **Use Case: Issue Platform Ban**: Actor Admin initiates. Manipulates core `users` schema, cascading `<<includes>>` the disruption of all active Worker Subsystem tokens rendering the bad actor offline immediately.

### 3.5 DATABASE DESIGN & RELATIONAL INTEGRITY
The backbone of NearSkill is a rigorous PostgreSQL relational structure. We explicitly disabled Supabase's default Row Level Security (RLS) interface to handle a heavily customized RPC framework (bypassing reliance on GoTrue JWT tokens for complex dual-table insertions).

**Core Schema Entities & Constraints:**
* `users`: Primary identity hub. Requires unique `email`, stores `user_id` as `.v4 UUID`. Defines standard `role` enum context (user, admin).
* `admins`: Security table linking `user_id` to an `admin_id` to provide explicit dashboard entry parameters.
* `worker_profiles`: Critical child table. Relies on `ON DELETE CASCADE` constraint spanning from `users`. If a user is purged, their worker shadow profile disappears flawlessly. Tracks `experience_years`, `hourly_rate`, `availability_status`, `current_latitude (FLOAT)`, `current_longitude (FLOAT)`.
* `skills` & `worker_skills`: A normalized Many-to-Many bridge methodology. Allows the application to generate infinite dynamic skill string lists without hardcoding databases.
* `service_requests`: The transactional heartbeat. Tracks `user_id`, `worker_id`, `status TEXT`, `agreed_price NUMERIC`. 
* `chat_messages`: Inherits from `service_requests`. `request_id` acts as the channel identifier. Tracks `message_type` (text vs image).
* `reviews`: Strictly enforces business logic by linking explicitly to `service_requests(request_id) UNIQUE` ensuring a transaction can only be reviewed exactly one time.

---

## 7. CHAPTER 4: IMPLEMENTATION METHODOLOGIES

### 4.1 System Clean Architecture implementation
The mobile application's source code inside the `lib/` directory is strictly organized using a Feature-Based folder packaging matrix adhering to principles of Clean Architecture. This prevents a monolithic codebase.
* `lib/core/`: Application-wide configurations, immutable theming constants (`app_colors.dart`, `app_strings.dart`), Supabase deterministic initializers, and pure generic reusable reusable UI widgets (buttons, text fields).
* `lib/features/`: Contains mutually exclusive domain packages (`auth`, `booking`, `chat`, `dashboard`, `discovery`, `profile`, `admin`).
Within each feature directory, it fractures further heavily referencing the `Presentation -> Domain -> Data` layered approach:
* **Presentation**: Only contains UI Widgets and Screen classes parsing Riverpod state.
* **Domain**: Contains the purely Dart object classes (`UserModel`, `MessageModel`) utilizing strictly typed variables and JSON factory constructors.
* **Data**: Contains `AuthRepository`, `ChatRepository`, performing all asynchronous asynchronous network I/O calls to Supabase securely.

### 4.2 State Management Mastery with Riverpod
Traditional `setState` commands cause inefficient widget tree rebuilds in Flutter when dealing with massive datasets (like map pins). Instead, `flutter_riverpod` handles all reactive state dependencies. 
StateNotifiers and StreamProviders act as reactive caching layers wrapped around asynchronous network operations. For example, the `messagesProvider` located in `chat_repository.dart` listens securely to the `chat_messages` table via a `.stream()` method relying on a Supabase real-time socket. As new records enter the PostgreSQL table, Riverpod automatically ingests the JSON payload, deserializes it into a `MessageModel`, and injects it into the active Chat UI listview, updating the visual layer instantly without requiring manual polling logic.

### 4.3 Direct Supabase Integration & RPC Usage
PostgreSQL handles the core heavy lifting. All intermediate legacy REST API server infrastructure is eliminated. Instead, the compiled Flutter binary communicates directly with the Supabase connection pool instances utilizing encrypted websocket connections and HTTPS payloads over the Supabase Dart Client SDK.

Key Backend Algorithmic Implementations:
- **Transactional Custom Auth via RPC**: Standard auth is explicitly bypassed. An RPC mapping function named `register_custom_user` was instantiated via raw SQL in the cloud. When a Worker registers, the database executes an atomic transaction that inserts the credentials into `users`, captures the generated PK `UUID`, and instantly triggers an `INSERT` into the `worker_profiles` schema, linking them flawlessly without network separation risk.
- **Geocoding & Client-Side Mathematics**: Heavy geospatial calculation shifts to the client boundary to save cloud compute parameters. `geolocator` fetches hardware vectors. Utilizing the `latlong2` package's Haversine mathematical `Distance().as(LengthUnit.Meter)` function, algorithmically comparing distance radii occurs efficiently on-device across arrays of thousands of workers returned by a low-overhead array fetch.
- **Complex Cloud Storage**: Supabase Edge Storage buckets manage Binary Large Objects (BLOBs) for profile imagery.

### 4.4 The Asynchronous Mapping Engine
The `flutter_map` library operates as the foundational canvas for discovering labor. Integrated closely with free-tier OpenStreetMap (OSM) tile servers, it constitutes the `NearbyWorkersScreen`. As the user intuitively pinches, pans, and zooms their touch screen, an asynchronous evaluation engine reviews the bounding box of the display port. It triggers highly localized repainting of custom vector `Marker` objects denoting human workers. The result is a smooth, gamified UI experience mapping reality to digital availability flawlessly.

### 4.5 User Interface Implementation & Flow
The application's interface is designed with a premium, accessible aesthetic prioritizing "glassmorphic" layers and high legibility. Below is a detailed breakdown of the implemented screens across all actor roles:

#### 1. Login and Signup Interfaces
> *[Insert Image: Login and Signup Screens here]*

**Description**: The authentication flow provides a streamlined onboarding experience. Users input their email and secure passwords. A critical toggle allows new registrations to flag themselves as "Workers," seamlessly executing dual-table account generation directly during sign-up. The UI handles error validation (e.g., weak passwords, invalid emails) via responsive inline alerts.

#### 2. User Dashboard (Discovery)
> *[Insert Image: User Dashboard / Nearby Mapping here]*

**Description**: The flagship screen for consumers. Upon granting hardware location permissions, the screen renders an interactive map via OpenStreetMap vectors. Distinct colored markers represent active localized workers. Users can filter this spatial grid using dynamic skill chips (e.g., "Plumbing") positioned horizontally at the top, immediately repainting matching map points.

#### 3. Worker Dashboard
> *[Insert Image: Worker Dashboard here]*

**Description**: The primary hub for service providers. It prominently features an overarching "Go Online / Offline" toggle governing their geospatial visibility on the platform. The dashboard summarizes incoming workflow, aggregating total career earnings, request volumes, and their active rolling star rating fetched from community reviews.

#### 4. User Profile
> *[Insert Image: User Profile Screen here]*

**Description**: A personal management interface allowing standard clients to update their display identifiers and profile photos (uploaded seamlessly into Supabase Cloud Buckets). It houses core application settings and serves as a gateway to check pending localized support tickets logged against the administration.

#### 5. Worker Profile
> *[Insert Image: Worker Profile / Public View here]*

**Description**: The public-facing digital storefront for workers displaying their hourly rates, accumulated experience levels, and a comprehensive list of successfully matched skills. Crucially, it provides an interface to submit physical ID cards for platform verification. Consumers viewing this profile are presented with a persistent "Message" and "Book Now" floating action array.

#### 6. Booking Management Section (User & Worker)
> *[Insert Image: Booking Listing and Status Screens here]*

**Description**: A unified transactional ledger for both parties. It organizes service requests logically based on sequential temporal states (`Pending` -> `Confirmed` -> `Completed` -> `Cancelled`). Color-coated status tags allow instant parsing of a gig's lifecycle constraint, enabling workers to accept incoming bids and users to track execution.

#### 7. User & Worker Message Section (Real-Time Chat)
> *[Insert Image: Chat Interface and Media Bubbles here]*

**Description**: The internal communication channel substituting risky SMS logic. It leverages WebSocket streams to achieve <200ms latency on message delivery. The UI is designed similarly to premium messaging applications, featuring distinct sender/receiver chat bubbles and an integrated photo tool allowing users to snap photos of broken appliances to negotiate accurate physical pricing.

#### 8. User Review System
> *[Insert Image: Post-Job Review and Rating Modal here]*

**Description**: Unlocked exclusively upon a booking reaching the 'Completed' state. Users are prompted to assign a 1-5 star metric alongside qualitative textual feedback. This transaction is immutable and explicitly tied to a unique `request_id`, fundamentally preventing fraudulent reputation farming or bots from interacting with the rating algorithm.

#### 9. Admin Panel
> *[Insert Image: Administrative Desktop/Mobile Dashboard here]*

**Description**: An elevated operational system hidden from standard users. Accessible only to UUIDs flagged as Admins, it provides an expansive, data-dense grid view mapping total ecosystem health. Admins utilize this screen to execute heavy database interventions, including banning malicious entities from the platform and explicitly granting "Verification Approvals" by checking worker-submitted government artifacts.

---

## 8. CHAPTER 5: RESULTS AND DISCUSSIONS

The physical development and conceptual realization of NearSkill successfully achieved all foundational objectives proposed in the initial scoping documentation against various test metrics.

1. **Ultra Low Latency Matchmaking**: The custom mapping integration ensures workers appear seemingly instantaneously to nearby users when toggling their online presence. Bounding the database queries and migrating heavy Haversine radius calculations locally proved to be highly efficient in minimizing unnecessary row rendering bottlenecks overhead.
2. **Ironclad Real-Time Messaging**: The Supabase Elixir real-time engine supported uninterrupted communication lines. Network simulation testing (injecting 3G dropouts and high-latency proxies) revealed that the architecture inherently buffers failing chat states until a socket reconnect is fully established, preventing critical data loss during job negotiations.
3. **Pristine Data Integrity Maintenance**: The strategic leveraging of constrained PostgreSQL tables, aggressively coupled with cascading deletes (`ON DELETE CASCADE`), successfully maintained pure database hygiene. During a mock scenario where an Admin panel executes a `DELETE FROM users` targeting a fraudulent entity, the database automatically pruned all corresponding profile associations, pending active bookings, unread messages, and open support tickets. The result leaves no orphaned arrays and zero DB bloat.
4. **Adaptive, Fault-Tolerant UI**: Utilizing Riverpod extensively allowed the UI to respond fluidly to remote mutations. During alpha testing, if a worker toggled their status on device A, device B (viewing the map) instantly saw the pin disappear due to Riverpod cascading a stream update across the UI layer boundaries seamlessly.

**Observations and Challenges:**
Challenges encountered centered primarily on handling the severely varying precision matrices of GPS hardware integrated across vastly different mobile OEM devices (e.g., modern flagship vs entry-level legacy Android tablets). This was mitigated through complex software-level parameter caching and implementing location debouncing logic localized in the `LocationUtils` framework. Additionally, migrating off mock application data to a live relational PostgreSQL environment necessitated careful structural analysis, especially regarding enforcing strictly typed variables (`UUID` validation, explicit `TIMESTAMPTZ` casting bridging between Cloud instances and local Dart `DateTime` parsing).

---

## 9. CHAPTER 6: CONCLUSION

NearSkill stands as a highly polished, robust architectural blueprint resolving localized labor discovery inefficiencies. By masterfully utilizing cutting-edge synchronous mobile development paradigms (Flutter logic + Riverpod reactivism) tightly coupled with an infinitely scalable open-source database BaaS (Supabase), the technical execution eliminates the traditional massive bottlenecks and heavy financial overhead associated with monolithic backend web-server maintenance.

The application platform critically succeeds in empowering disorganized gig workers by granting them an accessible digital storefront deeply characterized by extreme proximity and heavily transparent, un-gameable community reviews. It fundamentally democratizes local service provisioning while concurrently equipping system administrators with comprehensive oversight tools natively integrated into the schema structure.

**Prospects for Future Enhancement:**
* **Escrow Financial Integration**: Bridging a global payment gateway like Stripe API to handle in-app escrow-based holding service transactions, resolving physical payment friction entirely.
* **Service-Level Background Tracking**: Implement native platform channels (Swift/Kotlin background workers) so that a worker's GPS is silently tracked without requiring the Flutter application layer to remain awake on screen.
* **AI Implementation**: Using small, localized machine learning algorithms analyzing natural language searches to automatically optimize worker skill tagging models based on aggregate community historical trends.
* **Dark Mode Capabilities**: Implementing full theme switching by extrapolating the `AppColors` data maps.

---

## 10. BIBLIOGRAPHY

1. **Flutter Developers Documentation**: "Building cross-platform apps with Flutter architecture constructs", Google Developer Resources. Available at: https://flutter.dev/docs
2. **Supabase Documentation**: "Supabase - Open Source Firebase PostgreSQL Alternative architecture modeling", Official Documentation. Available at: https://supabase.com/docs
3. **PostgreSQL Global Development Group**: "PostgreSQL 15.0 Relational Documentation Constraints and RPC Logic". Available at: https://www.postgresql.org/docs/
4. **Riverpod Documentation Overview**: "A Reactive Caching and Data-binding Framework for Dart", Remi Rousselet. Available at: https://riverpod.dev/
5. **OpenStreetMap API Foundation**: "OpenStreetMap Tile Servers mapping matrices and Usage Policy". Available at: https://wiki.openstreetmap.org/
6. Sommerville, I. (2015). *Software Engineering* (10th ed.). Pearson. (Academic reference methodology for generic System Architecture and comprehensive SRS construction).
7. Date, C. J. (2003). *An Introduction to Database Systems* (8th ed.). Addison-Wesley. (Architectural principles underlying the Relational Database schemas, constraints, and Normal Forms implemented herein).
