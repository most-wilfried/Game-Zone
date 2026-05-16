import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/inventory_item.dart';
import '../models/station.dart';
import '../repositories/database_repository.dart';

class AddStationDialog extends StatefulWidget {
  const AddStationDialog({super.key});

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  final _db = DatabaseRepository();

  // Stepper
  int _step = 1;

  // Étape 1
  final _nameController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _selectedConsoleType;

  // Étape 2
  final Map<String, List<InventoryItem>> _stockByType = {};
  final Set<int> _selectedItemIds = {};
  final Map<int, TextEditingController> _itemReferenceControllers = {};
  bool _loadingStock = true;
  String? _loadError;

  // Étape 3
  String? get _stationName =>
      _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
  String? get _stationReference => _referenceController.text.trim().isEmpty
      ? null
      : _referenceController.text.trim().toUpperCase();

  List<String> get _consoleTypes => AppConstants.consoleTypes;

  @override
  void initState() {
    super.initState();
    _loadStock();
    _nameController.text = 'VIP 1';
    _referenceController.text = 'A';
    _selectedConsoleType ??= _consoleTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _referenceController.dispose();
    for (final controller in _itemReferenceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() {
      _loadingStock = true;
      _loadError = null;
    });

    try {
      final items = await _db.getInventoryItems(status: 'en_stock');

      final byType = <String, List<InventoryItem>>{};
      for (final item in items) {
        byType.putIfAbsent(item.type, () => <InventoryItem>[]).add(item);
      }

      // Option: trier types pour une UI stable
      final sortedKeys = byType.keys.toList()..sort();
      final sortedMap = <String, List<InventoryItem>>{
        for (final k in sortedKeys)
          k: (byType[k]!..sort((a, b) => a.name.compareTo(b.name))),
      };

      setState(() {
        _stockByType
          ..clear()
          ..addAll(sortedMap);
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      setState(() {
        _loadingStock = false;
      });
    }
  }

  Future<void> _createStationWithAssignments() async {
    final stationName = _stationName;
    final stationReference = _stationReference;
    final consoleType = _selectedConsoleType;

    if (stationName == null) {
      _showSnack('Veuillez entrer le nom du poste');
      return;
    }
    if (stationReference == null) {
      _showSnack('Veuillez entrer la référence du poste');
      return;
    }
    if (consoleType == null) {
      _showSnack('Veuillez sélectionner une console');
      return;
    }
    if (_selectedItemIds.isEmpty) {
      _showSnack('Veuillez sélectionner au moins un équipement en stock');
      return;
    }
    if (!_hasSelectedConsole) {
      _showSnack('Sélectionnez la console en stock qui correspond à ce poste.');
      return;
    }

    // Contrainte demandée : items uniquement en stock (sélection provenant de stock en_stock)
    // Mais on sécurise côté DB en filtrant à nouveau lors du chargement final.
    final selectedIds = _selectedItemIds.toList();

    // Charger les items sélectionnés pour récupérer tous les champs nécessaires.
    // (On les recharge pour garantir l’état en stock.)
    final allStock = await _db.getInventoryItems(status: 'en_stock');
    final selectedItems = allStock
        .where((it) => selectedIds.contains(it.id))
        .toList();

    if (selectedItems.isEmpty) {
      _showSnack('Aucun article sélectionné n’est encore en stock');
      return;
    }
    if (!_hasRequiredEquipment) {
      _showSnack('Ajoutez au moins une manette pour ce type de console.');
      return;
    }
    final hasMissingReference = selectedItems.any((item) {
      final id = item.id;
      if (id == null) return true;
      return (_itemReferenceControllers[id]?.text.trim().isEmpty ?? true);
    });
    if (hasMissingReference) {
      _showSnack('Donnez une référence à chaque équipement sélectionné.');
      return;
    }

    final nowStation = Station(
      name: stationName,
      reference: stationReference,
      consoleType: consoleType,
    );
    if (!mounted) return;

    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(),
          ),
        );
      },
    );

    try {
      // Création Realtime Database puis affectation des équipements.
      final stationId = await _db.createStation(nowStation);
      if (stationId <= 0) {
        throw Exception('Impossible de créer le poste');
      }

      for (final item in selectedItems) {
        if (item.id == null) continue;
        final updated = item.copyWith(
          status: 'attribue',
          reference: _itemReferenceControllers[item.id!]!.text
              .trim()
              .toUpperCase(),
          assignedStationId: stationId,
          assignedStationName: stationName,
        );
        await _db.updateInventoryItem(updated);
      }

      navigator.pop(); // fermer le loader
      if (!mounted) return;
      navigator.pop(true); // fermer le dialog
    } catch (e) {
      navigator.pop(); // fermer le loader
      if (!mounted) return;
      _showSnack('Erreur: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canGoNextFromStep1 {
    return _stationName != null &&
        _stationReference != null &&
        _selectedConsoleType != null;
  }

  bool get _requiresController {
    return _selectedConsoleType != null && _selectedConsoleType != 'PC Gaming';
  }

  bool get _hasSelectedConsole {
    final selectedItems = _selectedItemIds
        .map((id) => _findItemById(id))
        .whereType<InventoryItem>();
    return selectedItems.any(_matchesSelectedConsole);
  }

  bool get _hasRequiredEquipment {
    if (!_requiresController) return true;
    final selectedItems = _selectedItemIds
        .map((id) => _findItemById(id))
        .whereType<InventoryItem>();
    return selectedItems.any(
      (item) => item.type.toLowerCase().contains('manette'),
    );
  }

  void _next() {
    if (_step == 1) {
      if (!_canGoNextFromStep1) {
        _showSnack('Complétez les informations (nom + référence + console)');
        return;
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      if (_selectedItemIds.isEmpty) {
        _showSnack('Sélectionnez au moins un équipement en stock');
        return;
      }
      if (!_hasSelectedConsole) {
        _showSnack('Sélectionnez la console en stock correspondant au poste.');
        return;
      }
      if (!_hasRequiredEquipment) {
        _showSnack('Ajoutez au moins une manette pour ce type de console.');
        return;
      }
      for (final id in _selectedItemIds) {
        final controller = _itemReferenceControllers[id];
        if (controller == null || controller.text.trim().isEmpty) {
          _showSnack(
            'Renseignez la référence de chaque équipement sélectionné.',
          );
          return;
        }
      }
      setState(() => _step = 3);
      return;
    }
  }

  void _back() {
    setState(() {
      _step = (_step - 1).clamp(1, 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF121514);
    const border = Color(0xFF1E2120);
    const accent = Color(0xFF00E676);
    const mutedText = Color(0xFFB0B0B0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          // Overlay blur
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
          // Content
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border, width: 1),
              ),
              constraints: BoxConstraints(
                maxWidth: 780,
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Étape $_step sur 3',
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildStepContent(
                          accent: accent,
                          mutedText: mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildBottomActions(accent: accent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent({required Color accent, required Color mutedText}) {
    switch (_step) {
      case 1:
        return _buildStep1(accent: accent, mutedText: mutedText);
      case 2:
        return _buildStep2(accent: accent, mutedText: mutedText);
      case 3:
        return _buildStep3(accent: accent, mutedText: mutedText);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1({required Color accent, required Color mutedText}) {
    const border = Color(0xFF1E2120);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom du poste',
          style: TextStyle(
            color: mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'VIP 1',
            hintStyle: TextStyle(color: mutedText.withValues(alpha: 0.7)),
            filled: true,
            fillColor: const Color(0xFF121514),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withValues(alpha: 1)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Référence du poste',
          style: TextStyle(
            color: mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _referenceController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'A',
            hintStyle: TextStyle(color: mutedText.withValues(alpha: 0.7)),
            prefixIcon: const Icon(Icons.tag, color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF121514),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withValues(alpha: 1)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        Text(
          'Type de console',
          style: TextStyle(
            color: mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _consoleTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final type = _consoleTypes[index];
            final isSelected = _selectedConsoleType == type;
            final emoji = AppConstants.consoleEmojis[type] ?? 'GM';

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedConsoleType = type;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: const Color(0xFF121514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accent : border,
                    width: 1.4,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        type,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : mutedText,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: accent, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        Text(
          'Sélectionnez le modèle de console qui sera lié au poste.',
          style: TextStyle(
            color: mutedText.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2({required Color accent, required Color mutedText}) {
    const border = Color(0xFF1E2120);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attribution des équipements (Stock lié)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (_requiresController && !_hasRequiredEquipment)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.38)),
            ),
            child: Text(
              'Ce poste nécessite au moins une manette sélectionnée avant de continuer.',
              style: TextStyle(
                color: Colors.orange[200],
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        if (!_hasSelectedConsole)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'La console du poste doit d’abord exister en stock. Sélectionnez une console "${_selectedConsoleType ?? ''}" dans la liste.',
              style: TextStyle(
                color: Colors.red[200],
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),

        if (_loadingStock) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_loadError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Erreur chargement stock: $_loadError',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ] else if (_stockByType.isEmpty) ...[
          Text(
            'Aucun équipement en stock pour le moment.',
            style: TextStyle(color: mutedText.withValues(alpha: 0.8)),
          ),
        ] else ...[
          for (final entry in _stockByType.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final item in entry.value)
                      _buildStockSelectorRow(item, accent, mutedText),
                  ],
                ),
              ),
            ),
          ],
        ],

        const SizedBox(height: 8),

        Text(
          _requiresController
              ? 'Seuls les articles marqués “En stock” apparaissent ici. Sélectionnez la console du poste, au moins une manette et les équipements nécessaires.'
              : 'Seuls les articles marqués “En stock” apparaissent ici. Sélectionnez au minimum la console du poste.',
          style: TextStyle(
            color: mutedText.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStockSelectorRow(
    InventoryItem item,
    Color accent,
    Color mutedText,
  ) {
    final isSelected = item.id != null && _selectedItemIds.contains(item.id);
    return _buildStockItemRow(
      item: item,
      accent: accent,
      mutedText: mutedText,
      isSelected: isSelected,
      onToggle: () {
        final id = item.id;
        if (id == null) return;
        if (!isSelected &&
            _isConsoleItem(item) &&
            !_matchesSelectedConsole(item)) {
          _showSnack('Cette console ne correspond pas au type sélectionné.');
          return;
        }
        setState(() {
          if (_selectedItemIds.contains(id)) {
            _selectedItemIds.remove(id);
          } else {
            _selectedItemIds.add(id);
            final controller = _itemReferenceControllers.putIfAbsent(
              id,
              () => TextEditingController(),
            );
            if (controller.text.trim().isEmpty) {
              controller.text =
                  '${_stationReference ?? ''}${_selectedItemIds.length}';
            }
          }
        });
      },
    );
  }

  Widget _buildStockItemRow({
    required InventoryItem item,
    required Color accent,
    required Color mutedText,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    // Badge état (ici: on suppose en_stock car chargement filtré)
    const badgeBg = Color(0xFF0E1110);
    final referenceController = item.id == null
        ? null
        : _itemReferenceControllers.putIfAbsent(
            item.id!,
            () => TextEditingController(),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: isSelected ? 'Désélectionner' : 'Sélectionner',
                onPressed: onToggle,
                icon: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? accent : mutedText,
                  size: 22,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : mutedText.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accent.withValues(
                                alpha: isSelected ? 0.45 : 0.22,
                              ),
                            ),
                          ),
                          child: Text(
                            'En stock',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? accent
                                  : mutedText.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        if (item.reference.isNotEmpty)
                          Text(
                            'Réf. ${item.reference}',
                            style: TextStyle(
                              color: mutedText,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        if (_isConsoleItem(item))
                          Text(
                            _matchesSelectedConsole(item)
                                ? 'Console compatible'
                                : 'Autre modèle',
                            style: TextStyle(
                              color: _matchesSelectedConsole(item)
                                  ? accent
                                  : Colors.orange[200],
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSelected && referenceController != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: TextField(
                controller: referenceController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Référence sur ce poste',
                  hintText: '${_stationReference ?? 'A'}1',
                  labelStyle: TextStyle(color: mutedText),
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.white70,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0E1110),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2120)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3({required Color accent, required Color mutedText}) {
    final consoleType = _selectedConsoleType;
    final stationName = _stationName;
    final emoji = consoleType == null
        ? 'GM'
        : (AppConstants.consoleEmojis[consoleType] ?? 'GM');

    final selectedItems = _selectedItemIds
        .map((id) => _findItemById(id))
        .whereType<InventoryItem>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF121514),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.55)),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${consoleType ?? '—'} · Réf. ${_stationReference ?? '—'}',
                      style: TextStyle(
                        color: mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Sorties de Stock',
          style: TextStyle(
            color: mutedText,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),

        if (selectedItems.isEmpty) ...[
          Text(
            'Aucun article sélectionné.',
            style: TextStyle(color: mutedText.withValues(alpha: 0.8)),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2120)),
            ),
            child: Column(
              children: selectedItems
                  .map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              it.type.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${it.name} · Réf. ${_itemReferenceControllers[it.id]?.text.trim().toUpperCase() ?? '—'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'En stock',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.yellow.withValues(alpha: 0.35)),
          ),
          child: Text(
            "Ces articles seront marqués comme 'Attribué' et liés à ce poste.",
            style: TextStyle(
              color: Colors.yellow[200],
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  InventoryItem? _findItemById(int id) {
    for (final list in _stockByType.values) {
      for (final it in list) {
        if (it.id == id) return it;
      }
    }
    return null;
  }

  bool _isConsoleItem(InventoryItem item) {
    return item.type.toLowerCase().contains('console');
  }

  bool _matchesSelectedConsole(InventoryItem item) {
    final selected = _selectedConsoleType;
    if (selected == null || !_isConsoleItem(item)) return false;
    final model = selected.toLowerCase();
    final haystack =
        '${item.name} ${item.reference} ${item.serialNumber ?? ''} ${item.notes ?? ''}'
            .toLowerCase();
    return haystack.contains(model) || model.contains(item.name.toLowerCase());
  }

  Widget _buildBottomActions({required Color accent}) {
    const mutedText = Color(0xFFB0B0B0);

    final isStep1 = _step == 1;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(false),
            style: TextButton.styleFrom(foregroundColor: mutedText),
            child: const Text('Annuler'),
          ),
        ),
        Row(
          children: [
            if (!isStep1)
              OutlinedButton(
                onPressed: _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1E2120)),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Retour'),
              ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                if (_step == 1 || _step == 2) {
                  _next();
                  return;
                }
                await _createStationWithAssignments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: Text(_step == 3 ? 'Créer le poste' : 'Suivant'),
            ),
          ],
        ),
      ],
    );
  }
}
