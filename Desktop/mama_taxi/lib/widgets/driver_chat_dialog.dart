import 'package:flutter/material.dart';
import 'package:mama_taxi/utils/constants.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class DriverChatDialog extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> driverInfo;
  final Function onClose;

  const DriverChatDialog({
    required this.orderId,
    required this.driverInfo,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  _DriverChatDialogState createState() => _DriverChatDialogState();
}

class _DriverChatDialogState extends State<DriverChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  String? _errorMessage;
  bool _isLoading = false;

  // Для звонков
  final String _appId = "08859bd0cc2246f193e41bedf7c53962";
  final String _rtcToken = "007eJxTYFjxlLnkpHZ4lMzzSXWnlHXLfZ3OFWXPXJVzr/mGjnVXwXcFBvMUY0sLQwsLUxNLCzOTRFMjYxNDM5NkUwODLYnGlIZARoZPLK8ZGRkgEMRnYShJLS5hYAAANlIfUw==";
  late String _channelName;
  late String _userId;
  RtcEngine? _engine;
  bool _isCallActive = false;
  bool _localAudioMuted = false;
  bool _speakerOn = true;
  String _callStatus = '';
  int _callDuration = 0;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _channelName = 'taxi_chat_${widget.orderId}';
    _userId = Supabase.instance.client.auth.currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    _messagesStream = Supabase.instance.client
        .from('messages:chat_id=eq.${widget.orderId}')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(100);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      await Supabase.instance.client.from('messages').insert({
        'chat_id': widget.orderId,
        'sender_id': _userId,
        'content': text,
      });
      _messageController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка отправки сообщения: $e';
      });
    }
  }

  // Voice call logic (unchanged)
  Future<void> _initVoiceCall() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: _appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await _engine!.enableAudio();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _isCallActive = true;
            _callStatus = 'Звонок начат';
            _startCallTimer();
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() {
            _isCallActive = false;
            _callStatus = '';
            _stopCallTimer();
          });
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _callStatus = 'Собеседник подключился';
          });
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          setState(() {
            _callStatus = 'Собеседник отключился';
          });
        },
        onError: (ErrorCodeType err, String msg) {
          setState(() {
            _callStatus = 'Ошибка: $msg';
          });
        },
        onNetworkQuality: (RtcConnection connection, int remoteUid, QualityType txQuality, QualityType rxQuality) {
          String quality = 'хорошее';
          if (txQuality.index >= 4 || rxQuality.index >= 4) {
            quality = 'плохое';
          } else if (txQuality.index >= 2 || rxQuality.index >= 2) {
            quality = 'среднее';
          }
          setState(() {
            _callStatus = 'Качество связи: $quality';
          });
        },
      ),
    );
  }

  Future<void> _startCall() async {
    if (_engine == null) {
      await _initVoiceCall();
    }
    String callChannelName = 'taxi_call_${widget.orderId}';
    await _engine!.joinChannel(
      token: _rtcToken,
      channelId: callChannelName,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _endCall() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      setState(() {
        _isCallActive = false;
      });
    }
  }

  Future<void> _toggleMute() async {
    if (_engine != null) {
      setState(() {
        _localAudioMuted = !_localAudioMuted;
      });
      await _engine!.muteLocalAudioStream(_localAudioMuted);
    }
  }

  Future<void> _toggleSpeaker() async {
    if (_engine != null) {
      setState(() {
        _speakerOn = !_speakerOn;
      });
      await _engine!.setEnableSpeakerphone(_speakerOn);
    }
  }

  void _startCallTimer() {
    _callDuration = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _callDuration = 0;
  }

  String _formatCallDuration() {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _endCall();
    if (_engine != null) {
      _engine!.release();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Container(
        width: double.maxFinite,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => widget.onClose(),
                  icon: const Icon(Icons.arrow_back),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: widget.driverInfo['avatarUrl'] != null && 
                        widget.driverInfo['avatarUrl'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.driverInfo['avatarUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driverInfo['name'] ?? 'Водитель',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    Text(
                      'В пути',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!_isCallActive)
                  IconButton(
                    onPressed: _startCall,
                    icon: Icon(Icons.call, color: AppColors.primary),
                  )
                else
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(Icons.call_end, color: Colors.red),
                  ),
                IconButton(
                  onPressed: () => widget.onClose(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            if (_isCallActive)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_in_talk, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _callStatus,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatCallDuration(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _toggleMute,
                          icon: Icon(
                            _localAudioMuted ? Icons.mic_off : Icons.mic,
                            color: _localAudioMuted ? Colors.red : AppColors.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleSpeaker,
                          icon: Icon(
                            _speakerOn ? Icons.volume_up : Icons.volume_down,
                            color: _speakerOn ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: _endCall,
                          icon: const Icon(Icons.call_end),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Подключение к чату...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        child: const Text('Попробовать снова'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final messages = snapshot.data!;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isDriver = msg['sender_id'] == widget.driverInfo['id'];
                        final time = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
                        return Align(
                          alignment: isDriver ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDriver ? Colors.grey[200] : AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Column(
                              crossAxisAlignment: isDriver ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(time),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 