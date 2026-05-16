import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/session.dart';

class ExtendSessionDialog extends StatefulWidget {
  const ExtendSessionDialog({
    super.key,
    required this.session,
    required this.settings,
    required this.onConfirm,
  });

  final Session session;
  final AppSettings settings;
  final Future<void> Function(double amount, int minutes) onConfirm;

  @override
  State<ExtendSessionDialog> createState() => _ExtendSessionDialogState();
}

class _ExtendSessionDialogState extends State<ExtendSessionDialog> {
  late final TextEditingController _amountController;
  late double _selectedAmount;
  late int _calculatedMinutes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.settings.basePrice;
    _calculatedMinutes = widget.settings.baseMinutes;
    _amountController = TextEditingController(
      text: widget.settings.basePrice.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateMinutes(double price) {
    setState(() {
      _selectedAmount = price;
      _calculatedMinutes = widget.settings.priceToMinutes(price).toInt();
    });
  }

  Future<void> _confirm() async {
    if (_selectedAmount <= 0 || _calculatedMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.onConfirm(_selectedAmount, _calculatedMinutes);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final newRemaining = widget.session.minutesRemaining + _calculatedMinutes;

    return AlertDialog(
      title: Text('Ajuster le temps - ${widget.session.stationName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.playerName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Temps actuel : ${AppConstants.formatDuration(widget.session.minutesRemaining)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateMinutes(double.tryParse(value) ?? 0),
              decoration: InputDecoration(
                labelText: 'Montant à ajouter (FCFA)',
                hintText: widget.settings.basePrice.toStringAsFixed(0),
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Montants rapides :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (index) {
                final price = widget.settings.basePrice * (index + 1);
                return FilterChip(
                  label: Text('${price.toStringAsFixed(0)} FCFA'),
                  selected: _selectedAmount == price,
                  onSelected: (_) {
                    _amountController.text = price.toStringAsFixed(0);
                    _updateMinutes(price);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temps ajouté',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${AppConstants.formatDuration(_calculatedMinutes)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nouveau reste : ${AppConstants.formatDuration(newRemaining)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter le temps'),
        ),
      ],
    );
  }
}
