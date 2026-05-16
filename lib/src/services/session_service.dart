import 'dart:async';
import '../models/session.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  final Map<int, Timer> _timers = {};

  /// Démarre un timer pour une session active
  void startSessionTimer(
    Session session,
    Function(int remainingMinutes) onTick,
    Function() onExpired,
  ) {
    // Annule le timer existant si présent
    _timers[session.id ?? 0]?.cancel();

    final startedAt = DateTime.parse(session.startedAt);
    final now = DateTime.now();
    final totalSeconds = session.totalMinutes * 60;

    _timers[session.id ?? 0] = Timer.periodic(Duration(seconds: 1), (timer) {
      final currentElapsedSeconds =
          now.difference(startedAt).inSeconds +
          (session.minutesUsed * 60) +
          timer.tick;
      final remainingSeconds = totalSeconds - currentElapsedSeconds;
      final remainingMinutes = remainingSeconds ~/ 60;

      if (remainingSeconds <= 0) {
        timer.cancel();
        _timers.remove(session.id ?? 0);
        onExpired();
      } else {
        onTick(remainingMinutes);
      }
    });
  }

  /// Arrête le timer pour une session
  void stopSessionTimer(int? sessionId) {
    _timers[sessionId ?? 0]?.cancel();
    _timers.remove(sessionId ?? 0);
  }

  /// Arrête tous les timers
  void stopAllTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Calcule le temps restant avant expiration de pause (72h)
  static Duration getRemainingPauseTime(String expiresAt) {
    final expirationTime = DateTime.parse(expiresAt);
    final now = DateTime.now();
    final remaining = expirationTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Vérifie si une pause est expirée
  static bool isPauseExpired(String expiresAt) {
    final remaining = getRemainingPauseTime(expiresAt);
    return remaining.inSeconds <= 0;
  }

  /// Formate la durée de pause restante
  static String formatPauseRemaining(String expiresAt) {
    final remaining = getRemainingPauseTime(expiresAt);
    final hours = remaining.inHours;
    final minutes = (remaining.inMinutes % 60);

    if (hours >= 24) {
      final days = remaining.inDays;
      return '$days j${((hours - (days * 24))).toString().padLeft(2, '0')}h';
    }
    return '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}';
  }
}
