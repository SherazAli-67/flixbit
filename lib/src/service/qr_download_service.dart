import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class QRDownloadService {
  static final QRDownloadService _instance = QRDownloadService._internal();
  factory QRDownloadService() => _instance;
  QRDownloadService._internal();

  /// Generate QR code image from data
  Future<ui.Image> _generateQRImage(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (!qrValidationResult.isValid) {
      throw Exception('Invalid QR code data');
    }

    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      color: Colors.black,
      emptyColor: Colors.white,
    );

    final picRecorder = ui.PictureRecorder();
    final canvas = Canvas(picRecorder);
    const size = 300.0;
    painter.paint(canvas, const Size(size, size));
    final pic = picRecorder.endRecording();
    return await pic.toImage(size.toInt(), size.toInt());
  }

  /// Save QR code to device
  Future<String?> saveQRCodeToDevice(String qrData, String filename) async {
    try {
      final image = await _generateQRImage(qrData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename.png';
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      
      final file = File(path);
      await file.writeAsBytes(buffer);
      
      return path;
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      return null;
    }
  }

  /// Share QR code
  Future<void> shareQRCode(String qrData, String title) async {
    try {
      final filename = '${title.replaceAll(' ', '_')}_QR.png';
      final path = await saveQRCodeToDevice(qrData, filename);
      
      if (path != null) {
        // Note: Requires share_plus package or platform-specific implementation
        // For now, copy to clipboard
        await copyQRDataToClipboard(qrData);
      }
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
    }
  }

  /// Copy QR code data to clipboard
  Future<void> copyQRDataToClipboard(String qrData) async {
    try {
      await Clipboard.setData(ClipboardData(text: qrData));
    } catch (e) {
      debugPrint('Error copying QR data: $e');
    }
  }

  /// Show QR code in dialog
  Future<void> showQRCodeDialog(
    BuildContext context,
    String qrData,
    String title,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(title, style: AppTextStyles.subHeadingTextStyle),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: QrImageView(
            data: qrData,
            size: 200,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await shareQRCode(qrData, title);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

