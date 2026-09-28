import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';
import 'package:legal_metrology_verification/core/utils/qr_decoder.dart';
import 'package:legal_metrology_verification/services/mock_api_service.dart';
import 'package:legal_metrology_verification/models/instrument_model.dart';

void main() {
  test('Unique QR generation for products and instruments', () async {
    final api = MockApiService();

    // 1. Check all seeded instruments have unique QR codes
    final instruments = await api.getInstruments();
    final qrCodes = instruments.map((i) => i.qrVerificationCode).whereType<String>().toList();
    expect(qrCodes.length, equals(instruments.length));
    expect(qrCodes.toSet().length, equals(instruments.length), reason: 'All seeded QR codes must be unique');

    // 2. Create new instrument with null qrVerificationCode
    final newInst1 = InstrumentModel(
      id: 'test-1',
      instrumentId: 'LM-IN-MH-PUN-999001',
      type: 'Counter Scale',
      manufacturer: 'Avery',
      model: 'C-1',
      serialNumber: 'SN-999001',
      capacity: 30,
      unit: 'kg',
      yearOfManufacture: 2026,
      purchaseDate: DateTime.now(),
      locationName: 'Shop A',
      address: 'Street 1',
      latitude: 18.5,
      longitude: 73.8,
      ownerId: 'usr-owner-01',
      ownerName: 'Test Owner',
      status: InstrumentStatus.registered,
      registrationDate: DateTime.now(),
    );
    final created1 = await api.createInstrument(newInst1);
    expect(created1.qrVerificationCode, isNotNull);
    expect(created1.qrVerificationCode!.startsWith('VERIFY-LM-'), isTrue);

    // 3. Create another instrument to ensure uniqueness
    final newInst2 = newInst1.copyWith(
      id: 'test-2',
      instrumentId: 'LM-IN-MH-PUN-999002',
      serialNumber: 'SN-999002',
    );
    final created2 = await api.createInstrument(newInst2);
    expect(created2.qrVerificationCode, isNotNull);
    expect(created2.qrVerificationCode, isNot(equals(created1.qrVerificationCode)));

    // 4. Verify public QR code lookup works for the unique product QR code
    final verified = await api.verifyPublicQr(created1.qrVerificationCode!);
    expect(verified, isNotNull);
    expect(verified!.instrumentUniqueId, equals(created1.instrumentId));
  });

  test('QrDecoder decodes real QR images', () {
    const textToEncode = 'VERIFY-LM-MH-PUN-999001-TEST';

    final qrCode = QrCode.fromData(
      data: textToEncode,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    const scale = 8;
    const border = 4;
    final totalSize = (qrImage.moduleCount + border * 2) * scale;
    final image = img.Image(width: totalSize, height: totalSize);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    for (int x = 0; x < qrImage.moduleCount; x++) {
      for (int y = 0; y < qrImage.moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final px = (x + border) * scale;
          final py = (y + border) * scale;
          img.fillRect(
            image,
            x1: px,
            y1: py,
            x2: px + scale - 1,
            y2: py + scale - 1,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(image));
    final decoded = QrDecoder.decodeFromBytes(pngBytes);
    expect(decoded, equals(textToEncode));
  });

  test('QrDecoder decodes themed dark-blue QR codes', () {
    const textToEncode = 'VERIFY-LM-THEMED-COLOR-99';

    final qrCode = QrCode.fromData(
      data: textToEncode,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    const scale = 8;
    const border = 4;
    final totalSize = (qrImage.moduleCount + border * 2) * scale;
    final image = img.Image(width: totalSize, height: totalSize);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    for (int x = 0; x < qrImage.moduleCount; x++) {
      for (int y = 0; y < qrImage.moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final px = (x + border) * scale;
          final py = (y + border) * scale;
          img.fillRect(
            image,
            x1: px,
            y1: py,
            x2: px + scale - 1,
            y2: py + scale - 1,
            color: img.ColorRgb8(10, 37, 64), // Dark Blue (AppColors.primaryDark)
          );
        }
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(image));
    final decoded = QrDecoder.decodeFromBytes(pngBytes);
    expect(decoded, equals(textToEncode));
  });
}
