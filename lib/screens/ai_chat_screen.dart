import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/app_provider.dart';

/// Full-screen AI chat conversation with the AI Chef.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    _focusNode.unfocus();

    await context.read<AppProvider>().sendChatMessage(text);
    _scrollToBottom();
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    _focusNode.unfocus();
    await context.read<AppProvider>().sendChatMessage(prompt);
    _scrollToBottom();
  }

  void _confirmClearChat() {
    final t = context.read<AppProvider>().t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('chat_clear')),
        content: Text(t('chat_clear_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppProvider>().clearChat();
              Navigator.pop(ctx);
            },
            child: Text(t('common_ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.smart_toy_rounded, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('chat_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (provider.isAiTyping)
                    Text(
                      t('chat_typing'),
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (provider.chatMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: t('chat_clear'),
              onPressed: _confirmClearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Inventory context pill
          _InventoryContextPill(
            inventoryCount: provider.inventory.length,
            t: t,
            cs: cs,
          ),

          // Messages
          Expanded(
            child: provider.chatMessages.isEmpty
                ? _EmptyChatState(t: t, cs: cs)
                : _ChatMessagesList(
                    messages: provider.chatMessages,
                    isAiTyping: provider.isAiTyping,
                    scrollController: _scrollController,
                    t: t,
                    cs: cs,
                  ),
          ),

          // Quick prompts (only when chat is empty)
          if (provider.chatMessages.isEmpty)
            _QuickPromptsBar(
              prompts: provider.chatQuickPrompts,
              onTap: _sendQuickPrompt,
              t: t,
            ),

          // Error banner
          if (provider.chatError != null)
            _ErrorBanner(
              error: provider.chatError!,
              t: t,
              cs: cs,
              onRetry: () => _sendQuickPrompt(
                provider.chatMessages
                    .lastWhere(
                      (m) => m.role == ChatRole.user,
                      orElse: () => ChatMessage(
                        id: '',
                        role: ChatRole.user,
                        content: '',
                        timestamp: DateTime.now(),
                      ),
                    )
                    .content,
              ),
            ),

          // Input area
          _ChatInputBar(
            controller: _inputController,
            focusNode: _focusNode,
            isLoading: provider.isAiTyping,
            onSend: _sendMessage,
            t: t,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

// ── Inventory Context Pill ──────────────────────────────────────────────────

class _InventoryContextPill extends StatelessWidget {
  final int inventoryCount;
  final String Function(String) t;
  final ColorScheme cs;

  const _InventoryContextPill({
    required this.inventoryCount,
    required this.t,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            inventoryCount > 0
                ? t('chat_context_pill')
                    .replaceAll('{count}', '$inventoryCount')
                : t('chat_no_context'),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Chat State ────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  final String Function(String) t;
  final ColorScheme cs;

  const _EmptyChatState({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('chat_empty_state'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Messages List ──────────────────────────────────────────────────────

class _ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isAiTyping;
  final ScrollController scrollController;
  final String Function(String) t;
  final ColorScheme cs;

  const _ChatMessagesList({
    required this.messages,
    required this.isAiTyping,
    required this.scrollController,
    required this.t,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length + (isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isAiTyping) {
          return _TypingIndicator(cs: cs);
        }
        final msg = messages[index];
        return _ChatBubble(message: msg, cs: cs);
      },
    );
  }
}

// ── Chat Bubble ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme cs;

  const _ChatBubble({required this.message, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.smart_toy_rounded, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? cs.onPrimary : cs.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? cs.onPrimary.withAlpha(153)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.secondaryContainer,
              child: Icon(Icons.person_rounded, size: 16, color: cs.secondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing Indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final ColorScheme cs;
  const _TypingIndicator({required this.cs});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: widget.cs.primaryContainer,
            child: Icon(Icons.smart_toy_rounded,
                size: 16, color: widget.cs.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final progress = (_controller.value * 3 - i) % 1.0;
                    final scale = 0.5 + 0.5 * (1 - (2 * progress - 1).abs());
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.cs.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Prompts Bar ───────────────────────────────────────────────────────

class _QuickPromptsBar extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onTap;
  final String Function(String) t;

  const _QuickPromptsBar({
    required this.prompts,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t('chat_quick_prompts'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: prompts.map((prompt) {
              return ActionChip(
                label: Text(prompt),
                labelStyle: TextStyle(fontSize: 12, color: cs.onSurface),
                avatar: const Icon(Icons.lightbulb_outline, size: 16),
                onPressed: () => onTap(prompt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String error;
  final String Function(String) t;
  final ColorScheme cs;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.error,
    required this.t,
    required this.cs,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t('chat_error'),
              style: TextStyle(
                fontSize: 13,
                color: cs.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              t('common_retry'),
              style: TextStyle(color: cs.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Input Bar ──────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final String Function(String) t;
  final ColorScheme cs;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.t,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: t('chat_placeholder'),
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                onPressed: isLoading ? null : onSend,
                backgroundColor:
                    isLoading ? cs.surfaceContainerHighest : cs.primary,
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Icon(Icons.send_rounded, color: cs.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
