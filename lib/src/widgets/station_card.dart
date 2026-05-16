import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/session.dart';
import '../constants/app_constants.dart';
import '../services/session_service.dart';

class StationCard extends StatefulWidget {
  final Station station;
  final Session? session;
  final int assetCount;
  final List<String> accessories;
  final VoidCallback onStartSession;
  final VoidCallback onPauseSession;
  final VoidCallback onResumeSession;
  final VoidCallback onExtendSession;
  final VoidCallback onEndSession;

  const StationCard({
    super.key,
    required this.station,
    this.session,
    this.assetCount = 0,
    this.accessories = const [],
    required this.onStartSession,
    required this.onPauseSession,
    required this.onResumeSession,
    required this.onExtendSession,
    required this.onEndSession,
  });

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  late SessionService _sessionService;
  int _remainingMinutes = 0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionService();
    _remainingMinutes = widget.session?.minutesRemaining ?? 0;

    if (widget.session != null &&
        widget.station.status == AppConstants.statusOccupe) {
      _initTimer();
    }
  }

  void _initTimer() {
    if (widget.session == null) return;

    _sessionService.startSessionTimer(
      widget.session!,
      (remainingMinutes) {
        setState(() {
          _remainingMinutes = remainingMinutes;
          _progress = 1.0 - (remainingMinutes / widget.session!.totalMinutes);
        });
      },
      () {
        // Session expirée
        widget.onEndSession();
      },
    );
  }

  @override
  void didUpdateWidget(StationCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.station.status != oldWidget.station.status ||
        widget.session?.id != oldWidget.session?.id ||
        widget.session?.startedAt != oldWidget.session?.startedAt ||
        widget.session?.totalMinutes != oldWidget.session?.totalMinutes ||
        widget.session?.minutesRemaining !=
            oldWidget.session?.minutesRemaining ||
        widget.session?.minutesUsed != oldWidget.session?.minutesUsed) {
      _sessionService.stopSessionTimer(oldWidget.session?.id);
      _remainingMinutes = widget.session?.minutesRemaining ?? 0;
      _progress = 0;

      if (widget.session != null &&
          widget.station.status == AppConstants.statusOccupe) {
        _initTimer();
      }
    }
  }

  @override
  void dispose() {
    _sessionService.stopSessionTimer(widget.session?.id);
    super.dispose();
  }

  Color get _statusColor =>
      AppConstants.statusColors[widget.station.status] ?? Colors.grey;
  String get _statusLabel =>
      AppConstants.statusLabels[widget.station.status] ?? 'Unknown';
  String get _consoleEmoji =>
      AppConstants.consoleEmojis[widget.station.consoleType] ?? 'GM';

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF121514);
    const border = Color(0xFF1E2120);
    const mutedText = Color(0xFFB0B0B0);

    return Card(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1F1D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      _consoleEmoji,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.station.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.station.reference.isEmpty
                    ? widget.station.consoleType
                    : '${widget.station.consoleType} · Réf. ${widget.station.reference}',
                style: const TextStyle(fontSize: 12, color: mutedText),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final accessory in widget.accessories.take(4))
                    Chip(
                      label: Text(accessory),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF1B1F1D),
                      side: const BorderSide(color: border),
                      labelStyle: const TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (widget.accessories.isEmpty)
                    Chip(
                      label: Text(
                        '${widget.assetCount} équipement${widget.assetCount > 1 ? 's' : ''}',
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF1B1F1D),
                      side: const BorderSide(color: border),
                      labelStyle: const TextStyle(
                        color: mutedText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.session != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F1D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session!.playerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.station.status ==
                          AppConstants.statusOccupe) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.station.status == AppConstants.statusEnPause
                                ? 'Restant'
                                : 'Temps restant',
                            style: const TextStyle(
                              fontSize: 12,
                              color: mutedText,
                            ),
                          ),
                          Text(
                            AppConstants.formatDuration(
                              widget.station.status ==
                                      AppConstants.statusEnPause
                                  ? widget.session!.minutesRemaining
                                  : _remainingMinutes,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total acheté',
                            style: TextStyle(fontSize: 12, color: mutedText),
                          ),
                          Text(
                            AppConstants.formatPrice(
                              widget.session!.amountPaid,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (widget.station.status == AppConstants.statusEnPause &&
                          widget.session!.expiresAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Expire dans : ${SessionService.formatPauseRemaining(widget.session!.expiresAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.session!.expiresAt != null
                                ? SessionService.isPauseExpired(
                                        widget.session!.expiresAt!,
                                      )
                                      ? Colors.red
                                      : Colors.orange
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compactButtons = constraints.maxWidth < 260;

                  if (widget.station.status == AppConstants.statusLibre) {
                    return ElevatedButton.icon(
                      onPressed: widget.onStartSession,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }

                  if (widget.station.status == AppConstants.statusOccupe) {
                    final pauseButton = ElevatedButton.icon(
                      onPressed: widget.onPauseSession,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    final extendButton = ElevatedButton.icon(
                      onPressed: widget.onExtendSession,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajuster'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF00E676),
                        side: const BorderSide(color: Color(0xFF00E676)),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );

                    return compactButtons
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: pauseButton,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: extendButton,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: pauseButton),
                              const SizedBox(width: 8),
                              Expanded(child: extendButton),
                            ],
                          );
                  }

                  if (widget.station.status == AppConstants.statusEnPause) {
                    final resumeButton = ElevatedButton.icon(
                      onPressed: widget.onResumeSession,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Reprendre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    final extendButton = ElevatedButton.icon(
                      onPressed: widget.onExtendSession,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajuster'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF00E676),
                        side: const BorderSide(color: Color(0xFF00E676)),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );

                    return compactButtons
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: resumeButton,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: extendButton,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: resumeButton),
                              const SizedBox(width: 8),
                              Expanded(child: extendButton),
                            ],
                          );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'En maintenance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
