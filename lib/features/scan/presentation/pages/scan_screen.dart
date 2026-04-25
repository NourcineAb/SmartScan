import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../data/services/ocr_service.dart';
import '../../../../core/services/entity_extraction_service.dart';
import '../../../../core/services/document_type_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../shared/models/entity_model.dart';
import '../../../../shared/models/bounding_box_model.dart';
import 'ocr_preview_screen.dart';
import 'save_scan_screen.dart';
import 'image_cropper_screen.dart';
import 'package:smart_scan/core/services/feedback_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInitializeCamera();
  }

  Future<void> _checkPermissionsAndInitializeCamera() async {
    final status = await Permission.camera.request();

    setState(() {
      _isCameraPermissionGranted = status.isGranted;
    });

    if (!mounted) return;

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required for scanning'),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }

    if (status.isGranted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera found on this device')),
          );
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller!.takePicture();

      // Shutter sound + haptic feedback
      FeedbackService().onShutter();

      if (!mounted) return;

      // Navigate to image cropper to select the OCR zone
      final cropData = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => ImageCropperScreen(imagePath: image.path),
        ),
      );

      if (cropData == null || !mounted) return;

      // Show loading dialog while extracting text
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Extraction du texte en cours...'),
            ],
          ),
        ),
      );

      // Extract structured text from image with crop zone
      final ocrService = OCRService();
      final ocrResult = await ocrService.extractStructuredText(
        image.path,
        cropZone: cropData,
      );

      // Detect language
      final languageService = LanguageService();
      final detectedLanguage = await languageService.detectLanguage(ocrResult.fullText);

      // Extract entities
      final entityService = EntityExtractionService();
      final entities = await entityService.extractEntities(ocrResult.fullText);

      // Detect document type
      final docTypeService = DocumentTypeService();
      final docTypeResult = docTypeService.detectDocumentType(ocrResult.fullText, entities);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate directly to save screen with all OCR data
      _navigateToSave(
        extractedText: ocrResult.fullText,
        imagePath: ocrResult.imagePath,
        boundingBoxes: ocrResult.elements,
        entities: entities,
        detectedLanguage: detectedLanguage,
        documentType: docTypeResult.type,
        documentTypeConfidence: docTypeResult.confidence,
        imageWidth: ocrResult.imageWidth,
        imageHeight: ocrResult.imageHeight,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _navigateToSave({
    required String extractedText,
    required String imagePath,
    List<BoundingBoxModel>? boundingBoxes,
    List<EntityModel>? entities,
    String? detectedLanguage,
    String? documentType,
    double? documentTypeConfidence,
    int? imageWidth,
    int? imageHeight,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Try to provide DashboardBloc if available in parent context
          try {
            final dashboardBloc = context.read<DashboardBloc>();
            return BlocProvider.value(
              value: dashboardBloc,
              child: SaveScanScreen(
                extractedText: extractedText,
                imagePath: imagePath,
                boundingBoxes: boundingBoxes,
                entities: entities,
                detectedLanguage: detectedLanguage,
                documentType: documentType,
                documentTypeConfidence: documentTypeConfidence,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ),
            );
          } catch (_) {
            // DashboardBloc not available, just show SaveScanScreen
            return SaveScanScreen(
              extractedText: extractedText,
              imagePath: imagePath,
              boundingBoxes: boundingBoxes,
              entities: entities,
              detectedLanguage: detectedLanguage,
              documentType: documentType,
              documentTypeConfidence: documentTypeConfidence,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartScan - Document Scanner'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
      ),
      body: !_isCameraPermissionGranted
          ? _buildPermissionDeniedUI()
          : _buildCameraUI(),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            'Camera Permission Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please enable camera permission to use the scan feature',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _checkPermissionsAndInitializeCamera,
            icon: const Icon(Icons.settings),
            label: const Text('Enable Camera'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUI() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              CameraPreview(_controller!),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'Position document in frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.blue[900]!,
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.blue[900],
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
