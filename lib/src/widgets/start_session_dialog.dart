import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class StartSessionDialog extends StatefulWidget {
  final String stationName;
  final Function(String playerName, double amount, int minutes) onConfirm;
  final List<String> recentPlayers;
  final AppSettings settings;

  const StartSessionDialog({
    super.key,
    required this.stationName,
    required this.onConfirm,
    required this.settings,
    this.recentPlayers = const [],
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  late TextEditingController _playerController;
  late TextEditingController _amountController;
  double _selectedAmount = 250;
  int _calculatedMinutes = 40;

  @override
  void initState() {
    super.initState();
    _playerController = TextEditingController();
    _selectedAmount = widget.settings.basePrice;
    _calculatedMinutes = widget.settings.baseMinutes;
    _amountController = TextEditingController(
      text: widget.settings.basePrice.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _playerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateMinutes(double price) {
    setState(() {
      _selectedAmount = price;
      _calculatedMinutes = widget.settings.priceToMinutes(price).toInt();
    });
  }

  void _confirmSession() {
    if (_playerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom du joueur')),
      );
      return;
    }

    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    widget.onConfirm(
      _playerController.text.trim(),
      _selectedAmount,
      _calculatedMinutes,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nouvelle session - ${widget.stationName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du joueur
            TextField(
              controller: _playerController,
              decoration: InputDecoration(
                labelText: 'Nom du joueur',
                hintText: 'Ex: Wilfried',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Suggestions de joueurs récents
            if (widget.recentPlayers.isNotEmpty) ...[
              const Text(
                'Joueurs récents :',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.recentPlayers.take(5).map((player) {
                  return ActionChip(
                    label: Text(player),
                    onPressed: () {
                      _playerController.text = player;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Montant
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                _updateMinutes(amount);
              },
              decoration: InputDecoration(
                labelText: 'Montant (FCFA)',
                hintText: widget.settings.basePrice.toStringAsFixed(0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'FCFA',
              ),
            ),
            const SizedBox(height: 12),

            // Montants rapides
            const Text(
              'Montants rapides :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(6, (index) {
                final price = widget.settings.basePrice * (index + 1);
                final isSelected = _selectedAmount == price.toDouble();
                return FilterChip(
                  label: Text('${price.toStringAsFixed(0)} FCFA'),
                  selected: isSelected,
                  onSelected: (_) {
                    _amountController.text = price.toStringAsFixed(0);
                    _updateMinutes(price);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Résumé du calcul
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conversion automatique :',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedAmount.toStringAsFixed(0)} FCFA → ${_formatDuration(_calculatedMinutes)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Base : ${widget.settings.ratioLabel}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _confirmSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Démarrer'),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
    return '${mins}min';
  }
}
