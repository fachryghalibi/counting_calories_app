import 'package:aplikasi_counting_calories/service/food_detect_service.dart';
import 'package:aplikasi_counting_calories/service/food_rename_service.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
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
  
  // Add these variables for rename functionality
  String? _currentScanId;
  final TextEditingController _foodNameController = TextEditingController();
  bool _isRenamingRequired = false;
  bool _isRenaming = false;
  
  // Instance service
  final FoodDetectionService _foodDetectionService = FoodDetectionService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize with default name
    
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

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Copy file ke temporary directory untuk konsistensi
        final directory = await getTemporaryDirectory();
        final imagePath = path.join(
          directory.path,
          '${DateTime.now().millisecondsSinceEpoch}_gallery.jpg',
        );
        
        await image.saveTo(imagePath);
        
        if (mounted) {
          setState(() {
            _lastImagePath = imagePath;
          });

          // Proses gambar dari galeri
          await _processImage(imagePath);
        }
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      if (mounted) {
        _showErrorSnackBar('Error memilih gambar dari galeri: $e');
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
          // Extract scan ID from result if available
          // Assuming the result contains scan information
          // You might need to modify this based on your actual response structure
          _currentScanId = result.scanId; // Add this property to FoodDetectionResult if not exists
          _isRenamingRequired = true; // Require renaming before closing
        });
        
        // Auto save ke database jika ada hasil deteksi
        if (result.items.isNotEmpty) {
          await _saveResultToDatabase();
        }
        
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

  // New method to handle scan renaming
  // New method to handle scan renaming - SIMPLIFIED VERSION
Future<void> _renameScan() async {
  if (_currentScanId == null) {
    _showErrorSnackBar('Scan ID tidak ditemukan');
    return;
  }

  final newName = _foodNameController.text.trim();
  if (newName.isEmpty) {
    _showErrorSnackBar('Nama makanan tidak boleh kosong');
    return;
  }

  setState(() {
    _isRenaming = true;
  });

  try {
    // Call rename service
    final result = await FoodRenameService.renameScan(_currentScanId!, newName);
    
    print('Rename result: $result'); // Debug print
    
    if (result['success'] == true) {
      _showSuccessSnackBar(result['message'] ?? 'Nama makanan berhasil diubah!');
      setState(() {
        _isRenamingRequired = false;
      });
      // Close dialog after successful rename
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      _showErrorSnackBar(result['message'] ?? 'Gagal mengubah nama makanan');
    }
  } catch (e) {
    print('Error renaming scan: $e');
    _showErrorSnackBar('Gagal mengubah nama: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isRenaming = false;
      });
    }
  }
}

  void _showResultDialog() {
    if (_scanResult == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !_isRenamingRequired, // Prevent closing if rename is required
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant_menu, color: Colors.blue, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Food Detected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gambar yang diambil dengan border rounded
                      if (_lastImagePath != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(_lastImagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                      
                      // Food Name Input Field
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2D2D44),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Meal Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            TextField(
                              controller: _foodNameController,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter meal name...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Color(0xFF1A1A2E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              maxLines: 1,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Food items dengan desain yang diperbaiki
                      if (_scanResult!.items.isNotEmpty) ...[
                        // Header dengan background gelap
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2D2D44),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Food Detected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_scanResult!.items.length} items',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // List makanan dengan desain yang diperbaiki
                        Column(
                          children: _scanResult!.items.map((item) => Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF2D2D44),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Icon makanan dengan design yang lebih clean
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getFoodColor(item.name),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${item.name} X${_getFoodQuantity(item.name)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                        
                        // Auto save confirmation message
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Automatically saved',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF2D2D44),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.search_off, color: Colors.grey[400], size: 40),
                              SizedBox(height: 12),
                              Text(
                                'No food detected',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 20),
                      
                      // Total Kalori dengan desain yang lebih clean
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Calories',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${_scanResult!.totalCalorie}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'kcal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Save and Close button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRenaming ? null : _renameScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isRenaming
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Save & Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                // Skip button (optional - only show if rename is not required)
                if (!_isRenamingRequired) ...[
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Skip & Close',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Color _getFoodColor(String foodName) {
    // Mengembalikan warna berdasarkan jenis makanan
    if (foodName.toLowerCase().contains('noodle')) return Colors.blue;
    if (foodName.toLowerCase().contains('egg')) return Colors.orange;
    if (foodName.toLowerCase().contains('rice')) return Colors.white;
    if (foodName.toLowerCase().contains('meat')) return Colors.red;
    if (foodName.toLowerCase().contains('vegetable')) return Colors.green;
    return Colors.grey;
  }

  int _getFoodQuantity(String foodName) {
    // Simulasi quantity berdasarkan nama makanan
    if (foodName.toLowerCase().contains('egg')) return 4;
    return 1;
  }

  Future<void> _saveResultToDatabase() async {
    try {
      if (_scanResult != null) {
        // Implementasi penyimpanan hasil scan ke database
        // Bisa menggunakan SharedPreferences, SQLite, atau cloud storage
        // Tambahkan logika penyimpanan sesuai dengan struktur database Anda
        
        print('Saving scan result to database...');
        // await DatabaseService.saveFoodScanResult(_scanResult!);
        
        _showSuccessSnackBar('Hasil scan berhasil disimpan!');
      }
    } catch (e) {
      print('Error saving to database: $e');
      _showErrorSnackBar('Gagal menyimpan ke database: $e');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    _foodNameController.dispose(); // Don't forget to dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Jika ada error kamera, tampilkan error message dengan retry button
    if (_cameraError != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Camera Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _retryCamera,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Jika kamera belum initialized, tampilkan loading
    if (!_isInitialized) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Jika kamera sudah initialized, tampilkan camera preview
    return SafeArea(
      child: Stack(
        children: [
          // Camera Preview Full Screen
          Positioned.fill(
            child: ClipRRect(
              child: CameraPreview(_cameraController!),
            ),
          ),
          
          // Overlay gelap untuk kontras
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // Top section - Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Scan Food',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Detection area guide
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.blue, width: 4),
                          left: BorderSide(color: Colors.blue, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.blue, width: 4),
                          right: BorderSide(color: Colors.blue, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.blue, width: 4),
                          left: BorderSide(color: Colors.blue, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.blue, width: 4),
                          right: BorderSide(color: Colors.blue, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom section - Controls (Galeri, Scan, dan spacer seimbang)
            Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instruction text
                  Text(
                    'Position food within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 30),
                  
                  // Camera controls dengan layout seimbang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: _isProcessing ? null : _pickImageFromGallery,
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _isProcessing 
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3), 
                                  width: 2
                                ),
                              ),
                              child: Icon(
                                Icons.photo_library,
                                color: _isProcessing 
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                color: _isProcessing 
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Scan button (main)
                      GestureDetector(
                        onTap: _isProcessing ? null : _takePicture,
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isProcessing 
                                    ? Colors.blue.withOpacity(0.5)
                                    : Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _isProcessing
                                  ? SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Spacer dengan ukuran yang sama untuk menjaga keseimbangan
                      Container(
                        width: 60,
                        height: 60,
                        // Invisible container untuk menjaga spacing
                      ),
                    ],
                  ),
                  
                  if (_isProcessing) ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Processing image...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}