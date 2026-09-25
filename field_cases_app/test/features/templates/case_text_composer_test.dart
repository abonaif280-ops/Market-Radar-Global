import 'package:drift/native.dart';
import 'package:field_cases/core/db/app_database.dart';
import 'package:field_cases/core/db/seed_data.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/settings/data/lookup_repository.dart';
import 'package:field_cases/features/templates/data/case_text_composer.dart';
import 'package:field_cases/features/templates/data/template_repository.dart';
import 'package:field_cases/features/templates/domain/default_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CaseTextComposer composer;
  late TemplateRepository templates;

  String id(String key, String code) => lookupId(key, code);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    templates = TemplateRepository(db);
    composer = CaseTextComposer(
      lookups: LookupRepository(db),
      templates: templates,
    );
  });
  tearDown(() => db.close());

  /// المثال المعتمد في المتطلبات (البند 9).
  CaseFormData requirementsExample() => CaseFormData(
    caseTypeId: id(LookupKeys.caseType, 'SOLID_OBJECT'),
    occurredAt: DateTime(2026, 9, 25, 19, 30),
    governorateId: id(LookupKeys.governorate, 'BADR'),
    centerId: id(LookupKeys.center, 'RAYES'),
    locationText: 'جنوب مركز الرايس',
    reportSourceId: id(LookupKeys.reportSource, '911'),
    extraFields: {'object_state': 'أجزاء من جسم صلب', 'has_fire': true},
    partyIds: {id(LookupKeys.party, 'EOD'), id(LookupKeys.party, 'CIVIL_DEF')},
  );

  test('reproduces the requirements example for a solid object', () async {
    expect(
      await composer.compose(requirementsExample()),
      'عند الساعة 7:30 مساءً ورد بلاغ من العمليات الموحدة (911) عن العثور على '
      'جسم صلب جنوب مركز الرايس، وبالانتقال للموقع اتضح وجود أجزاء من جسم صلب '
      'تنبعث منها نيران، دون تسجيل إصابات أو وفيات، وجرى إبلاغ الدفاع المدني '
      'وإدارة الأسلحة والمتفجرات لإكمال اللازم كل فيما يخصه.',
    );
  });

  test('injuries, damage and action are woven into the text', () async {
    final data = requirementsExample()
      ..extraFields.remove('has_fire')
      ..hasInjuries = true
      ..injuriesCount = 2
      ..hasDamage = true
      ..damageDescription = 'تضرر سيارة'
      ..actionTaken = 'وتم تطويق الموقع';
    expect(
      await composer.compose(data),
      'عند الساعة 7:30 مساءً ورد بلاغ من العمليات الموحدة (911) عن العثور على '
      'جسم صلب جنوب مركز الرايس، وبالانتقال للموقع اتضح وجود أجزاء من جسم صلب، '
      'ونتج عن ذلك إصابتان، مع وجود أضرار (تضرر سيارة)، وتم تطويق الموقع، '
      'وجرى إبلاغ الدفاع المدني وإدارة الأسلحة والمتفجرات لإكمال اللازم كل فيما يخصه.',
    );
  });

  test('a sparse draft still reads cleanly', () async {
    final data = CaseFormData(
      caseTypeId: id(LookupKeys.caseType, 'SECURITY_CASE'),
      occurredAt: DateTime(2026, 9, 25, 9, 5),
      governorateId: id(LookupKeys.governorate, 'YNB'),
    );
    expect(
      await composer.compose(data),
      'عند الساعة 9:05 صباحًا ورد بلاغ عن حالة أمنية بمحافظة ينبع، '
      'دون تسجيل إصابات أو وفيات.',
    );
  });

  test('fire and drone templates use their own fields', () async {
    final fire = CaseFormData(
      caseTypeId: id(LookupKeys.caseType, 'FIRE'),
      occurredAt: DateTime(2026, 9, 25, 22, 0),
      centerId: id(LookupKeys.center, 'RAYES'),
      reportSourceId: id(LookupKeys.reportSource, 'PATROL'),
      extraFields: {'fire_size': 'محدود', 'fire_controlled': true},
      hasDeaths: true,
      deathsCount: 1,
    );
    expect(
      await composer.compose(fire),
      'عند الساعة 10:00 مساءً ورد بلاغ من دورية ميدانية عن نشوب حريق محدود '
      'في مركز الرايس، وتمت السيطرة عليه، ونتج عن ذلك حالة وفاة واحدة.',
    );

    final drone = CaseFormData(
      caseTypeId: id(LookupKeys.caseType, 'DRONE'),
      occurredAt: DateTime(2026, 9, 25, 13, 15),
      locationText: 'شمال طريق الهجرة',
      extraFields: {'drone_state': 'محطمة'},
      partyIds: {id(LookupKeys.party, 'EOD')},
    );
    expect(
      await composer.compose(drone),
      'عند الساعة 1:15 مساءً ورد بلاغ عن سقوط طائرة مسيرة شمال طريق الهجرة، '
      'وبالانتقال للموقع اتضح أنها محطمة، دون تسجيل إصابات أو وفيات، وجرى إبلاغ '
      'إدارة الأسلحة والمتفجرات لإكمال اللازم كل فيما يخصه.',
    );
  });

  test('edited template is used and default can be restored', () async {
    final data = requirementsExample();
    final template = (await templates.templateFor(data.caseTypeId))!;
    expect(template.id, DefaultTemplates.idFor('SOLID_OBJECT'));

    await templates.updateBody(
      template.id,
      'بلاغ {{نوع_الحالة}} الساعة {{الوقت}}',
    );
    expect(await composer.compose(data), 'بلاغ جسم صلب الساعة 7:30 مساءً');

    final updated = (await templates.byId(template.id))!;
    await templates.updateBody(template.id, templates.defaultBodyFor(updated)!);
    expect(await composer.compose(data), startsWith('عند الساعة 7:30 مساءً'));
  });

  test(
    'types without their own template fall back to the generic one',
    () async {
      final t = await templates.templateFor(id(LookupKeys.caseType, 'OTHER'));
      expect(t!.id, DefaultTemplates.genericId);
    },
  );
}
