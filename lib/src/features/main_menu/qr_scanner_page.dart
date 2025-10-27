import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/l10n/app_localizations.dart';
import 'package:flixbit/src/helpers/message_display_helper.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/qr_scan_service.dart';
import '../../service/offer_service.dart';
import '../../providers/offers_provider.dart';

class ScannerPage extends StatefulWidget{
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  late MobileScannerController cameraController;
  final QRScanService _scanService = QRScanService();
  final OfferService _offerService = OfferService();
  bool _isControllerInitialized = false;
  bool _hasScanned = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  void _initializeController() async{
    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
    );
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await cameraController.start();
      if (mounted) {
        setState(() => _isControllerInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _reinitializeController();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _disposeController();
        break;
      default:
        break;
    }
  }

  void _reinitializeController() {
    _disposeController();
    _initializeController();
  }

  void _disposeController() {
    if (_isControllerInitialized) {
      cameraController.dispose();
      _isControllerInitialized = false;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _reinitializeController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 65),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BackButton(color: AppColors.whiteColor),
              Text(
                AppLocalizations.of(context)!.scanQRCode,
                style: AppTextStyles.bodyTextStyle,
              ),
              IconButton(
                onPressed: () => DisplayMessageHelper.showQRScannerInfoDialog(context),
                icon: Icon(Icons.info_outline, color: AppColors.whiteColor),
              ),

              IconButton(onPressed: ()=> context.push(RouterEnum.qrScanHistoryView.routeName), icon: Icon(Icons.history))
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorColor, size: 20),
                  Expanded(child: Text(_error!, style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.errorColor,),),),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Container(
                height: size.height * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isProcessing
                        ? AppColors.primaryColor
                        : AppColors.darkGreyColor,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) {
                          if (!_hasScanned && capture.barcodes.isNotEmpty) {
                            _foundQRCode(capture.barcodes.first);
                          }
                        },
                      ),
                      if (_isProcessing)
                        Container(
                          color: AppColors.darkBgColor.withValues(alpha: 0.8),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Processing QR code...',
                                  style: AppTextStyles.bodyTextStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scan seller\'s QR code to earn points',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Scan from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _foundQRCode(Barcode barcode) async {
    if (_hasScanned || _isProcessing) return;
    setState(() {
      _hasScanned = true;
      _isProcessing = true;
      _error = null;
    });

    try {
      if (barcode.format != BarcodeFormat.qrCode) {
        throw Exception('Invalid QR code format');
      }

      final qrData = barcode.rawValue;
      if (qrData == null || qrData.isEmpty) {
        throw Exception('Invalid QR code data');
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Please sign in to scan QR codes');
      }

      // Parse QR code data
      final parts = qrData.split(':');

      if (parts.isEmpty || parts[0] != 'flixbit') {
        throw Exception('Invalid QR code format');
      }

      if (parts.length >= 3 && parts[1] == 'seller') {
        await _handleSellerQR(userId, parts[2], qrData);
      } else if (parts.length >= 4 && parts[1] == 'offer') {
        await _handleOfferQR(userId, parts[2], parts[3], qrData);
      } else {
        throw Exception('Unknown QR code type');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        DisplayMessageHelper.showSnackbarMessage(context, title: e.toString(), icon: Icons.error_outline);
      }
    } finally {
      if (mounted) {
        setState(() {
          _hasScanned = false;
          _isProcessing = false;
        });
        _initializeController();
      }
    }
  }

  Future<void> _handleSellerQR(String userId, String sellerId, String qrData) async {
    try {
      await _scanService.recordScan(userId: userId, sellerId: sellerId, qrCode: qrData,);

      if (mounted) {
        DisplayMessageHelper.showSnackbarMessage(context, title: 'Points awarded for QR scan!',
            textIconColor: AppColors.whiteColor,
            backgroundColor: AppColors.successColor);
      }

      // Navigate to seller profile
      if (mounted) {
        context.push('${RouterEnum.sellerProfileView.routeName}?sellerId=$sellerId&verificationMethod=qr_scan',);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleOfferQR(String userId, String offerId, String sellerId, String qrData) async {
    try {
      final provider = Provider.of<OffersProvider>(context, listen: false);
      final isValid = await _offerService.validateQRRedemption(userId, offerId, qrData);

      if (!isValid) {
        throw Exception('Invalid or expired offer QR code');
      }

      // Redeem offer via QR method
      final redemption = await provider.redeemOffer(userId: userId, offerId: offerId, method: 'qr', qrCodeData: qrData,);

      if (redemption == null) {
        throw Exception(provider.error ?? 'Failed to redeem offer');
      }

      if (mounted) {
        await DisplayMessageHelper.showOfferRedemptionSuccess(context, offerId: offerId, pointsEarned:  redemption.pointsEarned);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _processImageForQR(image.path);
      }
    } catch (e) {
      if (mounted) {
        DisplayMessageHelper.showSnackbarMessage(context, title: 'Failed to pick image: $e', backgroundColor: AppColors.errorColor);
      }
    }
  }

  Future<void> _processImageForQR(String imagePath) async {
    setState(()=> _isProcessing = true);

    try {
      final BarcodeCapture? capture = await cameraController.analyzeImage(imagePath);

      if (capture != null && capture.barcodes.isNotEmpty) {
        _foundQRCode(capture.barcodes.first);
      } else {
        throw Exception('No QR code found in image');
      }
    } catch (e) {
      if (mounted) {
        DisplayMessageHelper.showSnackbarMessage(context, title: 'Failed to scan QR from image: $e', backgroundColor: AppColors.errorColor);

      }
    } finally {
      if (mounted) {
        setState(()=> _isProcessing = false);
      }
    }
  }
}