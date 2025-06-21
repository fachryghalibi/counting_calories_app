import 'package:aplikasi_counting_calories/service/food_detect_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FoodScanPage extends StatefulWidget {
  @override
  _FoodScanPageState createState() => _FoodScanPageState();
}

class _FoodScanPageState extends State<FoodScanPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _lastImagePath;
  FoodDetectionResult? _scanResult;
  String? _cameraError;
  
  // Instance service
  final FoodDetectionService _foodDetectionService = FoodDetectionService();

  @override
  void initState() {
    super.initState();
    // Delay initialization untuk memastikan widget sudah fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
      _checkServerConnection();
    });
  }

  Future<void> _initializeCamera() async {
    try {
      // Reset error state
      setState(() {
        _cameraError = null;
      });

      // Get available cameras dengan error handling yang lebih baik
      try {
        _cameras = await availableCameras();
      } catch (e) {
        print('Error getting cameras: $e');
        setState(() {
          _cameraError = 'Tidak dapat mengakses kamera: $e';
        });
        return;
      }

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = 'Tidak ada kamera yang tersedia';
        });
        return;
      }

      // Dispose controller lama jika ada
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      // Initialize camera controller dengan error handling
      try {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _cameraError = null;
          });
        }
      } catch (e) {
        print('Error initializing camera controller: $e');
        setState(() {
          _cameraError = 'Error menginisialisasi kamera: $e';
          _isInitialized = false;
        });
      }
    } catch (e) {
      print('Error in _initializeCamera: $e');
      setState(() {
        _cameraError = 'Error kamera: $e';
        _isInitialized = false;
      });
    }
  }

  Future<void> _checkServerConnection() async {
    final isAvailable = await _foodDetectionService.isServerAvailable();
    if (!isAvailable && mounted) {
      _showErrorSnackBar('Server Flask tidak tersedia. Pastikan server berjalan di http://127.0.0.1:5000');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if camera is still available
      if (_cameraController!.value.hasError) {
        throw Exception('Kamera mengalami error');
      }

      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile picture = await _cameraController!.takePicture();
      await picture.saveTo(imagePath);
      
      if (mounted) {
        setState(() {
          _lastImagePath = imagePath;
        });

        // Kirim gambar ke Flask API menggunakan service
        await _processImage(imagePath);
      }
      
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        _showErrorSnackBar('Error mengambil foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Menggunakan service untuk deteksi makanan
      final result = await _foodDetectionService.detectFood(imagePath);
      
      if (mounted) {
        setState(() {
          _scanResult = result;
        });
        
        _showResultDialog();
      }
      
    } on FoodDetectionException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error memproses gambar: $e');
      }
    }
  }

  void _showResultDialog() {
    if (_scanResult == null || !mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.blue),
              SizedBox(width: 8),
              Text('Hasil Scan Makanan'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gambar yang diambil
                  if (_lastImagePath != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(_lastImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  
                  // Total Kalori
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department, 
                             color: Colors.orange, size: 28),
                        SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              '${_scanResult!.totalCalorie}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              'kalori',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // List makanan terdeteksi
                  if (_scanResult!.items.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Makanan Terdeteksi (${_scanResult!.items.length}):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ...(_scanResult!.items.map((item) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.restaurant, 
                                   color: Colors.green.shade700, size: 20),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        subtitle: Text(
                          'Confidence: ${item.confidencePercentage}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '✓',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ))),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tidak ada makanan yang terdeteksi',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
            if (_scanResult!.items.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _saveResult();
                },
                icon: Icon(Icons.save),
                label: Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  void _saveResult() {
    if (_scanResult != null) {
      // Implementasi penyimpanan hasil scan
      // Bisa menggunakan SharedPreferences, SQLite, atau cloud storage
      _showSuccessSnackBar('Hasil scan berhasil disimpan!');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Method untuk retry inisialisasi kamera
  void _retryCamera() {
    setState(() {
      _isInitialized = false;
      _cameraError = null;
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          'Scan Kalori Makanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF2D2D44),
        elevation: 0,
        automaticallyImplyLeading: false, // This removes the back button
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Jika ada error kamera, tampilkan error message dengan retry button
    if (_cameraError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Error Kamera',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryCamera,
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Jika kamera belum initialized, tampilkan loading
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Memuat kamera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Jika kamera sudah initialized, tampilkan camera preview
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  CameraPreview(_cameraController!),
                  // Overlay untuk guide
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  // Center guide
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.7),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Letakkan makanan\ndi sini',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Arahkan kamera ke makanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pastikan makanan terlihat jelas dalam frame',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _isProcessing ? null : _takePicture,
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  child: _isProcessing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: Colors.white,
                        ),
                ),
              ),
              SizedBox(height: 16),
              if (_isProcessing)
                Column(
                  children: [
                    Text(
                      'Memproses gambar...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI akan mendeteksi jenis makanan dan menghitung kalori secara otomatis',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Cara Menggunakan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                Icons.camera_alt,
                'Posisikan Makanan',
                'Letakkan makanan dalam frame kamera dengan pencahayaan yang cukup',
              ),
              _buildHelpItem(
                Icons.center_focus_strong,
                'Fokus pada Makanan',
                'Pastikan makanan terlihat jelas dan tidak terpotong',
              ),
              _buildHelpItem(
                Icons.touch_app,
                'Ambil Foto',
                'Tap tombol kamera untuk mengambil foto dan memulai deteksi',
              ),
              _buildHelpItem(
                Icons.timeline,
                'Lihat Hasil',
                'AI akan menampilkan kalori total dan jenis makanan yang terdeteksi',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}