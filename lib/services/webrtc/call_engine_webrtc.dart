import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../signaling/firebase_signaling.dart';

enum WebRtcRole { caller, callee }

final class WebRtcCallEngine {
  WebRtcCallEngine({
    required FirebaseSignaling signaling,
    required String selfId,
  }) : _signaling = signaling,
       _selfId = selfId;

  final FirebaseSignaling _signaling;
  final String _selfId;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  StreamSubscription? _answerSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _remoteCandidatesSub;

  final StreamController<String> _events = StreamController.broadcast();
  Stream<String> get events => _events.stream;

  Future<void> dispose() async {
    await hangup();
    await _events.close();
  }

  Future<void> startCall({required String callId}) async {
    await _ensurePeerConnection(callId: callId, role: WebRtcRole.caller);

    await _signaling.createCall(callId, callerId: _selfId);

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    await _signaling.setOffer(callId, _sdpToJson(offer));

    _answerSub?.cancel();
    _answerSub = _signaling.watchAnswer(callId).listen((answerJson) async {
      if (answerJson == null) return;
      final current = await _pc?.getRemoteDescription();
      if (current != null) return;
      await _pc?.setRemoteDescription(_jsonToSdp(answerJson));
      _events.add('remote_answer_set');
    });

    _listenRemoteIce(callId: callId, role: WebRtcRole.caller);
  }

  Future<void> joinCall({required String callId}) async {
    await _ensurePeerConnection(callId: callId, role: WebRtcRole.callee);

    final offerJson = await _signaling.getOffer(callId);
    if (offerJson == null) {
      throw StateError('Call offer not found for callId=$callId');
    }

    await _pc!.setRemoteDescription(_jsonToSdp(offerJson));
    _events.add('remote_offer_set');

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _signaling.setAnswer(callId, _sdpToJson(answer));

    _listenRemoteIce(callId: callId, role: WebRtcRole.callee);
  }

  Future<void> hangup() async {
    await _answerSub?.cancel();
    await _offerSub?.cancel();
    await _remoteCandidatesSub?.cancel();
    _answerSub = null;
    _offerSub = null;
    _remoteCandidatesSub = null;

    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;

    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
  }

  Future<void> setMuted(bool muted) async {
    final tracks = _localStream?.getAudioTracks() ?? const [];
    for (final t in tracks) {
      t.enabled = !muted;
    }
  }

  Future<void> _ensurePeerConnection({
    required String callId,
    required WebRtcRole role,
  }) async {
    await hangup();

    final pc = await createPeerConnection(
      {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      },
      {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      },
    );
    _pc = pc;

    pc.onConnectionState = (state) {
      _events.add('pc_connection_state:$state');
    };
    pc.onIceConnectionState = (state) {
      _events.add('pc_ice_state:$state');
    };
    pc.onIceGatheringState = (state) {
      _events.add('pc_ice_gathering:$state');
    };

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    _localStream = stream;
    for (final track in stream.getAudioTracks()) {
      await pc.addTrack(track, stream);
    }

    pc.onIceCandidate = (candidate) {
      if (candidate == null) return;
      _signaling.addIceCandidate(
        callId,
        side: role == WebRtcRole.caller ? 'caller' : 'callee',
        candidate: _candidateToJson(candidate),
      );
    };
  }

  void _listenRemoteIce({required String callId, required WebRtcRole role}) {
    _remoteCandidatesSub?.cancel();
    final remoteSide = role == WebRtcRole.caller ? 'callee' : 'caller';
    _remoteCandidatesSub = _signaling
        .watchIceCandidates(callId, side: remoteSide)
        .listen((json) async {
          final cand = _jsonToCandidate(json);
          if (cand == null) return;
          await _pc?.addCandidate(cand);
        });
  }

  Map<String, Object?> _sdpToJson(RTCSessionDescription sdp) {
    return {'sdp': sdp.sdp, 'type': sdp.type};
  }

  RTCSessionDescription _jsonToSdp(Map<String, Object?> json) {
    final sdp = (json['sdp'] as String?) ?? '';
    final type = (json['type'] as String?) ?? 'offer';
    return RTCSessionDescription(sdp, type);
  }

  Map<String, Object?> _candidateToJson(RTCIceCandidate c) {
    return {
      'candidate': c.candidate,
      'sdpMid': c.sdpMid,
      'sdpMLineIndex': c.sdpMLineIndex,
    };
  }

  RTCIceCandidate? _jsonToCandidate(Map<String, Object?> json) {
    final cand = json['candidate'];
    if (cand is! String) return null;
    final sdpMid = json['sdpMid'];
    final sdpMLineIndex = json['sdpMLineIndex'];
    return RTCIceCandidate(
      cand,
      sdpMid is String ? sdpMid : null,
      sdpMLineIndex is int ? sdpMLineIndex : null,
    );
  }
}
