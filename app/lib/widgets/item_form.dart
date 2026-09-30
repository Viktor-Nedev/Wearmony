import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../util/format.dart';
import 'common.dart';

/// What the item form returns; the caller creates the item and uploads the image.
class NewItemData {
  const NewItemData({required this.json, this.image});

  final Json json;
  final List<int>? image;
}

const lipPalette = [
  '#9E2A4B',
  '#B0304A',
  '#C2185B',
  '#D96C83',
  '#C98A7D',
  '#8E3B46',
  '#E0707A',
  '#6D1F33',
];
const hairPalette = [
  '#1E1612',
  '#3B2A20',
  '#6B4A2E',
  '#C8A165',
  '#E3C79A',
  '#8A4B2A',
  '#5E2230',
  '#B8B8B8',
];

Future<NewItemData?> showItemForm(BuildContext context, ItemType type) =>
    showDialog<NewItemData>(
      context: context,
      builder: (context) => _ItemFormDialog(type: type),
    );

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({required this.type});

  final ItemType type;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _name = TextEditingController();
  final _price = TextEditingController(text: '0');
  late final _hex = TextEditingController(
    text: widget.type == ItemType.hair ? hairPalette[3] : lipPalette[0],
  );
  GarmentCategory _category = GarmentCategory.fullBody;
  List<int>? _image;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _hex.dispose();
    super.dispose();
  }

  bool get _validHex => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(_hex.text.trim());

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      double.tryParse(_price.text.replaceAll(',', '.')) != null &&
      (widget.type == ItemType.garment ? _image != null : _validHex);

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _image = bytes);
  }

  void _submit() {
    final price = double.parse(_price.text.replaceAll(',', '.'));
    final json = <String, dynamic>{
      'type': widget.type.name,
      'name': _name.text.trim(),
      'price': price,
    };
    if (widget.type == ItemType.garment) {
      json['category'] = _category.apiName;
    } else {
      json['colorHex'] = _hex.text.trim().toUpperCase();
    }
    Navigator.pop(context, NewItemData(json: json, image: _image));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (widget.type) {
      ItemType.garment => l10n.addGarment,
      ItemType.makeup => l10n.addMakeup,
      ItemType.hair => l10n.addHair,
    };
    final palette = widget.type == ItemType.hair ? hairPalette : lipPalette;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.itemName),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.itemPrice,
                  suffixText: '€',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (widget.type == ItemType.garment) ...[
                DropdownButtonFormField<GarmentCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(labelText: l10n.itemCategory),
                  items: [
                    for (final category in GarmentCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(categoryName(l10n, category)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(
                    _image == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(l10n.chooseItemPhoto),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.itemPhotoHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                Text(
                  l10n.itemColor,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hex in palette)
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _hex.text = hex),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 2,
                              color: _hex.text.toUpperCase() == hex
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: ColorDot(hex, size: 28),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hex,
                  decoration: InputDecoration(
                    labelText: 'HEX',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ColorDot(
                        _validHex ? _hex.text.trim() : null,
                        size: 20,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
