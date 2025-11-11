import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:service_app/core/email/sender.dart';
import 'package:service_app/models/worker_model.dart';
import '../logic/providers.dart';
import '../data/models.dart';
import '../../../core/notifications/local_notifs.dart';
import 'payment_sheet.dart';
import 'package:go_router/go_router.dart';
import '../../../services/location_service.dart';

class BookingForm extends ConsumerStatefulWidget {
  final String city; final DateTime date; final String slot; final int pax;
  final WorkerModel worker;
  const BookingForm({super.key, required this.city, required this.worker, required this.date, required this.slot, required this.pax});
@override
ConsumerState<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<BookingForm> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  final _email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final priceCents = 6000;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détails de réservation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description du besoin'), validator: (v)=> (v==null||v.isEmpty)?'Obligatoire':null),
              TextFormField(controller: _addr, decoration: const InputDecoration(labelText: 'Adresse')),              
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email de confirmation'), validator: (v)=> (v!=null && v.contains('@'))?null:'Email invalide'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
  if (!_form.currentState!.validate()) return;

  // 1️⃣ Confirmation du paiement
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmer le paiement'),
      content: const Text('Êtes-vous sûr de vouloir payer et finaliser la réservation ?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Non')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Oui')),
      ],
    ),
  );

  if (confirm != true) return;
  if (!mounted) return; // ✅ ici

  // 2️⃣ Feuille de paiement
  final paid = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PaymentSheet(amountCents: priceCents),
  );

  if (paid != true) {
    if (!mounted) return; // ✅ ici aussi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paiement annulé')),
    );
    return;
  }

  // 3️⃣ Affiche le chargement
  if (!mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Traitement du paiement et envoi de la confirmation...',
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    ),
  );

  try {
    

   final booking = Booking(
  workerId: widget.worker.id?.toString() ?? 'unknown',
  workerName: widget.worker.fullName,
  city: widget.city,
  date: widget.date,
  slot: widget.slot,
  description: _desc.text,
  address: _addr.text,
  pax: widget.pax,
  priceCents: widget.worker.price * 100,
  status: 'paid',
  email: _email.text,
  latitude : ref.read(userLatProvider),
   longitude: ref.read(userLngProvider),
);


    final id = await ref.read(bookingRepoProvider).create(booking);

    await LocalNotifs.scheduleReminder(
      DateTime(widget.date.year, widget.date.month, widget.date.day,
          int.parse(widget.slot.substring(0, 2))),
      title: 'Rappel réservation',
      body: 'Votre service commence à ${widget.slot}',
    );

    await sendConfirmationEmail(_email.text, booking);

    if (!mounted) return; // ✅ avant d'utiliser context
    Navigator.of(context).pop(); // ferme le dialog "loading"

    // ✅ Dialog de succès
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paiement effectué'),
        content: Text(
            'Votre paiement a été effectué avec succès. Un e-mail de confirmation a été envoyé à ${_email.text}.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // ferme le form sheet
              context.push('/success', extra: {'bookingId': id});
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  } catch (e) {
    if (!mounted) return;
    Navigator.of(context).pop(); // ferme le dialog loading s’il est ouvert

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erreur'),
        content:
            Text('Le paiement ou l’envoi du mail a échoué.\nDétail: $e'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }
},

                child: const Text('Payer & Confirmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
