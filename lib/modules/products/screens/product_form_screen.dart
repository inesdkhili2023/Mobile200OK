import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late double _price;
  late String _image;

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _description = widget.product?.description ?? '';
    _price = widget.product?.price ?? 0;
    _image = widget.product?.image ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Nom du produit'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Entrez un nom' : null,
                  onSaved: (value) => _name = value!,
                ),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Entrez une description'
                      : null,
                  onSaved: (value) => _description = value!,
                ),
                TextFormField(
                  initialValue: _price.toString(),
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || double.tryParse(value) == null
                      ? 'Entrez un prix valide'
                      : null,
                  onSaved: (value) => _price = double.parse(value!),
                ),
                TextFormField(
                  initialValue: _image,
                  decoration: const InputDecoration(labelText: 'URL de l’image'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Entrez une image' : null,
                  onSaved: (value) => _image = value!,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final product = Product(
                        id: widget.product?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _name,
                        description: _description,
                        price: _price,
                        image: _image,
                      );

                      final provider =
                      Provider.of<ProductProvider>(context, listen: false);

                      if (isEditing) {
                        await provider.updateProduct(widget.product!.id, product);
                      } else {
                        await provider.addProduct(product);
                      }

                      if (mounted) {
                        context.go('/');
                      }
                    }
                  },
                  child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
