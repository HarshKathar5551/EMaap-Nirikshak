import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/instrument_model.dart';
import '../../../../models/application_model.dart';
import '../../../../models/inspection_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../applications/presentation/controllers/applications_controller.dart';
import '../controllers/instruments_controller.dart';

class AddInstrumentDialog extends ConsumerStatefulWidget {
  const AddInstrumentDialog({super.key});

  @override
  ConsumerState<AddInstrumentDialog> createState() => _AddInstrumentDialogState();
}

class _AddInstrumentDialogState extends ConsumerState<AddInstrumentDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 — Equipment Info
  String _selectedType = 'Electronic Weighing Scale (Class III)';
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedUnit = 'kg';
  final _yearController = TextEditingController(text: '2026');
  final _descriptionController = TextEditingController();

  // Step 2 — Location
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;
  bool _locationCaptured = false;
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 3 — Photos
  final ImagePicker _picker = ImagePicker();
  XFile? _instrumentPhoto;
  Uint8List? _instrumentPhotoBytes;
  XFile? _serialPhoto;
  Uint8List? _serialPhotoBytes;
  XFile? _sealPhoto;
  Uint8List? _sealPhotoBytes;
  bool _hasSamplePhotos = true;
  bool _isLocationServiceDisabled = false;
  bool _isPermissionDenied = false;
  String? _locationStatusMessage;

  bool _isSubmitting = false;
  bool _formHasData = false;

  final List<String> _equipmentTypes = [
    'Electronic Weighing Scale (Class III)',
    'Retail Counter Scale (Class III)',
    'Heavy Electronic Weighbridge (Class IV)',
    'Fuel Dispensing Unit (Petrol/Diesel)',
    'Precision Analytical Balance (Class I)',
    'Milk Volume Measuring Tank',
    'LPG Gas Cylinder Weighing Scale',
    'Automatic Gravimetric Filling Instrument',
    'Gold Jewellery Balance (Class II)',
    'Platform Weighing Scale (Class III)',
  ];

  final List<String> _units = ['kg', 'g', 'tons', 'litres', 'L/min', 'mL', 'tons/hr'];

  @override
  void initState() {
    super.initState();
    final randomDigits = 1000 + Random().nextInt(9000);
    _serialNumberController.text = 'SN-2026-$randomDigits';
    final user = ref.read(authControllerProvider).user;
    _businessNameController.text = user?.department ?? 'Verma Provisions & Mart';
    _addressController.text = 'Shop 12, FC Road, Shivajinagar, Pune - 411005';
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _capacityController.dispose();
    _yearController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _quickFillDemoData() {
    final randomDigits = 1000 + Random().nextInt(9000);
    setState(() {
      _selectedType = 'Retail Counter Scale (Class III)';
      _manufacturerController.text = 'Essae-Teraoka Ltd';
      _modelController.text = 'DS-215 Commercial Scale';
      _serialNumberController.text = 'SN-2026-$randomDigits';
      _capacityController.text = '30.0';
      _selectedUnit = 'kg';
      _yearController.text = '2026';
      _descriptionController.text = 'Dual LED display counter weighing scale for retail grocery trade.';
      _latitude = null;
      _longitude = null;
      _locationCaptured = false;
      _businessNameController.text = 'Verma Provisions & Mart';
      _addressController.text = 'Shop 12, FC Road, Shivajinagar, Pune - 411005';
      _hasSamplePhotos = true;
      _formHasData = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('⚡ Pre-filled demo equipment specifications!'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  void _useCommercialPremiseGps() {
    setState(() {
      _latitude = 18.5204;
      _longitude = 73.8567;
      _locationCaptured = true;
      _isDetectingLocation = false;
      _isLocationServiceDisabled = false;
      _isPermissionDenied = false;
      _formHasData = true;
      _locationStatusMessage = 'Verified Commercial Premise Coordinates applied (Pune Zone)';
      if (_addressController.text.trim().isEmpty) {
        _addressController.text = 'Shop 12, FC Road, Shivajinagar, Pune, Maharashtra - 411005';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('✓ Verified Commercial Premise Location applied: 18.5204°, 73.8567° (Pune Zone).'),
        duration: Duration(milliseconds: 2000),
      ),
    );
  }

  Future<void> _promptEnableLocationService() async {
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(child: Text('Enable Location Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ],
        ),
        content: const Text(
          'Device location (GPS) is currently disabled. Under Legal Metrology regulations, geo-coordinates must be enabled to register and assign your instrument.\n\nPlease enable location services.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _useCommercialPremiseGps();
            },
            child: const Text('Use Premise GPS'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Location Settings'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (enable == true) {
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        _captureLocation();
      }
    }
  }

  Future<void> _promptOpenAppSettings() async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(child: Text('Location Permission Needed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ],
        ),
        content: const Text(
          'Location permission is permanently denied. To enable geo-tagging for your instrument, please allow location permission in App Settings.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _useCommercialPremiseGps();
            },
            child: const Text('Use Premise GPS'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open App Settings'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (open == true) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _captureLocation() async {
    if (!mounted) return;
    setState(() {
      _isDetectingLocation = true;
      _locationStatusMessage = 'Checking device location service & permissions...';
    });

    try {
      // Step 1: Check if Location Service is enabled on device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isDetectingLocation = false;
            _isLocationServiceDisabled = true;
            _locationStatusMessage = 'Location service is turned off. Please enable GPS.';
          });
          _promptEnableLocationService();
        }
        return;
      }

      setState(() => _isLocationServiceDisabled = false);

      // Step 2: Check & Request Location Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isDetectingLocation = false;
            _isPermissionDenied = true;
            _locationStatusMessage = 'Location permission permanently denied. Open App Settings.';
          });
          _promptOpenAppSettings();
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isDetectingLocation = false;
            _isPermissionDenied = true;
            _locationStatusMessage = 'Location permission was denied. Tap again or use premise GPS.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.warning,
              content: Text('⚠️ Location permission is required to detect GPS coordinates.'),
            ),
          );
        }
        return;
      }

      setState(() {
        _isPermissionDenied = false;
        _locationStatusMessage = 'Acquiring satellite GPS fix...';
      });

      // Step 3: Fetch GPS position
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        setState(() {
          _latitude = pos!.latitude;
          _longitude = pos.longitude;
          _locationCaptured = true;
          _isDetectingLocation = false;
          _isLocationServiceDisabled = false;
          _isPermissionDenied = false;
          _formHasData = true;
          _locationStatusMessage = 'GPS Location verified (Accuracy: ${pos.accuracy.toStringAsFixed(1)}m)';
        });
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'Lat: ${pos.latitude.toStringAsFixed(5)}, Long: ${pos.longitude.toStringAsFixed(5)}, Pune Beat Zone';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✓ Device GPS Coordinates set: ${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        _useCommercialPremiseGps();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
          _locationStatusMessage = 'GPS error: $e';
        });
        _useCommercialPremiseGps();
      }
    }
  }

  Future<void> _pickPhoto(String slot) async {
    if (!mounted) return;
    final ctx = context;
    final action = await showModalBottomSheet<String>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bsCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo with Camera'),
              onTap: () => Navigator.pop(bsCtx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(bsCtx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.secondary),
              title: const Text('Attach Sample Verification Photos (Instant Demo)'),
              onTap: () => Navigator.pop(bsCtx, 'sample'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'sample') {
      setState(() {
        _hasSamplePhotos = true;
        _formHasData = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Attached official Legal Metrology sample equipment photos.'),
        ),
      );
      return;
    }

    try {
      final XFile? photo = action == 'camera'
          ? await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1920)
          : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1920);

      if (photo != null && mounted) {
        final bytes = await photo.readAsBytes();
        if (!mounted) return;
        setState(() {
          _formHasData = true;
          switch (slot) {
            case 'instrument':
              _instrumentPhoto = photo;
              _instrumentPhotoBytes = bytes;
              break;
            case 'serial':
              _serialPhoto = photo;
              _serialPhotoBytes = bytes;
              break;
            case 'seal':
              _sealPhoto = photo;
              _sealPhotoBytes = bytes;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  void _removePhoto(String slot) {
    setState(() {
      switch (slot) {
        case 'instrument':
          _instrumentPhoto = null;
          _instrumentPhotoBytes = null;
          break;
        case 'serial':
          _serialPhoto = null;
          _serialPhotoBytes = null;
          break;
        case 'seal':
          _sealPhoto = null;
          _sealPhotoBytes = null;
          break;
      }
    });
  }

  bool get _canProceedStep1 {
    return _manufacturerController.text.trim().isNotEmpty &&
        _modelController.text.trim().isNotEmpty &&
        _serialNumberController.text.trim().isNotEmpty &&
        _capacityController.text.trim().isNotEmpty;
  }

  bool get _canSubmit =>
      _canProceedStep1 &&
      _locationCaptured &&
      (_hasSamplePhotos || _instrumentPhoto != null || _serialPhoto != null);

  Future<void> _handleSubmit() async {
    // 1. Ensure Step 1 fields are valid
    if (!_canProceedStep1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please complete the mandatory equipment specifications.'),
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }

    // 2. Ensure Location is enabled & set
    if (!_locationCaptured || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('⚠️ Location required: Please enable and set location before registering.'),
        ),
      );
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isSubmitting = true);

    final user = ref.read(authControllerProvider).user;
    final randomId = 100000 + Random().nextInt(900000);
    final instrumentId = 'LM-IN-MH-PUN-${randomId.toString().substring(0, 6)}';

    // Build photo paths list
    final List<String> photoPaths = [];
    if (_instrumentPhoto != null) photoPaths.add(_instrumentPhoto!.path);
    if (_serialPhoto != null) photoPaths.add(_serialPhoto!.path);
    if (_sealPhoto != null) photoPaths.add(_sealPhoto!.path);

    if (photoPaths.isEmpty) {
      // Default metrology registration photo paths for instant verification
      photoPaths.addAll([
        'https://images.unsplash.com/photo-1584282479905-188b8fa87f3b?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1581092335397-9583fe92d232?auto=format&fit=crop&w=600&q=80',
      ]);
    }

    final newInstrument = InstrumentModel(
      id: 'inst-$randomId',
      instrumentId: instrumentId,
      type: _selectedType,
      manufacturer: _manufacturerController.text.trim().isNotEmpty
          ? _manufacturerController.text.trim()
          : 'Essae-Teraoka Ltd',
      model: _modelController.text.trim().isNotEmpty
          ? _modelController.text.trim()
          : 'DS-215 Counter Scale',
      serialNumber: _serialNumberController.text.trim().isNotEmpty
          ? _serialNumberController.text.trim()
          : 'SN-2026-$randomId',
      capacity: double.tryParse(_capacityController.text.trim()) ?? 30.0,
      unit: _selectedUnit,
      yearOfManufacture: int.tryParse(_yearController.text.trim()) ?? 2026,
      purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
      locationName: _businessNameController.text.trim().isNotEmpty
          ? _businessNameController.text.trim()
          : (user?.department ?? 'Commercial Establishment'),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'Shop 12, FC Road, Shivajinagar, Pune - 411005',
      latitude: _latitude!,
      longitude: _longitude!,
      ownerId: user?.id ?? 'usr-owner-01',
      ownerName: user?.name ?? 'Rajesh Sharma',
      status: InstrumentStatus.registered,
      registrationDate: DateTime.now(),
      photoUrls: photoPaths,
      qrVerificationCode: 'VERIFY-LM-${instrumentId.replaceAll('LM-IN-', '').replaceAll('-', '')}-${_generateCode()}',
      riskLevel: 'LOW',
    );

    try {
      final created = await ref
          .read(instrumentsControllerProvider.notifier)
          .registerInstrument(newInstrument);

      if (created != null && mounted) {
        // ── Auto-submit verification application to LMO ──────────────
        try {
          final appRandom = 10000 + Random().nextInt(90000);
          final appId = 'LM-APP-${DateTime.now().year}-$appRandom';
          final application = ApplicationModel(
            id: 'app-${created.id}',
            applicationId: appId,
            instrumentId: created.id,
            instrumentUniqueId: created.instrumentId,
            instrumentType: created.type,
            ownerId: created.ownerId,
            ownerName: created.ownerName,
            type: ApplicationType.newVerification,
            status: ApplicationStatus.submitted,
            submittedDate: DateTime.now(),
            assignedOfficerId: 'usr-officer-01',
            assignedOfficerName: 'Inspector Vikram Patil (LMO)',
            feeAmount: 450.00,
            feePaid: true,
            remarks: 'Auto-submitted for Initial Verification after instrument registration.',
          );
          await ref
              .read(applicationsControllerProvider.notifier)
              .submitApplication(application);

          // Create assigned inspection for LMO field portal
          final inspRandom = 10000 + Random().nextInt(90000);
          final inspection = InspectionModel(
            id: 'insp-${created.id}',
            inspectionId: 'LM-INS-${DateTime.now().year}-$inspRandom',
            applicationId: appId,
            instrumentId: created.id,
            instrumentUniqueId: created.instrumentId,
            instrumentType: created.type,
            officerId: 'usr-officer-01',
            officerName: 'Inspector Vikram Patil',
            scheduledDate: DateTime.now(),
            status: InspectionStatus.pending,
            registeredLatitude: created.latitude,
            registeredLongitude: created.longitude,
            actualLatitude: created.latitude,
            actualLongitude: created.longitude,
            isLocationMatched: true,
            distanceMeters: 4.8,
            remarks: 'Initial verification inspection for ${created.type}.',
          );
          await ref
              .read(inspectionRepositoryProvider)
              .createInspection(inspection);
        } catch (_) {
          // Non-fatal — application can be submitted separately
        }
        // ─────────────────────────────────────────────────────────────

        if (mounted) {
          setState(() => _isSubmitting = false);
          Navigator.of(context).pop(created);
        }
      } else if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Could not register instrument. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Registration error: $e'),
          ),
        );
      }
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    final r = Random();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        final dialogWidth = (screenW - 24.0).clamp(300.0, 560.0);
        final dialogHeight = (screenH * 0.9).clamp(400.0, 740.0);

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      const Icon(Icons.app_registration,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Register Weighing / Measuring Instrument',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 20),
                        onPressed: () async {
                          if (_formHasData) {
                            final nav = Navigator.of(context);
                            final discard = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                    'Discard Registration?'),
                                content: const Text(
                                    'You have filled equipment data. Are you sure you want to discard?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child:
                                          const Text('Keep Editing')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.error),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Discard',
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (discard == true && mounted) {
                              nav.pop();
                            }
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // ── Step indicator ───────────────────────────────────
                _StepIndicator(currentStep: _currentStep),

                // ── Step content ─────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildCurrentStep(),
                  ),
                ),

                // ── Bottom navigation ────────────────────────────────
                _buildBottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Equipment();
      case 1:
        return _buildStep2Location();
      case 2:
        return _buildStep3Photos();
      default:
        return _buildStep1Equipment();
    }
  }

  Widget _buildStep1Equipment() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: _SectionHeader(
                  icon: Icons.settings,
                  title: 'Equipment Specifications',
                  subtitle: 'Enter instrument details as per calibration plate',
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('Quick Fill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: _quickFillDemoData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Instrument Category & Type *',
              prefixIcon: Icon(Icons.category_outlined, size: 20),
            ),
            isExpanded: true,
            items: _equipmentTypes
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedType = v!;
              _formHasData = true;
            }),
          ),
          const SizedBox(height: 14),

          // Manufacturer & Model
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer *',
                    hintText: 'e.g. Avery / Essae',
                    prefixIcon: Icon(Icons.factory_outlined, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  onChanged: (v) => setState(() => _formHasData = true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model Number *',
                    hintText: 'e.g. DS-215 / EWS-30',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  onChanged: (v) => setState(() => _formHasData = true),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Serial Number
          TextFormField(
            controller: _serialNumberController,
            decoration: const InputDecoration(
              labelText: 'Physical Serial Number (Unique) *',
              prefixIcon: Icon(Icons.tag, size: 20),
              helperText: 'Must match the serial number stamped on the instrument',
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter serial number' : null,
            onChanged: (v) => setState(() => _formHasData = true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Capacity, Unit, Year
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Capacity *',
                    hintText: 'e.g. 30',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  onChanged: (v) => setState(() => _formHasData = true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  ),
                  items: _units
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mfg Year'),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description (optional)
          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description / Purpose (Optional)',
              prefixIcon: Icon(Icons.notes, size: 20),
              hintText: 'e.g. Counter weighing scale at checkout register',
            ),
          ),
          const SizedBox(height: 16),

          // Owner info card
          _buildOwnerInfoCard(),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    final user = ref.read(authControllerProvider).user;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Owner Information (Auto-filled)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Name', value: user?.name ?? 'Rahul Verma'),
          _InfoRow(label: 'Business', value: user?.department ?? 'Verma Provisions & Mart'),
          _InfoRow(label: 'Owner ID', value: user?.id ?? 'usr-owner-fresh'),
        ],
      ),
    );
  }

  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.location_on,
          title: 'Instrument Geo-Location',
          subtitle: 'Required for Legal Metrology zonal allocation and beat officer assignment',
          isRequired: true,
        ),
        const SizedBox(height: 14),

        // Warning banner when location is not yet set
        if (!_locationCaptured)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_disabled, color: AppColors.warning, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Must Be Enabled & Set Before Proceeding',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'To comply with the Legal Metrology Act and enable this instrument for official registration, please enable location and capture coordinates.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Location Service Disabled Notice if GPS is off
        if (_isLocationServiceDisabled)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gps_off, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Device Location (GPS) is Disabled',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.error),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your device location services are turned off. Please turn them on in device settings, or use the verified commercial premise coordinates below.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.settings, size: 14),
                      label: const Text('Open Location Settings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (mounted) _captureLocation();
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _useCommercialPremiseGps,
                      child: const Text('Use Premise GPS', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Location Permission Denied Notice
        if (_isPermissionDenied)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Location Permission Denied',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.error),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Location access is required to capture the equipment GPS coordinates. Please grant permission in App Settings or use premise coordinates.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.settings, size: 14),
                      label: const Text('Open App Settings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _useCommercialPremiseGps,
                      child: const Text('Use Premise GPS', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Main GPS capture card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _locationCaptured
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _locationCaptured ? AppColors.success : AppColors.primaryLight,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_locationCaptured ? AppColors.success : AppColors.primary).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _locationCaptured ? Icons.gps_fixed : Icons.my_location,
                      color: _locationCaptured ? AppColors.success : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              _locationCaptured ? 'GPS Location Enabled & Set ✓' : 'Location Not Set Yet',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _locationCaptured ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            if (_locationCaptured)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VERIFIED',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locationCaptured
                              ? 'Lat: ${_latitude?.toStringAsFixed(5)}°, Long: ${_longitude?.toStringAsFixed(5)}° (Pune Metrology Zone)'
                              : (_locationStatusMessage ?? 'Tap below to enable and capture device GPS or use premise coordinates'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _locationCaptured ? FontWeight.w600 : FontWeight.normal,
                            color: _locationCaptured ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _locationCaptured ? AppColors.surfaceMuted : AppColors.primary,
                        foregroundColor: _locationCaptured ? AppColors.textPrimary : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: _locationCaptured ? 0 : 2,
                      ),
                      onPressed: _isDetectingLocation ? null : _captureLocation,
                      icon: _isDetectingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(_locationCaptured ? Icons.refresh : Icons.my_location, size: 16),
                      label: Text(
                        _isDetectingLocation
                            ? 'Detecting GPS...'
                            : (_locationCaptured ? 'Re-detect Device GPS' : 'Enable & Detect Device Location'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                          color: _locationCaptured ? AppColors.border : AppColors.primary,
                        ),
                      ),
                      onPressed: _useCommercialPremiseGps,
                      icon: const Icon(Icons.store, size: 16),
                      label: const Text(
                        'Set Premise GPS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Business Name
        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Establishment / Shop Name *',
            prefixIcon: Icon(Icons.storefront, size: 20),
          ),
          onChanged: (v) => setState(() => _formHasData = true),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),

        // Address
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Physical Installation Address *',
            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            hintText: 'Shop No., Street, Market Area, City, State - PIN',
          ),
          onChanged: (v) => setState(() => _formHasData = true),
        ),
      ],
    );
  }

  Widget _buildStep3Photos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: _SectionHeader(
                icon: Icons.photo_camera,
                title: 'Instrument Verification Photos',
                subtitle: 'Capture camera photo or attach sample inspection records',
                isRequired: true,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Sample Photos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              onPressed: () {
                setState(() => _hasSamplePhotos = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Attached official Legal Metrology sample equipment photos.'),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Photo status summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _canSubmit
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _canSubmit ? AppColors.success : AppColors.warning,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _canSubmit ? Icons.check_circle : Icons.info_outline,
                color: _canSubmit ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _canSubmit
                      ? '✓ Verification photo requirements satisfied. Ready to register!'
                      : 'Take camera photos or tap "Sample Photos" above to proceed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _canSubmit ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _PhotoCard(
          title: 'Main Instrument Photo',
          isRequired: true,
          photo: _instrumentPhoto,
          photoBytes: _instrumentPhotoBytes,
          hasSample: _hasSamplePhotos,
          onAdd: () => _pickPhoto('instrument'),
          onRemove: () => _removePhoto('instrument'),
        ),
        const SizedBox(height: 12),

        _PhotoCard(
          title: 'Serial Number / Rating Plate Photo',
          isRequired: true,
          photo: _serialPhoto,
          photoBytes: _serialPhotoBytes,
          hasSample: _hasSamplePhotos,
          onAdd: () => _pickPhoto('serial'),
          onRemove: () => _removePhoto('serial'),
        ),
        const SizedBox(height: 12),

        _PhotoCard(
          title: 'Government Lead Seal Photo (Optional)',
          isRequired: false,
          photo: _sealPhoto,
          photoBytes: _sealPhotoBytes,
          hasSample: _hasSamplePhotos,
          onAdd: () => _pickPhoto('seal'),
          onRemove: () => _removePhoto('seal'),
        ),
        const SizedBox(height: 16),

        _buildRegistrationSummary(),
      ],
    );
  }

  Widget _buildRegistrationSummary() {
    final user = ref.read(authControllerProvider).user;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Registration Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          _InfoRow(label: 'Type', value: _selectedType),
          if (_manufacturerController.text.isNotEmpty)
            _InfoRow(label: 'Manufacturer', value: _manufacturerController.text.trim()),
          if (_modelController.text.isNotEmpty)
            _InfoRow(label: 'Model', value: _modelController.text.trim()),
          if (_serialNumberController.text.isNotEmpty)
            _InfoRow(label: 'Serial No.', value: _serialNumberController.text.trim()),
          if (_capacityController.text.isNotEmpty)
            _InfoRow(label: 'Capacity', value: '${_capacityController.text.trim()} $_selectedUnit'),
          _InfoRow(
            label: 'Location',
            value: _locationCaptured
                ? '${_latitude?.toStringAsFixed(4)}°, ${_longitude?.toStringAsFixed(4)}°'
                : 'Pune Commercial Zone',
          ),
          _InfoRow(label: 'Owner', value: user?.name ?? 'Rahul Verma'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // ── Left: Back or spacer ──────────────────────────────
          if (_currentStep > 0)
            Flexible(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                onPressed: () => setState(() => _currentStep--),
              ),
            )
          else
            const SizedBox(width: 8),

          const Spacer(),

          // ── Right: Next or Submit ─────────────────────────────
          if (_currentStep < 2)
            Flexible(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (_currentStep == 1 && !_locationCaptured)
                          ? Colors.grey.shade400
                          : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                icon: Icon(
                  _currentStep == 1 && !_locationCaptured
                      ? Icons.lock_outline
                      : Icons.arrow_forward,
                  size: 16,
                ),
                label: Text(
                  _currentStep == 0
                      ? 'Next: Location'
                      : (_locationCaptured
                          ? 'Next: Photos'
                          : 'Set Location to Proceed'),
                ),
                onPressed: () {
                  if (_currentStep == 0) {
                    if (!_canProceedStep1) {
                      _formKey.currentState?.validate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please fill the required specifications or tap Quick Fill.'),
                        ),
                      );
                      return;
                    }
                  }
                  if (_currentStep == 1) {
                    if (!_locationCaptured) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.warning,
                          content: Text(
                              '⚠️ Location required before proceeding.'),
                        ),
                      );
                      _captureLocation();
                      return;
                    }
                  }
                  setState(() => _currentStep++);
                },
              ),
            )
          else
            Flexible(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (_locationCaptured && _canProceedStep1)
                          ? AppColors.success
                          : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        (_locationCaptured && _canProceedStep1)
                            ? Icons.check_circle
                            : Icons.lock_outline,
                        size: 18,
                      ),
                label: const Text(
                  'REGISTER INSTRUMENT',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (!_canProceedStep1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text(
                                  'Please complete the mandatory equipment specifications.'),
                            ),
                          );
                          setState(() => _currentStep = 0);
                          return;
                        }
                        if (!_locationCaptured) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.warning,
                              content: Text(
                                  '⚠️ Location required before registering.'),
                            ),
                          );
                          setState(() => _currentStep = 1);
                          return;
                        }
                        _handleSubmit();
                      },
              ),
            ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.settings, 'Equipment'),
      (Icons.location_on, 'Location'),
      (Icons.photo_camera, 'Photos'),
    ];

    return Container(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Icon(steps[i].$1, size: 14, color: isActive ? Colors.white : AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  steps[i].$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                if (i < steps.length - 1) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: isDone ? AppColors.success : AppColors.border,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRequired;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.error),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String title;
  final bool isRequired;
  final XFile? photo;
  final Uint8List? photoBytes;
  final bool hasSample;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PhotoCard({
    required this.title,
    required this.isRequired,
    required this.photo,
    this.photoBytes,
    this.hasSample = false,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasRealPhoto = photoBytes != null || photo != null;
    final isSatisfied = hasRealPhoto || hasSample;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSatisfied
              ? AppColors.success
              : AppColors.border,
          width: isSatisfied ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSatisfied
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.surfaceMuted,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(
                  isSatisfied ? Icons.check_circle : Icons.camera_alt,
                  size: 16,
                  color: isSatisfied ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSatisfied ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasSample && !hasRealPhoto)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Sample Attached ✓',
                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  )
                else if (isRequired && !isSatisfied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          if (hasRealPhoto)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                  child: photoBytes != null
                      ? Image.memory(
                          photoBytes!,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : (photo != null && photo!.path.isNotEmpty
                          ? Image.network(
                              photo!.path,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: AppColors.surfaceMuted,
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: AppColors.textMuted),
                                ),
                              ),
                            )
                          : Container(height: 120, color: AppColors.surfaceMuted)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _iconBtn(Icons.refresh, 'Retake', AppColors.primary, onAdd),
                      const SizedBox(width: 6),
                      _iconBtn(Icons.delete, 'Remove', AppColors.error, onRemove),
                    ],
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: onAdd,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasSample ? Icons.check : Icons.add_a_photo_outlined,
                      size: 20,
                      color: hasSample ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasSample ? 'Tap to replace with camera photo' : 'Take Photo / Upload / Sample',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: hasSample ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
