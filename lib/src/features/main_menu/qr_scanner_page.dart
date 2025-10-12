import 'dart:async';
import 'package:flixbit/l10n/app_localizations.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../res/apptextstyles.dart';

class ScannerPage extends StatefulWidget{
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver{
  late MobileScannerController cameraController;
  bool _isControllerInitialized = false;
  bool _hasScanned = false; // Add this to your state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  // Separate controller initialization
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

  // Add method to handle hot reload
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

  void _foundQRCode(Barcode barcode) async {
    if (_hasScanned) return;
    _hasScanned = true;
    _disposeController();

    if (barcode.format == BarcodeFormat.qrCode) {
      await context.push(RouterEnum.sellerProfileView.routeName, extra: {
        'sellerId': '1',
        'verificationMethod': 'qr_scan'
      });
      /*  await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GuestVerifiedPage(barcode: barcode,)),
      );

       */
      _hasScanned = false;
      _initializeController(); // restart scanner after returning
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        Padding(padding: EdgeInsets.only(top: 65),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BackButton(color: Colors.white,),
              Text(AppLocalizations.of(context)!.scanQRCode, style: AppTextStyles.bodyTextStyle,),
              const SizedBox(width: 40,)
              // IconButton(onPressed: ()=> _showEditBottomSheet(context), icon: Icon(Icons.more_vert_rounded, color: Colors.white,))
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(15.0),
          child: SizedBox(
            height: size.height*0.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:  // 1. Camera Scanner at the bottom
              MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  if (!_hasScanned && capture.barcodes.isNotEmpty) {
                    _foundQRCode(capture.barcodes.first);
                  }
                },
              ),
            ),
          ),
        ),


      ],
    );
  }
}

