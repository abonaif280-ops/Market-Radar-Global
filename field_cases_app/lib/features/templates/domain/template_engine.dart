/// محرك قوالب بسيط بصيغة قريبة من Mustache، بمتغيرات عربية:
///
/// - `{{الوقت}}` تُستبدل بقيمة المتغير (فارغ إن لم يوجد).
/// - `{{#وجود_حريق}} ... {{/وجود_حريق}}` يظهر المحتوى إذا كانت القيمة "صحيحة"
///   (نص غير فارغ، true، رقم أكبر من صفر، قائمة غير فارغة).
/// - `{{^وجود_حريق}} ... {{/وجود_حريق}}` يظهر المحتوى إذا كانت القيمة "فارغة".
///
/// بعد الاستبدال يُنظَّف النص من المسافات المكررة وعلامات الترقيم المتتالية
/// الناتجة عن الحقول الفارغة.
class TemplateEngine {
  const TemplateEngine._();

  static final RegExp _tag = RegExp(r'\{\{\s*([#^/]?)\s*([^{}]+?)\s*\}\}');

  static String render(String template, Map<String, Object?> variables) {
    final nodes = _parse(template);
    final buffer = StringBuffer();
    _renderNodes(nodes, variables, buffer);
    return cleanUp(buffer.toString());
  }

  /// أخطاء بنية القالب ومتغيراته غير المعروفة (لمحرر القوالب).
  static List<String> validate(String template, Set<String> knownVariables) {
    final errors = <String>[];
    final open = <String>[];
    for (final match in _tag.allMatches(template)) {
      final kind = match.group(1)!;
      final name = match.group(2)!;
      if (kind == '/') {
        if (open.isEmpty || open.last != name) {
          errors.add('إغلاق غير متوقع: {{/$name}}');
        } else {
          open.removeLast();
        }
        continue;
      }
      if (kind.isNotEmpty) open.add(name);
      if (!knownVariables.contains(name)) {
        errors.add('متغير غير معروف: {{$name}}');
      }
    }
    for (final name in open.reversed) {
      errors.add('قسم غير مغلق: {{#$name}} يحتاج {{/$name}}');
    }
    return errors.toSet().toList();
  }

  static bool isTruthy(Object? value) => switch (value) {
    null => false,
    final bool b => b,
    final num n => n > 0,
    final String s => s.trim().isNotEmpty,
    final Iterable<Object?> i => i.isNotEmpty,
    _ => true,
  };

  static String stringify(Object? value) => switch (value) {
    null => '',
    true => 'نعم',
    false => 'لا',
    final Iterable<Object?> i => i.join('، '),
    _ => value.toString().trim(),
  };

  /// تنظيف النتيجة: مسافات مكررة، مسافة قبل علامة ترقيم، فواصل متتالية.
  static String cleanUp(String text) {
    var result = text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(RegExp(r' +([،,.:؛])'), (m) => m.group(1)!)
        .replaceAll(RegExp(r' *\n *'), '\n');
    // "،،" أو "، ،" الناتجة عن أقسام فارغة متجاورة.
    final repeatedCommas = RegExp(r'([،,])(\s*[،,])+');
    result = result.replaceAllMapped(repeatedCommas, (m) => m.group(1)!);
    result = result
        .replaceAll(RegExp(r'[،,]\s*\.'), '.')
        .replaceAll(RegExp(r'\(\s*\)'), '')
        .replaceAll(RegExp(r'^[\s،,.]+'), '')
        .replaceAll(RegExp(r'[ ،,]+$'), '');
    return result.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  // ------------------------------------------------------------ داخلي

  static List<_Node> _parse(String template) {
    final root = <_Node>[];
    final stack = <(_Section, List<_Node>)>[];
    var current = root;
    var position = 0;

    for (final match in _tag.allMatches(template)) {
      if (match.start > position) {
        current.add(_Text(template.substring(position, match.start)));
      }
      position = match.end;
      final kind = match.group(1)!;
      final name = match.group(2)!;
      switch (kind) {
        case '#' || '^':
          final section = _Section(name, inverted: kind == '^');
          current.add(section);
          stack.add((section, current));
          current = section.children;
        case '/':
          // إغلاق بلا فتح مطابق يُتجاهل؛ المحرر يعرضه كخطأ عبر validate().
          final index = stack.lastIndexWhere((s) => s.$1.name == name);
          if (index < 0) continue;
          current = stack[index].$2;
          stack.removeRange(index, stack.length);
        default:
          current.add(_Variable(name));
      }
    }
    if (position < template.length) {
      current.add(_Text(template.substring(position)));
    }
    return root;
  }

  static void _renderNodes(
    List<_Node> nodes,
    Map<String, Object?> variables,
    StringBuffer out,
  ) {
    for (final node in nodes) {
      switch (node) {
        case _Text(:final text):
          out.write(text);
        case _Variable(:final name):
          out.write(stringify(variables[name]));
        case _Section(:final name, :final inverted, :final children):
          if (isTruthy(variables[name]) != inverted) {
            _renderNodes(children, variables, out);
          }
      }
    }
  }
}

sealed class _Node {}

class _Text extends _Node {
  _Text(this.text);

  final String text;
}

class _Variable extends _Node {
  _Variable(this.name);

  final String name;
}

class _Section extends _Node {
  _Section(this.name, {required this.inverted});

  final String name;
  final bool inverted;
  final List<_Node> children = [];
}
