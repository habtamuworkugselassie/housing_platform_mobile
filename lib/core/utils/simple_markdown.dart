import 'package:flutter/material.dart';

/// Renders the Markdown subset the agreement templates use (headings, paragraphs, bold, italics,
/// bullet and numbered lists, rules) as plain Flutter widgets. No package, no HTML, no links: the
/// text comes from the server and is shown as text only.
class SimpleMarkdown extends StatelessWidget {
  final String markdown;
  final TextStyle? baseStyle;

  const SimpleMarkdown(this.markdown, {super.key, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parse(markdown).map((block) => _render(context, block, base)).toList(),
    );
  }

  static Widget _render(BuildContext context, MarkdownBlock block, TextStyle base) {
    switch (block.type) {
      case MarkdownBlockType.heading:
        final size = block.level == 1 ? 18.0 : block.level == 2 ? 16.0 : 15.0;
        return Padding(
          padding: EdgeInsets.only(top: block.level == 1 ? 0 : 14, bottom: 6),
          child: Text(block.text, style: base.copyWith(fontSize: size, fontWeight: FontWeight.w800)),
        );
      case MarkdownBlockType.rule:
        return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1));
      case MarkdownBlockType.bullets:
      case MarkdownBlockType.numbered:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < block.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(block.type == MarkdownBlockType.bullets ? '•' : '${i + 1}.', style: base),
                      ),
                      Expanded(child: _inline(block.items[i], base)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case MarkdownBlockType.paragraph:
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: _inline(block.text, base));
    }
  }

  /// **bold** and *italic* runs inside a paragraph.
  static Widget _inline(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|(?<![*\w])\*([^*\n]+?)\*(?!\*)');
    var index = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > index) spans.add(TextSpan(text: text.substring(index, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        spans.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      index = m.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return Text.rich(TextSpan(style: base.copyWith(height: 1.5), children: spans));
  }

  /// Block-level parse; exposed for tests.
  static List<MarkdownBlock> parse(String markdown) {
    final blocks = <MarkdownBlock>[];
    final paragraph = <String>[];
    MarkdownBlock? list;

    void flushParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(MarkdownBlock.paragraph(paragraph.join('\n')));
        paragraph.clear();
      }
    }

    void closeList() {
      if (list != null) {
        blocks.add(list!);
        list = null;
      }
    }

    for (final raw in markdown.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flushParagraph();
        closeList();
        continue;
      }
      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        flushParagraph();
        closeList();
        blocks.add(MarkdownBlock.heading(heading.group(1)!.length, heading.group(2)!.trim()));
        continue;
      }
      if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(line.trim())) {
        flushParagraph();
        closeList();
        blocks.add(MarkdownBlock.rule());
        continue;
      }
      final bullet = RegExp(r'^\s*[-*]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        if (list?.type != MarkdownBlockType.bullets) {
          closeList();
          list = MarkdownBlock.list(MarkdownBlockType.bullets);
        }
        list!.items.add(bullet.group(1)!);
        continue;
      }
      final numbered = RegExp(r'^\s*\d+[.)]\s+(.*)$').firstMatch(line);
      if (numbered != null) {
        flushParagraph();
        if (list?.type != MarkdownBlockType.numbered) {
          closeList();
          list = MarkdownBlock.list(MarkdownBlockType.numbered);
        }
        list!.items.add(numbered.group(1)!);
        continue;
      }
      closeList();
      paragraph.add(line.trim());
    }
    flushParagraph();
    closeList();
    return blocks;
  }
}

enum MarkdownBlockType { heading, paragraph, bullets, numbered, rule }

class MarkdownBlock {
  final MarkdownBlockType type;
  final int level;
  final String text;
  final List<String> items;

  MarkdownBlock._(this.type, {this.level = 0, this.text = '', List<String>? items}) : items = items ?? [];

  factory MarkdownBlock.heading(int level, String text) => MarkdownBlock._(MarkdownBlockType.heading, level: level, text: text);
  factory MarkdownBlock.paragraph(String text) => MarkdownBlock._(MarkdownBlockType.paragraph, text: text);
  factory MarkdownBlock.rule() => MarkdownBlock._(MarkdownBlockType.rule);
  factory MarkdownBlock.list(MarkdownBlockType type) => MarkdownBlock._(type);
}
