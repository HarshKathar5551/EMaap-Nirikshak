# PROJECT_STATUS.md
# SIH 26036 - Legal Metrology Verification and Certification Platform

Updated: 2026-09-25

## Architecture

- Framework: Flutter 3.38.7 / Dart 3.10.7
- State Management: Riverpod (flutter_riverpod ^2.6.1)
- Routing: GoRouter ^14.8.1
- Storage: shared_preferences (session persistence)
- QR: qr_flutter ^4.1.0
- Location: geolocator ^14.0.3
- Crypto: crypto ^3.0.6 (SHA-256)
- UUID: uuid ^4.5.1

## Test Credentials

Owner (12 instruments): owner@test.com / 123456
Owner (0 instruments):  newowner@test.com / 123456
Officer:                officer@test.com / 123456
GATC:                   gatc@test.com / 123456
Admin:                  admin@test.com / 123456

## COMPLETED FEATURES

- Flutter project setup with feature-first architecture
- Authentication (login, session persistence, remember me, logout)
- Riverpod state management + GoRouter navigation
- Role-based routing guards
- UserModel, InstrumentModel, ApplicationModel, InspectionModel, CertificateModel
- MockApiService with in-memory data + ownerId filter
- Owner dashboard (welcome, stats, instrument list, empty state)
- GPS location capture in add instrument form
- InstrumentsController + ApplicationsController (StateNotifier)
- Apply verification dialog with automatic officer assignment
- Officer dashboard (assigned inspections list)
- Inspection detail screen (checklist, measurements, GPS compare, pass/fail)
- Certificate view screen (QR code display via qr_flutter)
- Public verification screen (QR/code lookup)
- Admin dashboard (stats, applications, audit trail)
- GATC dashboard (basic)
- Status badges, offline banner, SHA-256 integrity seal
- flutter analyze: 0 issues / flutter test: 8/8 pass

## CRITICAL BUGS TO FIX

1. Mandatory location NOT enforced - can submit without GPS capture
2. No mandatory photos - no camera/gallery UI at all
3. Admin dashboard hardcodes ?? 12 fallback - always shows 12 instruments
4. Officer sees 6 seeded inspections even on fresh state (all assigned to usr-officer-01)
5. Android back navigation exits app from dashboard screens
6. No unsaved form warning when pressing back
7. Possible RenderFlex overflows on small screens

## REMAINING FEATURES

- Mandatory location enforcement before instrument submission
- Mandatory photos (instrument + serial number) with camera/gallery picker
- Photo preview/retake UI
- Android back navigation fix
- Unsaved form changes warning dialog
- Search/filter/sort on instrument lists
- Instrument detail page (full details, photo gallery, timeline)
- Verification lifecycle timeline widget
- Notification system (in-app)
- Pull to refresh
- E-MAAP branding update
- Public QR camera scanner
- Data persistence after app restart
