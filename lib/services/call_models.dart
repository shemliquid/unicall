enum CallPhase {
  idle,
  outgoingDialing,
  incomingRinging,
  connecting,
  inCall,
  ended,
  failed,
}

enum CallEndReason { localHangup, remoteHangup, rejected, missed, error }

final class CaptionLine {
  CaptionLine({
    required this.text,
    required this.isPartial,
    required this.timestamp,
    this.speakerLabel,
  });

  final String text;
  final bool isPartial;
  final DateTime timestamp;
  final String? speakerLabel;
}

final class ChatMessage {
  ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.timestamp,
    this.wasSpoken = false,
  });

  final String id;
  final String from;
  final String text;
  final DateTime timestamp;
  final bool wasSpoken;

  ChatMessage copyWith({bool? wasSpoken}) {
    return ChatMessage(
      id: id,
      from: from,
      text: text,
      timestamp: timestamp,
      wasSpoken: wasSpoken ?? this.wasSpoken,
    );
  }
}
