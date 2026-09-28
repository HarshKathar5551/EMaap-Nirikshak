import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/utils/qr_decoder.dart';
import '../../../../models/instrument_model.dart';
import '../../../../services/mock_data.dart';

class PublicQrScannerDialog extends ConsumerStatefulWidget {
  final bool autoStartCamera;
  const PublicQrScannerDialog({super.key, this.autoStartCamera = true});

  static Future<String?> show(BuildContext context, {bool autoStartCamera = true}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PublicQrScannerDialog(autoStartCamera: autoStartCamera),
    );
  }

  @override
  ConsumerState<PublicQrScannerDialog> createState() => _PublicQrScannerDialogState();
}

class _PublicQrScannerDialogState extends ConsumerState<PublicQrScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _laserAnimation;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  final _manualInputController = TextEditingController();
  List<InstrumentModel> _registeredInstruments = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadRegisteredInstruments();

    if (widget.autoStartCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _captureWithCamera();
      });
    }
  }

  Future<void> _loadRegisteredInstruments() async {
    try {
      final list = await ref.read(instrumentRepositoryProvider).getInstruments();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _registeredInstruments = list;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _registeredInstruments = MockData.instruments;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onCodeDetected(String code) {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop(code);
      }
    });
  }

  Future<void> _captureWithCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (photo != null && mounted) {
        setState(() => _isProcessing = true);

        final bytes = await photo.readAsBytes();
        final decoded = QrDecoder.decodeFromBytes(bytes);

        if (decoded != null && decoded.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success,
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('QR Detected: $decoded')),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          _onCodeDetected(decoded);
        } else {
          if (mounted) {
            setState(() => _isProcessing = false);
            _showQrNotFoundDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Camera could not be launched: $e\nTip: You can pick an image or select equipment below.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() => _isProcessing = true);

        final bytes = await image.readAsBytes();
        final decoded = QrDecoder.decodeFromBytes(bytes);

        if (decoded != null && decoded.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success,
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('QR Detected: $decoded')),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          _onCodeDetected(decoded);
        } else {
          if (mounted) {
            setState(() => _isProcessing = false);
            _showQrNotFoundDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery access error: $e')),
        );
      }
    }
  }

  void _showQrNotFoundDialog() {
    final instruments = _registeredInstruments.isNotEmpty
        ? _registeredInstruments
        : MockData.instruments;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppColors.secondary, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'QR Not Recognized',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No barcode detected in the captured photo. For best results, place the camera 10–15 cm from the QR plaque.\n\nYou can also select the equipment directly from the registered list:',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: instruments.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 8),
                itemBuilder: (context, i) {
                  final inst = instruments[i];
                  final code = (inst.qrVerificationCode != null && inst.qrVerificationCode!.isNotEmpty)
                      ? inst.qrVerificationCode!
                      : 'VERIFY-LM-${inst.instrumentId.replaceAll('LM-IN-', '').replaceAll('-', '')}';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.scale, color: AppColors.primaryLight, size: 20),
                    title: Text(
                      '${inst.type} (${inst.instrumentId})',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Token: $code',
                      style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      _onCodeDetected(code);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _captureWithCamera();
            },
            child: const Text('RETRY CAMERA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instruments = _registeredInstruments.isNotEmpty
        ? _registeredInstruments
        : MockData.instruments;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark slate
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal Metrology QR Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Align sticker QR code within viewfinder',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.amber : Colors.white60,
                    ),
                    tooltip: 'Toggle Flashlight',
                    onPressed: () {
                      setState(() => _isTorchOn = !_isTorchOn);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Camera Viewfinder Simulation
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Viewfinder Area
                      AspectRatio(
                        aspectRatio: 1.05,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isProcessing ? AppColors.success : Colors.white24,
                              width: _isProcessing ? 3 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.08,
                                  child: GridPaper(
                                    color: Colors.white,
                                    divisions: 2,
                                    subdivisions: 1,
                                  ),
                                ),
                              ),

                              // Viewfinder Reticle Corners
                              Positioned(
                                top: 24,
                                left: 24,
                                child: _CornerBracket(isTop: true, isLeft: true),
                              ),
                              Positioned(
                                top: 24,
                                right: 24,
                                child: _CornerBracket(isTop: true, isLeft: false),
                              ),
                              Positioned(
                                bottom: 24,
                                left: 24,
                                child: _CornerBracket(isTop: false, isLeft: true),
                              ),
                              Positioned(
                                bottom: 24,
                                right: 24,
                                child: _CornerBracket(isTop: false, isLeft: false),
                              ),

                              // Center QR Target Icon / Status
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    size: 96,
                                    color: _isProcessing
                                        ? AppColors.success
                                        : Colors.white.withValues(alpha: 0.25),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _isProcessing
                                          ? 'DECODING VERIFICATION TOKEN...'
                                          : 'POINT AT GOVERNMENT CALIBRATION STICKER',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: _isProcessing ? AppColors.success : Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Animated Scanning Laser Line
                              if (!_isProcessing)
                                AnimatedBuilder(
                                  animation: _laserAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 30 + (220 * _laserAnimation.value),
                                      left: 28,
                                      right: 28,
                                      child: Container(
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF00FF88),
                                              Color(0xFF38BDF8),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Camera / Gallery Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text(
                                'Snap Live Photo',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              onPressed: _isProcessing ? null : _captureWithCamera,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text(
                                'Upload Sticker',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              onPressed: _isProcessing ? null : _pickFromGallery,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Manual Entry Field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualInputController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Or enter QR Token (e.g. VERIFY-LM-...)',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) _onCodeDetected(val.trim());
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final text = _manualInputController.text.trim();
                              if (text.isNotEmpty) _onCodeDetected(text);
                            },
                            child: const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick Test Equipment Chips with Actual Registered Instruments
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.touch_app, size: 14, color: AppColors.secondary),
                                SizedBox(width: 6),
                                Text(
                                  'Tap Registered Equipment to Simulate QR Scan:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...instruments.map((item) {
                                  final code = (item.qrVerificationCode != null && item.qrVerificationCode!.isNotEmpty)
                                      ? item.qrVerificationCode!
                                      : 'VERIFY-LM-${item.instrumentId.replaceAll('LM-IN-', '').replaceAll('-', '')}';

                                  return InkWell(
                                    onTap: _isProcessing
                                        ? null
                                        : () => _onCodeDetected(code),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item.type.split(" ").first} (${item.status.displayName})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            code,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                InkWell(
                                  onTap: _isProcessing
                                      ? null
                                      : () => _onCodeDetected('COUNTERFEIT-QR-INVALID'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.error.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '❌ Fake / Tampered QR',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'COUNTERFEIT-QR-INVALID',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    const thickness = 3.5;
    const color = Color(0xFF00FF88);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          isTop: isTop,
          isLeft: isLeft,
          thickness: thickness,
          color: color,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final Color color;

  _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
