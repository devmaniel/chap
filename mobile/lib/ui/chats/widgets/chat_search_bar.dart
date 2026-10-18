import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';
import '../view_model/chats_viewmodel.dart';

/// Replaces the heading while searching. Focused on open; Cancel closes it.
class ChatSearchBar extends StatefulWidget {
  const ChatSearchBar({super.key, required this.viewModel});

  final ChatsViewModel viewModel;

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  static const _fieldMinHeight = 48.0;
  static const _focusRing = 4.0;
  static const _clearSize = 20.0;

  late final _controller = TextEditingController(text: widget.viewModel.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.viewModel.setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = widget.viewModel;
    final textStyle = TextStyle(
      color: colors.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimens.gutter, 10, 14, Dimens.spaceL),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: _fieldMinHeight),
              padding: const EdgeInsets.only(left: 14, right: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(Dimens.radius),
                border: Border.all(
                  color: colors.primary,
                  width: Dimens.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryContainer,
                    spreadRadius: _focusRing,
                  ),
                ],
              ),
              child: Row(
                spacing: Dimens.spaceS,
                children: [
                  AppIcon(
                    AppIconName.search,
                    size: 20,
                    color: colors.onPrimaryContainer,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: viewModel.setQuery,
                      textInputAction: TextInputAction.search,
                      cursorColor: colors.primary,
                      style: textStyle,
                      decoration: InputDecoration(
                        hintText: 'Name or message',
                        hintStyle: textStyle.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        filled: false,
                        isDense: true,
                        constraints: const BoxConstraints(),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: Dimens.spaceM,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (viewModel.query.isNotEmpty)
                    IconButton(
                      onPressed: _clear,
                      tooltip: 'Clear search',
                      constraints: const BoxConstraints.tightFor(
                        width: Dimens.minTapTarget,
                        height: Dimens.minTapTarget,
                      ),
                      icon: Container(
                        width: _clearSize,
                        height: _clearSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: AppIcon(
                          AppIconName.close,
                          size: 12,
                          color: colors.surface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: viewModel.closeSearch,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
