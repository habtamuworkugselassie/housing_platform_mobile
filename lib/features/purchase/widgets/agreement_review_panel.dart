import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/simple_markdown.dart';

/// Review-and-sign panel for one agreement, used by the wizard and by the order details screen.
/// The name field and the checkbox stay disabled until the buyer has scrolled through the whole
/// text (short texts count as read right away).
class AgreementReviewPanel extends StatefulWidget {
  final String title;
  final String content;
  final int? version;
  final String providerName;
  final bool scrolledToEnd;
  final bool accepted;
  final String signatoryName;
  final bool attempted;
  final bool enabled;
  final ValueChanged<bool> onScrolledToEnd;
  final ValueChanged<bool> onAccepted;
  final ValueChanged<String> onSignatoryName;
  final double maxHeight;

  const AgreementReviewPanel({
    super.key,
    required this.title,
    required this.content,
    this.version,
    required this.providerName,
    required this.scrolledToEnd,
    required this.accepted,
    required this.signatoryName,
    this.attempted = false,
    this.enabled = true,
    required this.onScrolledToEnd,
    required this.onAccepted,
    required this.onSignatoryName,
    this.maxHeight = 340,
  });

  @override
  State<AgreementReviewPanel> createState() => _AgreementReviewPanelState();
}

class _AgreementReviewPanelState extends State<AgreementReviewPanel> {
  final ScrollController _scroll = ScrollController();
  late final TextEditingController _name = TextEditingController(text: widget.signatoryName);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(covariant AgreementReviewPanel old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content) {
      // A new text (new template version) must be read again.
      widget.onScrolledToEnd(false);
      widget.onAccepted(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
        _check();
      });
    }
    if (old.signatoryName != widget.signatoryName && _name.text != widget.signatoryName) {
      _name.text = widget.signatoryName;
    }
  }

  void _check() {
    if (!mounted || !_scroll.hasClients) return;
    final atEnd = _scroll.position.maxScrollExtent - _scroll.offset <= 24;
    if (atEnd && !widget.scrolledToEnd) widget.onScrolledToEnd(true);
  }

  void _jumpToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 450), _check);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final read = widget.scrolledToEnd;
    final nameError = widget.attempted && widget.signatoryName.trim().length < 3;
    final acceptError = widget.attempted && read && !widget.accepted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  Text(
                    'Between you and ${widget.providerName}${widget.version != null ? ' · version ${widget.version}' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: read ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(read ? 'Read in full' : 'Scroll to read',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: read ? const Color(0xFF047857) : const Color(0xFF92400E))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              key: const Key('agreement-scroll'),
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              child: SimpleMarkdown(widget.content, baseStyle: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ),
          ),
        ),
        if (!read)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Scroll through the whole agreement to enable the signature.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                ),
                TextButton(onPressed: _jumpToEnd, child: const Text('Jump to the end', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Opacity(
          opacity: read ? 1 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your full legal name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('agreement-signatory'),
                  controller: _name,
                  enabled: read && widget.enabled,
                  textCapitalization: TextCapitalization.words,
                  onChanged: widget.onSignatoryName,
                  decoration: InputDecoration(
                    hintText: 'As written on your ID',
                    errorText: nameError ? 'Enter your full name as your signature.' : null,
                    helperText: nameError ? null : 'Typing your name is your electronic signature.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  key: const Key('agreement-accept'),
                  value: widget.accepted,
                  onChanged: read && widget.enabled ? (v) => widget.onAccepted(v ?? false) : null,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.primaryColor,
                  title: Text('I have read and agree to the ${widget.title}.',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  subtitle: const Text('Required to place the order. The signed text and its fingerprint are stored with your order.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
                if (acceptError)
                  const Text('You must accept the agreement to continue.', style: TextStyle(fontSize: 12, color: AppTheme.error)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
