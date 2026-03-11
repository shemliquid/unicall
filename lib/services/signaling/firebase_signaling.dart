import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, Object?>;

final class FirebaseSignaling {
  FirebaseSignaling({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<JsonMap> _callDoc(String callId) {
    return _db
        .collection('calls')
        .doc(callId)
        .withConverter<JsonMap>(
          fromFirestore: (snap, _) => snap.data() ?? <String, Object?>{},
          toFirestore: (value, _) => value,
        );
  }

  CollectionReference<JsonMap> _candidates(String callId, String side) {
    return _callDoc(callId)
        .collection('${side}Candidates')
        .withConverter<JsonMap>(
          fromFirestore: (snap, _) => snap.data() ?? <String, Object?>{},
          toFirestore: (value, _) => value,
        );
  }

  Future<void> createCall(String callId, {required String callerId}) async {
    await _callDoc(callId).set(<String, Object?>{
      'status': 'created',
      'callerId': callerId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOffer(String callId, JsonMap offer) async {
    await _callDoc(callId).set(<String, Object?>{
      'offer': offer,
      'status': 'offer_set',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setAnswer(String callId, JsonMap answer) async {
    await _callDoc(callId).set(<String, Object?>{
      'answer': answer,
      'status': 'answer_set',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<JsonMap?> getOffer(String callId) async {
    final snap = await _callDoc(callId).get();
    final data = snap.data();
    final offer = data?['offer'];
    return offer is Map<String, Object?> ? offer : null;
  }

  Stream<JsonMap?> watchAnswer(String callId) {
    return _callDoc(callId)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          final answer = data?['answer'];
          if (answer is Map<String, Object?>) return answer;
          return null;
        })
        .distinct((a, b) => _shallowMapEquals(a, b));
  }

  Stream<JsonMap?> watchOffer(String callId) {
    return _callDoc(callId)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          final offer = data?['offer'];
          if (offer is Map<String, Object?>) return offer;
          return null;
        })
        .distinct((a, b) => _shallowMapEquals(a, b));
  }

  Future<void> addIceCandidate(
    String callId, {
    required String side,
    required JsonMap candidate,
  }) async {
    await _candidates(callId, side).add(<String, Object?>{
      ...candidate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<JsonMap> watchIceCandidates(String callId, {required String side}) {
    return _candidates(callId, side).orderBy('createdAt').snapshots().expand((
      snap,
    ) {
      return snap.docChanges
          .where((c) => c.type == DocumentChangeType.added)
          .map((c) => c.doc.data() ?? <String, Object?>{});
    });
  }

  Future<void> endCall(String callId, {required String reason}) async {
    await _callDoc(callId).set(<String, Object?>{
      'status': 'ended',
      'endReason': reason,
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool _shallowMapEquals(JsonMap? a, JsonMap? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
