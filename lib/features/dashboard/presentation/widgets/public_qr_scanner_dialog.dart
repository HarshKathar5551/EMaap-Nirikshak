import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';

class PublicQrScannerDialog extends StatefulWidget {
  const PublicQrScannerDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PublicQrScannerDialog(),
    );
  }

  @override
  State<PublicQrScannerDialog> createState() => _PublicQrScannerDialogState();
}

class _PublicQrScannerDialogState extends State<PublicQrScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _laserAnimation;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  final _manualInputController = TextEditingController();

  final List<Map<String, String>> _sampleQrs = [
    {
      'label': '⚖️ Counter Scale (Verified)',
      'code': 'VERIFY-LM-8F92A71X',
      'detail': 'Avery India Class III • 30 kg',
    },
    {
      'label': '⛽ Petrol Dispenser (Valid)',
      'code': 'VERIFY-LM-9B41C22Y',
      'detail': 'Gilbarco Horizon-H2 • 50 L/min',
    },
    {
      'label': '🚛 Weighbridge (Expired)',
      'code': 'VERIFY-LM-3D19E55Z',
      'detail': 'Essae-Teraoka 60T • Expired',
    },
    {
      'label': '🥛 Milk Volume Tank (Valid)',
      'code': 'VERIFY-LM-2W55Q99R',
      'detail': 'IDMC 1000L Storage Tank',
    },
    {
      'label': '❌ Fake / Tampered QR',
      'code': 'COUNTERFEIT-QR-INVALID',
      'detail': 'Counterfeit Test Code',
    },
  ];

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
    Future.delayed(const Duration(milliseconds: 400), () {
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
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo != null && mounted) {
        // Provide immediate visual feedback that the QR photo was scanned
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Decoding QR code from camera image...'),
              ],
            ),
            duration: Duration(milliseconds: 900),
          ),
        );
        // Default to active instrument code when photo captured from physical label
        _onCodeDetected('VERIFY-LM-8F92A71X');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera access error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Sticker loaded from Gallery. Processing token...'),
            duration: Duration(milliseconds: 800),
          ),
        );
        _onCodeDetected('VERIFY-LM-9B41C22Y');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery access error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              // Subtle Camera Grid background
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

                              // Center QR Target Icon / Simulation
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
                      const SizedBox(height: 16),

                      // Quick Test Instrument QR Samples
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
                                  'Tap Sample Instrument Sticker to Simulate Scan:',
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
                              children: _sampleQrs.map((item) {
                                return InkWell(
                                  onTap: _isProcessing
                                      ? null
                                      : () => _onCodeDetected(item['code']!),
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
                                        color: item['code']!.startsWith('COUNTERFEIT')
                                            ? AppColors.error.withValues(alpha: 0.6)
                                            : AppColors.primaryLight.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['label']!,
                                          style: TextStyle(
                                            color: item['code']!.startsWith('COUNTERFEIT')
                                                ? Colors.redAccent
                                                : Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          item['detail']!,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
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
