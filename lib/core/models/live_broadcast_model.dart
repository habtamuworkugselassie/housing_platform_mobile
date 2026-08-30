/// Public view of a live/approved broadcast (mirrors backend LiveBroadcastResponse).
class LiveBroadcast {
  final String id;
  final String title;
  final String broadcasterName;
  final String? broadcasterRole; // VISITOR | EXHIBITOR | ORGANIZER
  final String? companyName;
  final String status; // REQUESTED | APPROVED | REJECTED | LIVE | ENDED
  final String? hlsUrl;

  const LiveBroadcast({
    required this.id,
    required this.title,
    required this.broadcasterName,
    this.broadcasterRole,
    this.companyName,
    required this.status,
    this.hlsUrl,
  });

  factory LiveBroadcast.fromJson(Map<String, dynamic> json) {
    return LiveBroadcast(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      broadcasterName: json['broadcasterName'] as String? ?? '',
      broadcasterRole: json['broadcasterRole'] as String?,
      companyName: json['companyName'] as String?,
      status: json['status'] as String? ?? 'REQUESTED',
      hlsUrl: json['hlsUrl'] as String?,
    );
  }

  bool get isLive => status == 'LIVE';
  bool get isApproved => status == 'APPROVED' || status == 'LIVE';
  bool get isRejected => status == 'REJECTED';
  bool get isEnded => status == 'ENDED';
}

/// Everything a client needs to connect to LiveKit (mirrors backend LiveTokenResponse).
class LiveToken {
  final String url;
  final String token;
  final String room;
  final String? hlsUrl;

  const LiveToken({
    required this.url,
    required this.token,
    required this.room,
    this.hlsUrl,
  });

  factory LiveToken.fromJson(Map<String, dynamic> json) {
    return LiveToken(
      url: json['url'] as String? ?? '',
      token: json['token'] as String? ?? '',
      room: json['room'] as String? ?? '',
      hlsUrl: json['hlsUrl'] as String?,
    );
  }
}
