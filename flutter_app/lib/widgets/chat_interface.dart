import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/heat_stats.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';

const _chips = [
  'Why is this area hot?',
  'What does the NDVI mean?',
  'How does this compare to other areas?',
  'What can be done to reduce heat?',
];

class ChatInterface extends ConsumerStatefulWidget {
  final String lgaId;
  final HeatStats heatStats;
  const ChatInterface({super.key, required this.lgaId, required this.heatStats});

  @override
  ConsumerState<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends ConsumerState<ChatInterface> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  Future<void> _send(String question) async {
    if (question.trim().isEmpty || _loading) return;
    final chat = ref.read(chatProvider.notifier);
    final history = ref.read(chatProvider);
    chat.add(ChatMessage(role: ChatRole.user, content: question, timestamp: DateTime.now()));
    _controller.clear();
    setState(() { _loading = true; _error = false; });
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final answer = await api.postChat(widget.lgaId, question, widget.heatStats, history);
      chat.add(ChatMessage(role: ChatRole.assistant, content: answer, timestamp: DateTime.now()));
      _scrollToBottom();
    } on ApiException {
      setState(() => _error = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _retry() async {
    final messages = ref.read(chatProvider);
    final lastUser = messages.lastWhere((m) => m.role == ChatRole.user, orElse: () => throw StateError('no user msg'));
    ref.read(chatProvider.notifier).clear();
    for (final m in messages.where((m) => m != lastUser)) {
      ref.read(chatProvider.notifier).add(m);
    }
    await _send(lastUser.content);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),

        if (messages.isNotEmpty)
          SizedBox(
            height: 280,
            child: ListView.separated(
              controller: _scrollController,
              itemCount: messages.length + (_loading ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                if (i == messages.length) return _LoadingBubble();
                final msg = messages[i];
                final isUser = msg.role == ChatRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3b82f6) : const Color(0xFFf3f4f6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.content,
                        style: TextStyle(fontSize: 14, color: isUser ? Colors.white : const Color(0xFF111827))),
                  ),
                );
              },
            ),
          ),

        if (_loading && messages.isEmpty) _LoadingBubble(),

        if (_error)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, size: 16, color: Color(0xFFdc2626)),
              label: const Text('Retry', style: TextStyle(color: Color(0xFFdc2626))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFfee2e2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

        // Prompt chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _chips.map((chip) => ActionChip(
                label: Text(chip, style: const TextStyle(fontSize: 12)),
                onPressed: _loading ? null : () => _controller.text = chip,
                backgroundColor: const Color(0xFFf3f4f6),
                side: const BorderSide(color: Color(0xFFd1d5db)),
                shape: const StadiumBorder(),
              )).toList(),
        ),
        const SizedBox(height: 8),

        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_loading,
                decoration: InputDecoration(
                  hintText: "Ask about this area's heat...",
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFd1d5db))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFd1d5db))),
                ),
                onSubmitted: _send,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loading ? null : () => _send(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingBubble extends StatefulWidget {
  @override
  State<_LoadingBubble> createState() => _LoadingBubbleState();
}

class _LoadingBubbleState extends State<_LoadingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFf3f4f6), borderRadius: BorderRadius.circular(12)),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity = ((_anim.value * 3 - i) % 1.0).clamp(0.3, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: opacity,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF9ca3af), shape: BoxShape.circle)),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
