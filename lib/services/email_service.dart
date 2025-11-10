import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_dqg57l6'; 
  static const String _templateId = 'template_canq5ys'; 
  static const String _signupTemplateId = 'template_6eznmde'; 
  static const String _publicKey = 'd9Y_Ol49SQL7GNdHm';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<bool> sendVerificationEmail({
    required String toEmail,
    required String verificationCode,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
           'Content-Type': 'application/json',
          'origin': 'http://localhost', 
          'User-Agent': 'FlutterApp/1.0',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'user_email': toEmail,
            'user_name': userName,
            'verification_code': verificationCode,
            'to_email': toEmail,
          },
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }

      print(
        'EmailJS request failed '
        '(status: ${response.statusCode}) -> ${response.body}',
      );
      return false;
    } catch (e) {

      print('Error sending email: $e');
      return false;
    }
  }


  Future<bool> sendSignupVerificationEmail({
    required String toEmail,
    required String verificationCode,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', 
          'User-Agent': 'FlutterApp/1.0',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _signupTemplateId,
          'user_id': _publicKey,
          'template_params': {
            'user_email': toEmail,
            'user_name': userName,
            'verification_code': verificationCode,
            'to_email': toEmail,
          },
        }),
      );


      if (response.statusCode == 200) {
        return true;
      }

      print(
        'EmailJS request failed '
        '(status: ${response.statusCode}) -> ${response.body}',
      );
      return false;
    } catch (e) {

      print('Error sending email: $e');
      return false;
    }
  }


  bool isConfigured() {
    final invalidValues = {
      '',
      'YOUR_SERVICE_ID',
      'YOUR_TEMPLATE_ID',
      'YOUR_PUBLIC_KEY',
      'service_hpnkwld',
      'template_gh1t0t9',
      'jDnx40E31dkyTNmUe',
    };

    final serviceId = _serviceId.trim();
    final templateId = _templateId.trim();
    final publicKey = _publicKey.trim();

    return !invalidValues.contains(serviceId) &&
        !invalidValues.contains(templateId) &&
        !invalidValues.contains(publicKey);
  }
}



