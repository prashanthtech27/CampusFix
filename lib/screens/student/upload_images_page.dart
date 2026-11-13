import 'dart:io';
import 'select_location_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadImagesPage extends StatefulWidget {
  final String selectedCategory;

  const UploadImagesPage({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<UploadImagesPage> createState() => _UploadImagesPageState();
}

class _UploadImagesPageState extends State<UploadImagesPage> {
  static const Color primaryBlue = Color(0xFF0866E8);
  static const Color darkBlue = Color(0xFF102A56);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color secondaryColor = Color(0xFF64748B);

  final ImagePicker _picker = ImagePicker();

  final List<XFile> selectedImages = [];

  // Maximum 5 images allowed.
  static const int maxImages = 5;

  // Select images from gallery.
  Future<void> _pickImages() async {
    final remainingImages = maxImages - selectedImages.length;

    if (remainingImages <= 0) {
      _showMessage('You can upload a maximum of 5 images.');
      return;
    }

    try {
      final List<XFile> images =
          await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isEmpty) return;

      setState(() {
        selectedImages.addAll(
          images.take(remainingImages),
        );
      });

      if (images.length > remainingImages) {
        _showMessage('Only 5 images can be uploaded.');
      }
    } catch (e) {
      _showMessage('Unable to select images. Please try again.');
    }
  }

  // Capture image using camera.
  Future<void> _captureImage() async {
    if (selectedImages.length >= maxImages) {
      _showMessage('You can upload a maximum of 5 images.');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImages.add(image);
        });
      }
    } catch (e) {
      _showMessage('Unable to open camera. Please try again.');
    }
  }

  // Remove selected image.
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Continue to location selection.
  void _goToNextPage() {
  if (selectedImages.isEmpty) {
    _showMessage('Please select at least one image.');
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SelectLocationPage(
        selectedCategory: widget.selectedCategory,
        imagePaths: selectedImages
            .map((image) => image.path)
            .toList(),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: darkBlue,
          ),
        ),
        title: const Text(
          'Add Photos',
          style: TextStyle(
            color: darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  const SizedBox(height: 5),

                  // Upload area.
                  _buildUploadArea(),

                  const SizedBox(height: 20),

                  // Selected images.
                  if (selectedImages.isNotEmpty)
                    _buildImagePreview(),

                  const SizedBox(height: 20),

                  // Information message.
                  _buildInformationBox(),
                ],
              ),
            ),
          ),

          // Bottom Next button.
          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20,
            ),
            color: Colors.white,

            child: SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: _goToNextPage,

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, size: 19),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upload section.
  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickImages,

      child: Container(
        height: 180,
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryBlue,
            width: 1.2,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              color: primaryBlue,
              size: 42,
            ),

            const SizedBox(height: 15),

            const Text(
              'Tap to upload image',
              style: TextStyle(
                color: darkBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'or select from gallery',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),

                TextButton.icon(
                  onPressed: _captureImage,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Image preview section.
  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Selected Images',
              style: TextStyle(
                color: darkBlue,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              '${selectedImages.length}/$maxImages',
              style: const TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 105,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedImages.length,

            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),

                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Image preview.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),

                      child: Image.file(
                        File(selectedImages[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Remove button.
                    Positioned(
                      top: -6,
                      right: -6,

                      child: GestureDetector(
                        onTap: () => _removeImage(index),

                        child: Container(
                          height: 25,
                          width: 25,

                          decoration: const BoxDecoration(
                            color: darkBlue,
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Information box.
  Widget _buildInformationBox() {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(9),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: primaryBlue,
            size: 21,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'You can upload up to 5 images.',
              style: TextStyle(
                color: darkBlue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}