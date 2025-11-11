import 'package:flutter/material.dart';
import 'dart:convert';

/// Helper widget to display images from URL or base64 data URI.
/// Handles both HTTP/HTTPS URLs and data:image/* URIs.
class ImageDisplay extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Color? errorColor;

  const ImageDisplay({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Check if it's a data URI (base64 image)
      if (imageUrl.startsWith('data:image/')) {
        return _buildDataImage();
      }
      
      // Otherwise treat as HTTP URL
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildErrorWidget(),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildDataImage() {
    try {
      // Extract base64 content from data URI
      // Format: data:image/jpeg;base64,<base64-data>
      final parts = imageUrl.split(',');
      if (parts.length != 2) {
        return _buildErrorWidget();
      }

      final bytes = base64Decode(parts[1]);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildErrorWidget(),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: errorColor ?? Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        size: width * 0.4,
        color: Colors.grey[400],
      ),
    );
  }
}
