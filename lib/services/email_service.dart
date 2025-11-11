import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // EmailJS credentials
  static const String _serviceId = 'service_nmsbxle';
  static const String _apiKey = 'Zg_ydKuH3vXLONzg-';
  static const String _privateKey = 'uGEBZCtmRAlyprwS194nF';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static Future<bool> sendCartConfirmation({
    required String recipientEmail,
    required List<Map<String, dynamic>> cartItems,
    required double totalPrice,
  }) async {
    try {
      // Format items for email
      final itemsList = cartItems
          .map((item) => '- ${item['name']} x${item['quantity']} @ \$${(item['price'] as num).toStringAsFixed(2)}')
          .join('\n');

      print('📧 Sending email to: $recipientEmail');
      print('📦 Items: ${cartItems.length}');
      for (var item in cartItems) {
        print('   - ${item['name']} x${item['quantity']} @ \$${item['price']}');
      }
      print('💰 Total: \$${totalPrice.toStringAsFixed(2)}');

      // Send via EmailJS API with private key for strict mode
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': 'template_5p7y2dn',
          'user_id': _apiKey,
          'accessToken': _privateKey, // Private key for strict mode
          'template_params': {
            'to_email': recipientEmail,
            'customer_email': recipientEmail,
            'order_summary': itemsList,
            'total_price': totalPrice.toStringAsFixed(2),
            'order_date': DateTime.now().toString(),
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully to $recipientEmail');
        return true;
      } else {
        print('❌ Failed to send email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }
}
