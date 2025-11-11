import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:service_app/features/data/models.dart';

/// Envoi d'un e-mail de confirmation réel via SMTP Gmail.
/// ⚠️ Il faut activer la "validation en deux étapes" et créer un mot de passe d'application Gmail.
Future<void> sendConfirmationEmail(String to, Booking booking) async {
  // 🟣 Mets ici ton adresse Gmail et ton mot de passe d'application
  final String username = 'onsgueblii@gmail.com';
  final String password = 'xsyqomhyernesiqp';

  // 🟢 Crée le serveur SMTP Gmail
  final smtpServer = gmail(username, password);

  // 📨 Message à envoyer
  final message = Message()
    ..from = Address(username, 'HandiCraft Reservation')
    ..recipients.add(to)
    ..subject = 'Confirmation de votre réservation — ${booking.workerName}'
    ..text = '''
Bonjour,

Votre paiement a été confirmé ✅

Voici les détails de votre réservation :

- Ouvrier : ${booking.workerName}
- Ville : ${booking.city}
- Date : ${booking.date.toLocal().toString().split(' ')[0]}
- Créneau : ${booking.slot}
- Montant : ${(booking.priceCents / 100).toStringAsFixed(2)} DT

Un rappel vous sera envoyé avant la date prévue.

Merci pour votre confiance !
L'équipe HandiCraft
''';

  try {
    await send(message, smtpServer);
    print('✅ Email envoyé avec succès à $to');
  } catch (e) {
    print('❌ Erreur envoi email : $e');
    rethrow;
  }
}
