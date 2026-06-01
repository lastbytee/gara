import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
import '../../config/api_config.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/auth_provider.dart';
import 'clinical_resolution_screen.dart';
import '../../services/localization_service.dart';

class ConsultationChatScreen extends StatefulWidget {
  final ConsultationModel consultation;
  const ConsultationChatScreen({super.key, required this.consultation});

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final _textCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? _recordingPath;
  int _recordDuration = 0;
  Timer? _recordTimer;

  int? _playingMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ConsultationProvider>();
      prov.fetchMessages(widget.consultation.id);
      prov.startPolling(widget.consultation.id);
    });
  }

  @override
  void dispose() {
    context.read<ConsultationProvider>().stopPolling();
    _textCtl.dispose();
    _scrollCtl.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sendText() async {
    final text = _textCtl.text.trim();
    if (text.isEmpty) return;
    _textCtl.clear();
    await context.read<ConsultationProvider>().sendTextMessage(
      widget.consultation.id,
      text,
    );
    _scrollDown();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final success = await context.read<ConsultationProvider>().sendImageMessage(
        widget.consultation.id,
        bytes,
        picked.name,
      );
      if (success && mounted) {
        _scrollDown();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.failedToSendImage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera not available on web. Use gallery or test on a mobile device.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final success = await context.read<ConsultationProvider>().sendImageMessage(
        widget.consultation.id,
        bytes,
        picked.name,
      );
      if (success && mounted) {
        _scrollDown();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.failedToSendPhoto), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.microphonePermissionDenied)),
        );
      }
      return;
    }
    String path;
    try {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    } catch (_) {
      path = 'voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    }
    await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
    _recordingPath = path;
    _recordDuration = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration++);
    });
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();
    _isRecording = false;
    if (path != null) {
      _recordingPath = path;
      if (mounted) _showRecordingPreview();
    } else {
      _recordingPath = null;
      _recordDuration = 0;
      if (mounted) setState(() {});
    }
  }

  void _showRecordingPreview() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isPlaying = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void togglePlay() async {
              if (isPlaying) {
                await _audioPlayer.stop();
                setSheetState(() => isPlaying = false);
              } else if (_recordingPath != null) {
                final src = _recordingPath!.startsWith('blob:') || _recordingPath!.startsWith('http')
                    ? UrlSource(_recordingPath!)
                    : UrlSource('file://${_recordingPath!}');
                await _audioPlayer.play(src);
                setSheetState(() => isPlaying = true);
                _audioPlayer.onPlayerComplete.first.then((_) {
                  if (mounted) setSheetState(() => isPlaying = false);
                });
              }
            }

            void deleteRecording() {
              _audioPlayer.stop();
              _recordingPath = null;
              _recordDuration = 0;
              setState(() {});
              Navigator.pop(ctx);
            }

            void sendRecording() async {
              Navigator.pop(ctx);
              if (_recordingPath == null) return;
              try {
                final Uint8List bytes;
                if (_recordingPath!.startsWith('blob:') || _recordingPath!.startsWith('http')) {
                  bytes = (await http.get(Uri.parse(_recordingPath!))).bodyBytes;
                } else {
                  bytes = await File(_recordingPath!).readAsBytes();
                }
                final success = await context.read<ConsultationProvider>().sendAudioBytes(
                  widget.consultation.id,
                  bytes,
                  'voice_${DateTime.now().millisecondsSinceEpoch}.wav',
                );
                _recordingPath = null;
                _recordDuration = 0;
                setState(() {});
                if (success && mounted) {
                  _scrollDown();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocalizationService.failedToSendVoice), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }

            final fmt = Duration(seconds: _recordDuration);
            final display = '${fmt.inMinutes.toString().padLeft(2, '0')}:${(fmt.inSeconds % 60).toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocalizationService.voiceNote, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(display, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300, color: GaraTheme.primaryBlue)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: deleteRecording,
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
                          ),
                          Text(LocalizationService.delete, style: const TextStyle(fontSize: 11, color: Colors.red)),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: togglePlay,
                            icon: Icon(
                              isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                              color: GaraTheme.primaryBlue, size: 48,
                            ),
                          ),
                          Text(isPlaying ? LocalizationService.stop : LocalizationService.preview, style: const TextStyle(fontSize: 11, color: GaraTheme.primaryBlue)),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: sendRecording,
                            icon: const Icon(Icons.send, color: GaraTheme.accent, size: 32),
                          ),
                          Text(LocalizationService.send, style: const TextStyle(fontSize: 11, color: GaraTheme.accent)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _audioPlayer.stop();
      _recordingPath = null;
      _recordDuration = 0;
      if (mounted) setState(() {});
    });
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.consultation.patientName, style: const TextStyle(fontSize: 16)),
            Text(widget.consultation.status, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (widget.consultation.isActive)
            IconButton(
              icon: const Icon(Icons.medical_services_outlined),
              tooltip: LocalizationService.clinicalActionsTooltip,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClinicalResolutionScreen(consultation: widget.consultation),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ConsultationProvider>(
              builder: (_, cons, __) {
                if (cons.loading && cons.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (cons.messages.isEmpty) {
                  return Center(child: Text(LocalizationService.noMessagesYet));
                }
                return ListView.builder(
                  controller: _scrollCtl,
                  padding: const EdgeInsets.all(16),
                  itemCount: cons.messages.length,
                  itemBuilder: (_, i) {
                    final msg = cons.messages[i];
                    final userId = context.read<AuthProvider>().user?.id;
                    final isMe = msg.sender == userId;
                    return _messageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          if (_isRecording) _buildRecordingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    final fmt = Duration(seconds: _recordDuration);
    final display = '${fmt.inMinutes.toString().padLeft(2, '0')}:${(fmt.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.withAlpha(15),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
          ),
          const SizedBox(width: 8),
          Text(LocalizationService.recordingLabel, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(display, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _stopRecording,
            child: Text(LocalizationService.stop, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: GaraTheme.primaryBlue),
            tooltip: LocalizationService.galleryTooltip,
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: GaraTheme.primaryBlue),
            tooltip: LocalizationService.cameraTooltip,
            onPressed: _takePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.mic_none, color: GaraTheme.primaryBlue),
            tooltip: LocalizationService.voiceNoteTooltip,
            onPressed: _startRecording,
          ),
          Expanded(
            child: TextField(
              controller: _textCtl,
              decoration: InputDecoration(
                hintText: LocalizationService.typeMessage,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send, color: GaraTheme.primaryBlue),
            onPressed: _sendText,
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: 60,
        ),
        decoration: BoxDecoration(
          color: isMe ? GaraTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.senderName,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : GaraTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (msg.isText)
              Text(
                msg.textContent ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : GaraTheme.textPrimary,
                ),
              )
            else if (msg.isImage && msg.imageFile != null)
              _buildImageMessage(msg.imageFile!, isMe)
            else if (msg.isAudio && msg.audioFile != null)
              _buildAudioMessage(msg, isMe)
            else
              Text(
                msg.textContent ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : GaraTheme.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(String imageUrl, bool isMe) {
    final fullUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}media/$imageUrl';
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(fullUrl, fit: BoxFit.contain),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
        ),
      ),
    );
  }

  Widget _buildAudioMessage(MessageModel msg, bool isMe) {
    final isThisPlaying = _playingMessageId == msg.id;
    return InkWell(
      onTap: () async {
        if (isThisPlaying) {
          await _audioPlayer.stop();
          setState(() => _playingMessageId = null);
        } else if (msg.audioFile != null) {
          final url = '${ApiConfig.baseUrl.replaceAll('/api', '')}media/${msg.audioFile}';
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(url));
          setState(() => _playingMessageId = msg.id);
          _audioPlayer.onPlayerComplete.first.then((_) {
            if (mounted) setState(() => _playingMessageId = null);
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isThisPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            size: 24,
            color: isMe ? Colors.white : GaraTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            isThisPlaying ? LocalizationService.playing : LocalizationService.voiceNote,
            style: TextStyle(
              fontSize: 14,
              color: isMe ? Colors.white : GaraTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
