import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/core/services/voice_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:urmoney/features/assistant/presentation/providers/assistant_provider.dart';

class AssistantOverlay extends ConsumerStatefulWidget {
  const AssistantOverlay({super.key});

  @override
  ConsumerState<AssistantOverlay> createState() => _AssistantOverlayState();
}

class _AssistantOverlayState extends ConsumerState<AssistantOverlay> {
  bool _isListening = false;
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);
    final voiceService = ref.read(voiceServiceProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Chat History
          SizedBox(
            height: 300,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: state.messages.length + (state.isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) {
                  return _buildThinking();
                }
                final msg = state.messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessage(msg['text']!, isUser);
              },
            ),
          ),

          // Voice Control Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _isListening ? 'Mendengarkan...' : 'Tekan mic untuk bicara',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AvatarGlow(
                  animate: _isListening,
                  glowColor: AppColors.primary,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: FloatingActionButton(
                    onPressed: () async {
                      if (_isListening) {
                        await voiceService.stop();
                        setState(() => _isListening = false);
                      } else {
                        // Request Permission
                        final status = await Permission.microphone.request();
                        if (!status.isGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Izin mic dibutuhkan untuk asisten suara')),
                            );
                          }
                          return;
                        }

                        setState(() => _isListening = true);
                        await voiceService.listen(
                          onResult: (text) {
                            ref.read(assistantProvider.notifier).processVoice(text);
                            _scrollToBottom();
                          },
                          onDone: () {
                            setState(() => _isListening = false);
                            _scrollToBottom();
                          },
                        );
                      }
                    },
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildThinking() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const SizedBox(
          width: 40,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ),
    );
  }
}
