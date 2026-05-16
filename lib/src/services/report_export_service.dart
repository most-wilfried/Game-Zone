import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../models/session.dart';
import '../models/station.dart';

class ReportExportService {
  Future<void> exportReport({
    required String periodLabel,
    required DateTime from,
    required DateTime to,
    required AppUser user,
    required List<Session> sessions,
    required List<Sale> sales,
    required List<Station> stations,
    required List<InventoryItem> inventory,
  }) async {
    final document = pw.Document();
    final totalRevenue = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.amount,
    );
    final sessionRevenue = sales
        .where((sale) => sale.type == 'session')
        .fold<double>(0, (sum, sale) => sum + sale.amount);
    final productRevenue = sales
        .where((sale) => sale.type != 'session')
        .fold<double>(0, (sum, sale) => sum + sale.amount);
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.totalMinutes,
    );
    final stationRevenue = _stationRevenue(sessions, sales);
    final productRevenueByName = _productRevenue(sales);
    final playsPerDay = _playsPerDay(sessions, from, to);
    final maintenanceAlerts = inventory
        .where((item) => item.wearLevel != 'bon')
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'GameZone - Rapport $periodLabel',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Période: ${_formatDate(from)} - ${_formatDate(to)}'),
          pw.Text('Administrateur: ${user.name}'),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.6),
            children: [
              _row('CA total', AppConstants.formatPrice(totalRevenue)),
              _row('Sessions de jeu', AppConstants.formatPrice(sessionRevenue)),
              _row('Ventes produits', AppConstants.formatPrice(productRevenue)),
              _row(
                'Heures jouées',
                '${(totalMinutes / 60).toStringAsFixed(1)} h',
              ),
              _row('Sessions comptées', sessions.length.toString()),
              _row('Alertes maintenance', maintenanceAlerts.length.toString()),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Diagramme - revenus par poste',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _barChart(
            values: stationRevenue,
            formatter: AppConstants.formatPrice,
            color: PdfColors.green600,
            emptyText: 'Aucun revenu de poste sur cette période.',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Diagramme - sessions jouées par jour',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _barChart(
            values: playsPerDay.map(
              (key, value) => MapEntry(key, value.toDouble()),
            ),
            formatter: (value) => value.toStringAsFixed(0),
            color: PdfColors.blue600,
            emptyText: 'Aucune session sur cette période.',
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Récapitulatif par poste',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
            headers: const [
              'Poste',
              'Console',
              'Sessions',
              'CA',
              'Heures',
              'Statut',
            ],
            data: [
              for (final station in stations)
                [
                  station.name,
                  station.consoleType,
                  sessions
                      .where((session) => session.stationId == station.id)
                      .length
                      .toString(),
                  AppConstants.formatPrice(stationRevenue[station.name] ?? 0),
                  station.totalHoursUsed.toStringAsFixed(1),
                  station.status,
                ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Récapitulatif des ventes produits',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (productRevenueByName.isEmpty)
            pw.Text('Aucune vente produit sur cette période.')
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
              headers: const ['Produit', 'CA'],
              data: [
                for (final entry in productRevenueByName.entries)
                  [entry.key, AppConstants.formatPrice(entry.value)],
              ],
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
            headers: const ['Description', 'Type', 'Montant', 'Date'],
            data: [
              for (final sale in sales.take(24))
                [
                  sale.description,
                  sale.type == 'session' ? 'Session' : 'Produit',
                  AppConstants.formatPrice(sale.amount),
                  _formatDate(DateTime.tryParse(sale.createdAt) ?? from),
                ],
            ],
          ),
          if (maintenanceAlerts.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Alertes maintenance IA',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Bullet(
              text: maintenanceAlerts
                  .map((item) => '${item.name} (${item.wearLevel})')
                  .join(' | '),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => document.save());
  }

  pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label)),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Map<String, double> _stationRevenue(
    List<Session> sessions,
    List<Sale> sales,
  ) {
    final sessionsById = {
      for (final session in sessions)
        if (session.id != null) session.id!: session,
    };
    final revenueByStation = <String, double>{};

    for (final sale in sales.where((sale) => sale.type == 'session')) {
      final session = sessionsById[sale.sessionId];
      final stationName =
          session?.stationName ??
          _extractStationNameFromDescription(sale.description);
      revenueByStation.update(
        stationName,
        (value) => value + sale.amount,
        ifAbsent: () => sale.amount,
      );
    }

    return Map.fromEntries(
      revenueByStation.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, double> _productRevenue(List<Sale> sales) {
    final productRevenue = <String, double>{};
    for (final sale in sales.where((sale) => sale.type != 'session')) {
      final label = sale.description.replaceFirst('Vente: ', '').trim();
      productRevenue.update(
        label.isEmpty ? 'Produit' : label,
        (value) => value + sale.amount,
        ifAbsent: () => sale.amount,
      );
    }
    return Map.fromEntries(
      productRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, int> _playsPerDay(
    List<Session> sessions,
    DateTime from,
    DateTime to,
  ) {
    final buckets = <String, int>{};
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final totalDays = end.difference(start).inDays + 1;

    for (var i = 0; i < totalDays; i++) {
      final day = start.add(Duration(days: i));
      buckets[_shortDate(day)] = 0;
    }

    for (final session in sessions) {
      final startedAt = DateTime.tryParse(session.startedAt);
      if (startedAt == null) continue;
      final key = _shortDate(startedAt);
      if (buckets.containsKey(key)) {
        buckets.update(key, (value) => value + 1);
      }
    }
    return buckets;
  }

  pw.Widget _barChart({
    required Map<String, double> values,
    required String Function(double) formatter,
    required PdfColor color,
    required String emptyText,
  }) {
    final visible = Map.fromEntries(
      values.entries.where((entry) => entry.value > 0).take(12),
    );
    if (visible.isEmpty) return pw.Text(emptyText);

    final maxValue = visible.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return pw.Column(
      children: [
        for (final entry in visible.entries)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 72, child: pw.Text(entry.key, maxLines: 1)),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 180,
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: maxValue == 0 ? 0 : 180 * entry.value / maxValue,
                        height: 10,
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          height: 10,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 70,
                  child: pw.Text(
                    formatter(entry.value),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _extractStationNameFromDescription(String description) {
    final parts = description.split(' - ');
    if (parts.isEmpty) return 'Autre';
    final left = parts.first
        .replaceFirst('Session ', '')
        .replaceFirst('Prolongation ', '')
        .trim();
    return left.isEmpty ? 'Autre' : left;
  }

  String _shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
