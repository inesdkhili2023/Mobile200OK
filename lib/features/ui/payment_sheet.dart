import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

class PaymentSheet extends StatefulWidget {
  final int amountCents;
  const PaymentSheet({super.key, required this.amountCents});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String number = '';
  String expiry = '';
  String holder = '';
  String cvv = '';
  bool focus = false;

  @override
  Widget build(BuildContext context) {
    final amount = (widget.amountCents / 100).toStringAsFixed(2);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          children: [
            CreditCardWidget(
              cardNumber: number,
              expiryDate: expiry,
              cardHolderName: holder,
              cvvCode: cvv,
              showBackView: focus,
              onCreditCardWidgetChange: (_) {},
            ),
            CreditCardForm(
              formKey: formKey,
              cardNumber: number,
              expiryDate: expiry,
              cardHolderName: holder,
              cvvCode: cvv,
              obscureCvv: true,
              obscureNumber: true,
              inputConfiguration: InputConfiguration(
                cardNumberDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Card Number',
                  hintText: 'XXXX XXXX XXXX XXXX',
                ),
                expiryDateDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                ),
                cvvCodeDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'CVV',
                  hintText: 'XXX',
                ),
                cardHolderDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Card Holder',
                ),
              ),
              onCreditCardModelChange: (CreditCardModel model) {
                setState(() {
                  number = model.cardNumber;
                  expiry = model.expiryDate;
                  holder = model.cardHolderName;
                  cvv = model.cvvCode;
                  focus = model.isCvvFocused;
                });
              },
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true); // paiement simulé OK
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Veuillez remplir correctement le formulaire'),
                      ),
                    );
                  }
                },
                child: Text('Continuer — $amount DT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
