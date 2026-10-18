import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import 'chat_header.dart';
import '../view_model/chat_viewmodel.dart';
import 'chat_animations.dart';
import 'chat_composer.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.viewModel});

  final ChatViewModel viewModel;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final _controller = TextEditingController(text: widget.viewModel.draft);
  late final _scrollController = ScrollController(
    initialScrollOffset: widget.viewModel.scrollOffset,
  );

  @override
  void initState() {
    super.initState();
    widget.viewModel.setVisible(true);
    _controller.addListener(_draftChanged);
    _scrollController.addListener(_scrolled);
  }

  void _scrolled() => widget.viewModel.scrollOffset = _scrollController.offset;

  void _draftChanged() => widget.viewModel.setDraft(_controller.text);

  void _submit() {
    if (!widget.viewModel.canSend) return;
    widget.viewModel.submit();
    _controller.clear();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    widget.viewModel.setVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ChatHeader(chat: viewModel.chat),
              Expanded(child: _thread(context)),
              if (viewModel.chat != null && !viewModel.load.running)
                ChatComposer(
                  viewModel: viewModel,
                  controller: _controller,
                  onSubmit: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thread(BuildContext context) {
    final viewModel = widget.viewModel;
    final colors = Theme.of(context).colorScheme;
    if (viewModel.load.running) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: 'Loading conversation',
          child: CircularProgressIndicator(color: colors.onPrimaryContainer),
        ),
      );
    }
    if (viewModel.load.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Can’t load chat'),
            TextButton(
              onPressed: viewModel.load.execute,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final chat = viewModel.chat;
    if (chat == null) return const SizedBox.shrink();
    final children = <Widget>[
      Center(
        child: Container(
          margin: const EdgeInsets.only(
            bottom: Dimens.spaceChat + Dimens.space2xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.spaceM,
            vertical: Dimens.space2xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Dimens.dayRadius),
          ),
          child: Text(
            '${messageDayLabel(viewModel.messages.firstOrNull?.sentAt ?? DateTime.now()).toUpperCase()} · A LITTLE TIME FOR A CONVERSATION',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              height: 1.4,
              letterSpacing: .6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: Dimens.spaceChat),
        padding: Dimens.chatIntroPadding,
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          border: Border.all(color: colors.tertiary, width: Dimens.borderWidth),
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
        child: Text(
          'You’re chatting with a fictional AI character.\n'
          'This concept uses sample conversations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 0,
            color: colors.onTertiaryContainer,
            fontSize: 11,
            height: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      for (final message in viewModel.messages)
        MessageBubble(
          key: ValueKey(message.id),
          message: message,
          portraitAsset: chat.portraitAsset,
          animateReply: message.id == viewModel.revealingMessageId,
          onRevealComplete: viewModel.finishReveal,
        ),
      if (viewModel.pending case final pending?)
        MessageBubble(
          key: const ValueKey('pending-message'),
          message: pending,
          portraitAsset: chat.portraitAsset,
          pendingStatus: viewModel.pendingStatus,
          onRetry: viewModel.retry,
        ),
      if (viewModel.reply.running && !viewModel.isOffline)
        ThinkingIndicator(
          name: chat.friendName,
          portraitAsset: chat.portraitAsset,
        ),
      if (viewModel.reply.error && !viewModel.isOffline)
        Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Couldn’t get a reply.',
                style: TextStyle(letterSpacing: 0, color: colors.error),
              ),
              TextButton(
                onPressed: viewModel.reply.execute,
                child: const Text('Retry reply'),
              ),
            ],
          ),
        ),
    ];
    return Semantics(
      label: 'Conversation with ${chat.friendName}',
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          controller: _scrollController,
          reverse: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: Dimens.chatThreadPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  (constraints.maxHeight - Dimens.chatThreadPadding.vertical)
                      .clamp(0, double.infinity),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
