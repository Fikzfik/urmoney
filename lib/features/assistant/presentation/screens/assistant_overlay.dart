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
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (_textController.text.isNotEmpty != _hasText) {
      setState(() => _hasText = _textController.text.isNotEmpty);
    }
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(assistantProvider.notifier).processVoice(text);
      _textController.clear();
      _scrollToBottom();
      FocusScope.of(context).unfocus();
    }
  }

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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.35, 0.5, 0.75, 0.95],
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                // ── Drag Handle ──────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    // Toggle between half and full on tap
                    final current = _sheetController.size;
                    final target = current < 0.75 ? 0.95 : 0.5;
                    _sheetController.animateTo(
                      target,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Header row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: AppColors.primary, size: 16),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Asisten AI',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              // Expand/Collapse icon hint
                              AnimatedBuilder(
                                animation: _sheetController,
                                builder: (context, _) {
                                  final isExpanded = _sheetController.isAttached
                                      ? _sheetController.size > 0.7
                                      : false;
                                  return Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // ── Chat History ─────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    itemCount:
                        state.messages.length + (state.isThinking ? 1 : 0),
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

                // ── Input Area ───────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            enabled: !_isListening,
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'Mendengarkan...'
                                  : 'Ketik pesan...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onSubmitted: (_) => _handleSendText(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AvatarGlow(
                        animate: _isListening,
                        glowColor: AppColors.primary,
                        duration: const Duration(milliseconds: 2000),
                        repeat: true,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: () async {
                            if (_hasText) {
                              _handleSendText();
                              return;
                            }

                            if (_isListening) {
                              await voiceService.stop();
                              setState(() => _isListening = false);
                            } else {
                              final status =
                                  await Permission.microphone.request();
                              if (!status.isGranted) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Izin mic dibutuhkan untuk asisten suara')),
                                  );
                                }
                                return;
                              }

                              setState(() => _isListening = true);
                              await voiceService.listen(
                                onResult: (text) {
                                  ref
                                      .read(assistantProvider.notifier)
                                      .processVoice(text);
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
                          child: Icon(
                            _hasText
                                ? Icons.send_rounded
                                : (_isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
