import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageService {
  static bool isNetworkImage(String path) {
    return path.startsWith('http') || path.startsWith('https');
  }

  static bool isLocalFile(String path) {
    return path.startsWith('/') || path.contains('Android') || path.contains('image_picker');
  }

  static bool isGooglePhotos(String path) {
    return path.contains('google') || path.contains('content://') || path.contains('media');
  }

  static Widget buildImage(String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    try {
      if (isNetworkImage(imagePath)) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => placeholder ?? _buildPlaceholder(width, height),
          errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(width, height),
        );
      } else if (isGooglePhotos(imagePath)) {
        // Pour Google Photos, utilisez Image.network ou un traitement spécial
        return Image.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildErrorWidget(width, height);
          },
        );
      } else {
        // Fichier local
        return Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildErrorWidget(width, height);
          },
        );
      }
    } catch (e) {
      return errorWidget ?? _buildErrorWidget(width, height);
    }
  }

  static Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  static Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}