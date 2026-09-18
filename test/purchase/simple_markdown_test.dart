import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/utils/simple_markdown.dart';

void main() {
  test('parses the agreement subset into blocks', () {
    final blocks = SimpleMarkdown.parse('# Title\n\nHello **bold**.\n\n- a\n- b\n\n1. one\n2. two\n\n---\n\nEnd');
    expect(blocks.map((b) => b.type), [
      MarkdownBlockType.heading,
      MarkdownBlockType.paragraph,
      MarkdownBlockType.bullets,
      MarkdownBlockType.numbered,
      MarkdownBlockType.rule,
      MarkdownBlockType.paragraph,
    ]);
    expect(blocks[0].level, 1);
    expect(blocks[2].items, ['a', 'b']);
    expect(blocks[3].items, ['one', 'two']);
  });

  testWidgets('renders headings and bold text as widgets, never as markup', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SimpleMarkdown('# PROMISE\n\n**Dream Teams Trading PLC** and <b>the buyer</b>.'))),
    ));
    expect(find.text('PROMISE'), findsOneWidget);
    final rich = tester.widget<Text>(find.byWidgetPredicate((w) => w is Text && w.textSpan != null));
    final plain = rich.textSpan!.toPlainText();
    expect(plain, contains('Dream Teams Trading PLC'));
    expect(plain, contains('<b>the buyer</b>'), reason: 'HTML stays literal text');
    expect(plain, isNot(contains('**')));
  });
}
