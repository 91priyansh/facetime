import 'package:cloud_firestore/cloud_firestore.dart';

class CallHistory {
  final String callerId;
  final String to;
  final String channelName;
  final Timestamp timestamp;
  final String callHistoryId;
  final String toUsername;
  final String toImageUrl;

  CallHistory(
      {this.callHistoryId,
      this.channelName,
      this.callerId,
      this.timestamp,
      this.to,
      this.toImageUrl,
      this.toUsername});

  static CallHistory fromSnapshot(DocumentSnapshot doc) {
    var json = doc.data();
    return CallHistory(
        callHistoryId: doc.id,
        callerId: json['callerId'],
        timestamp: json['timestamp'],
        to: json['to'],
        channelName: json['channelName'] ?? "",
        toImageUrl: json['toImageUrl'],
        toUsername: json['toUsername']);
  }
}
