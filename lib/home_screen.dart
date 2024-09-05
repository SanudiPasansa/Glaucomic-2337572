import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  String _predictionResult = '';
  double? _probabilityPercentage;
  bool _isLoading = false;  // This will track the loading state
  String _errorMessage = '';  // This will track the error message

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _predictionResult = '';
        _probabilityPercentage = null;
        _errorMessage = '';
      });
    }
  }

  Future<void> _testGlaucoma() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image before testing.';
      });
      return;
    }

    String uploadUrl = 'http://13.53.57.205:8000/predict/';

    setState(() {
      _isLoading = true;  // Show loading indicator
      _errorMessage = '';  // Clear any previous error messages
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decodedResp = json.decode(respStr);
        setState(() {
          _predictionResult = decodedResp['prediction'] ?? 'No prediction available';
          _probabilityPercentage = decodedResp['probability_percentage']?.toDouble();
          _isLoading = false;
        });
      } else {
        setState(() {
          _predictionResult = 'Failed to get prediction. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'Failed to get prediction: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.pink.shade50,
        appBar: AppBar(
          backgroundColor: Colors.pink.shade100,
          title: const Center(
            child: Text(
              'Diagnosing Glaucoma',
              style: TextStyle(
                  color: Colors.indigo,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Center(
          child: Column(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.indigoAccent, width: 1),
                    color: Colors.white),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Upload Your Eye Image'),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.white,
                          context: context,
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.photo_library,
                                    color: Colors.indigoAccent,
                                  ),
                                  title: const Text('Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                                const Divider(
                                  color: Colors.grey,
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.indigoAccent,
                                  ),
                                  title: const Text('Camera'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.file_upload_outlined,
                        size: 28,
                        color: Colors.blueAccent,
                      ),
                    ),
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        fit: BoxFit.fill,
                        width: 150,
                        height: 150,
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _predictionResult = '';
                    _probabilityPercentage = null;
                  });
                },
                child: const Text('Remove Image'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _testGlaucoma,  // Disable the button if loading
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)  // Show loading indicator
                    : const Text('Test Glaucoma'),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_predictionResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        'Prediction: $_predictionResult',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_probabilityPercentage != null)
                        Text(
                          'Probability: ${_probabilityPercentage!.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
