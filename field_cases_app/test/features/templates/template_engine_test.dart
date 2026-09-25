import 'package:field_cases/features/templates/domain/case_template_variables.dart';
import 'package:field_cases/features/templates/domain/template_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TemplateEngine.render', () {
    test('replaces variables and leaves unknown ones empty', () {
      expect(
        TemplateEngine.render('بلاغ {{النوع}} في {{المكان}}{{غير_موجود}}.', {
          'النوع': 'حريق',
          'المكان': 'ينبع',
        }),
        'بلاغ حريق في ينبع.',
      );
    });

    test('sections show for truthy values and inverted for empty ones', () {
      const t = '{{#حريق}}يوجد حريق{{/حريق}}{{^حريق}}لا حريق{{/حريق}}';
      expect(TemplateEngine.render(t, {'حريق': true}), 'يوجد حريق');
      expect(TemplateEngine.render(t, {'حريق': false}), 'لا حريق');
      expect(TemplateEngine.render(t, {'حريق': 0}), 'لا حريق');
      expect(TemplateEngine.render(t, {'حريق': 3}), 'يوجد حريق');
      expect(TemplateEngine.render(t, {'حريق': '  '}), 'لا حريق');
      expect(TemplateEngine.render(t, {}), 'لا حريق');
    });

    test('nested sections', () {
      const t = '{{#أ}}أ{{#ب}} وب{{/ب}}{{/أ}}';
      expect(TemplateEngine.render(t, {'أ': 1, 'ب': 1}), 'أ وب');
      expect(TemplateEngine.render(t, {'أ': 1}), 'أ');
      expect(TemplateEngine.render(t, {'ب': 1}), '');
    });

    test('values are stringified in Arabic', () {
      expect(TemplateEngine.render('{{x}}', {'x': true}), 'نعم');
      expect(
        TemplateEngine.render('{{x}}', {
          'x': ['أ', 'ب'],
        }),
        'أ، ب',
      );
    });

    test('tolerates spaces inside tags', () {
      expect(TemplateEngine.render('{{ # x }}نعم{{ / x }}', {'x': 1}), 'نعم');
    });
  });

  group('TemplateEngine.cleanUp', () {
    test('fixes spacing and punctuation left by empty fields', () {
      expect(
        TemplateEngine.cleanUp('بلاغ  من   جهة ، في ينبع'),
        'بلاغ من جهة، في ينبع',
      );
      expect(TemplateEngine.cleanUp('أ،، ب، ، ج'), 'أ، ب، ج');
      expect(TemplateEngine.cleanUp('نهاية،.'), 'نهاية.');
      expect(TemplateEngine.cleanUp('، بداية'), 'بداية');
      expect(TemplateEngine.cleanUp('أضرار () هنا'), 'أضرار هنا');
      expect(TemplateEngine.cleanUp('الوقت 7:30 مساءً'), 'الوقت 7:30 مساءً');
    });
  });

  group('TemplateEngine.validate', () {
    const known = {'أ', 'ب'};

    test('accepts a well-formed template', () {
      expect(TemplateEngine.validate('{{أ}} {{#ب}}x{{/ب}}', known), isEmpty);
    });

    test('reports unknown variables and bad sections', () {
      final errors = TemplateEngine.validate('{{ج}} {{#أ}}x {{/ب}}', known);
      expect(errors, contains('متغير غير معروف: {{ج}}'));
      expect(errors, contains('إغلاق غير متوقع: {{/ب}}'));
      expect(errors, contains('قسم غير مغلق: {{#أ}} يحتاج {{/أ}}'));
    });
  });

  group('Arabic phrases', () {
    test('casualties phrase follows Arabic number agreement', () {
      String p(int i, int d) =>
          CaseTemplateVariables.casualtiesPhrase(injuries: i, deaths: d);
      expect(p(0, 0), 'دون تسجيل إصابات أو وفيات');
      expect(p(1, 0), 'ونتج عن ذلك إصابة واحدة');
      expect(p(2, 0), 'ونتج عن ذلك إصابتان');
      expect(p(5, 0), 'ونتج عن ذلك (5) إصابات');
      expect(p(12, 0), 'ونتج عن ذلك (12) إصابة');
      expect(p(0, 2), 'ونتج عن ذلك حالتا وفاة');
      expect(p(3, 1), 'ونتج عن ذلك (3) إصابات وحالة وفاة واحدة');
    });

    test('parties are joined with و', () {
      expect(
        CaseTemplateVariables.joinArabic([
          'الدفاع المدني',
          'الهلال الأحمر',
          'المرور',
        ]),
        'الدفاع المدني والهلال الأحمر والمرور',
      );
    });

    test('location phrase falls back to center or governorate', () {
      String l({String text = '', String? c, String? g}) =>
          CaseTemplateVariables.locationPhrase(
            locationText: text,
            center: c,
            governorate: g,
          );
      expect(l(text: 'جنوب مركز الرايس', c: 'مركز الرايس'), 'جنوب مركز الرايس');
      expect(l(c: 'مركز الرايس', g: 'بدر'), 'في مركز الرايس');
      expect(l(g: 'بدر'), 'بمحافظة بدر');
      expect(l(), '');
    });
  });
}
