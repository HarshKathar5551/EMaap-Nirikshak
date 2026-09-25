# E-Metrology Verify — SIH Problem Statement 26036
## Online Verification System for Weighing and Measuring Instruments
**Ministry of Consumer Affairs, Food & Public Distribution | Legal Metrology Division**

---

### 1. Executive Summary & Problem Statement
Under the **Legal Metrology Act, 2009**, every commercial weighing and measuring instrument (retail scales, weighbridges, fuel dispensers, automated packers, storage tanks) must undergo periodic mandatory verification and stamping by authorized Legal Metrology Officers (LMO) or Government Approved Test Centres (GATC).

#### Current Challenges:
- **Paper-based and fragmented records**: Lack of real-time visibility into expired or unverified instruments.
- **Physical tampering**: High prevalence of counterfeit verification paper seals and fraudulent certificates.
- **Disconnected field inspections**: Field officers in rural beats face zero network connectivity.
- **No public trust mechanism**: Consumers have no instant way to verify whether a vendor's scale is legally stamped and accurate.

---

### 2. The Solution: Digital Metrology Platform
This platform manages the complete lifecycle of weighing and measuring instruments from registration to disposal:

```text
REGISTER INSTRUMENT
       ↓
VALIDATE SPECIFICATIONS & INVOICES
       ↓
APPLY FOR VERIFICATION (Initial / Periodic)
       ↓
ADMIN ASSIGNMENT (LMO / GATC)
       ↓
SCHEDULE INSPECTION & DOWNLOAD PACK
       ↓
FIELD INSPECTION (Offline-First + GPS + Photos)
       ↓
PASS / FAIL / REVIEW & SEALING
       ↓
DIGITAL CERTIFICATE GENERATION (SHA-256)
       ↓
PUBLIC QR CODE ATTACHMENT
       ↓
MONITOR EXPIRY & RISK-BASED INSPECTIONS
       ↓
PERIODIC RE-VERIFICATION / CITIZEN COMPLAINT LOOP
```

---

### 3. Architecture & Clean Code Structure
The application follows a **feature-first, clean repository architecture**:

```text
lib/
  core/
    constants/       # App constants, credentials, and government color palette
    theme/           # Material 3 theme tailored for Govt enterprise portals
    routing/         # GoRouter with role-based navigation guards
    network/         # Dependency injection providers (Riverpod)
    errors/          # Failure & exception hierarchies
    utils/           # Date formatters, expiry analyzers, crypto helpers
    widgets/         # Reusable Govt App Header, Status Badges, Cards, Offline Banners
  features/
    auth/            # Authentication, Demo role selector, Session state
    dashboard/       # Role-specific dashboards (Owner, Officer, GATC, Admin, Public)
    instruments/     # Digital Instrument Passport & Registration (Phase 2)
    applications/    # Verification Applications management
    inspections/     # Field checklist, measurements, and evidence
    certificates/    # Digital Certificate & PDF generation
    qr_verification/ # Scanner & Public certificate trust verification
    complaints/      # Consumer reporting loop
    risk/            # Transparent rule-based risk prioritization
    audit/           # Tamper-evident departmental audit log
  models/            # Strongly-typed domain models (User, Instrument, Certificate, etc.)
  repositories/      # Abstract repository interfaces & implementations
  services/          # MockApiService (with latency, CRUD, and offline simulation)
  main.dart          # Entry point with ProviderScope and MaterialApp.router
```

---

### 4. Role-Based Access & Demo Credentials

| Role | Email | Password | Primary Capabilities |
| :--- | :--- | :--- | :--- |
| **Instrument Owner** | `owner@test.com` | `123456` | Register instruments, apply for verification, track passport, view certificates |
| **Legal Metrology Officer (LMO)** | `officer@test.com` | `123456` | Assigned beat, download offline pack, GPS check, checklist, measurements, evidence |
| **GATC Officer** | `gatc@test.com` | `123456` | Laboratory calibrations, test measures, volumetric standards, certificates |
| **Administrator** | `admin@test.com` | `123456` | Officer assignment, statewide analytics, complaints review, risk engine, audit trail |
| **Public Consumer** | *No Login* | *N/A* | Scan QR, verify authenticity, inspect SHA-256 seal, report measurement issues |

---

### 5. Differentiators & Technical Innovations

1. **Digital Instrument Passport (DIP)**: Permanent digital identity (`LM-IN-MH-PUN-000101`) capturing verification history, calibration readings, and certificates.
2. **Offline-First Field Inspection**: Officers download an encrypted local Inspection Pack before field work. Full inspections function seamlessly with no cellular coverage.
3. **GPS Proximity Matching**: Enforces field integrity by comparing actual inspection GPS with registered business location.
4. **Photo Evidence Chain**: Captures timestamped photos of the scale, serial number plate, and lead wire seal.
5. **Cryptographic Certificate Integrity**: Each certificate generates a SHA-256 fingerprint hash resistant to tampering.
6. **Instant Public QR Verification**: Transparent citizen verification without requiring accounts or logins.
7. **Transparent Risk Engine**: Prioritizes inspections based on overdue days, failure history, and consumer complaints.
8. **Government Audit Trail**: Every status transition and inspection is permanently recorded.

---

### 6. Verification & Build Commands Executed
- `flutter pub get`: Resolved and installed all dependencies.
- `flutter analyze`: Passed with 0 issues.
- `flutter test`: 7/7 tests passed.
- `flutter build apk --debug`: Successfully generated `build/app/outputs/flutter-apk/app-debug.apk`.
