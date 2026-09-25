import 'package:field_cases/core/utils/arabic_format.dart';
import 'package:field_cases/features/cases/domain/case_content_hasher.dart';
import 'package:field_cases/features/cases/domain/case_enums.dart';
import 'package:field_cases/features/cases/domain/case_form_data.dart';
import 'package:field_cases/features/cases/domain/case_form_validator.dart';
import 'package:field_cases/features/cases/domain/case_type_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 25, 19, 30);

  CaseFormData complete() => CaseFormData(
    caseTypeId: 't',
    occurredAt: now,
    governorateId: 'g',
    locationText: 'جنوب مركز الرايس',
    reportSourceId: 's',
  );

  group('CaseFormValidator', () {
    test('draft only needs a case type', () {
      final errors = CaseFormValidator.validate(
        CaseFormData(caseTypeId: 't', occurredAt: now),
        targetStatus: CaseStatus.draft,
        now: now,
      );
      expect(errors, isEmpty);
    });

    test('completed needs governorate, place and source', () {
      final errors = CaseFormValidator.validate(
        CaseFormData(caseTypeId: 't', occurredAt: now),
        targetStatus: CaseStatus.completed,
        now: now,
      );
      expect(errors.map((e) => e.message), [
        'اختر المحافظة',
        'حدد المركز أو اكتب الموقع',
        'اختر مصدر البلاغ',
      ]);
      expect(errors.every((e) => e.step == CaseFormStep.basics), isTrue);
    });

    test('missing type points back to the type step', () {
      final errors = CaseFormValidator.validate(
        CaseFormData(occurredAt: now),
        targetStatus: CaseStatus.draft,
        now: now,
      );
      expect(errors.single.step, CaseFormStep.type);
    });

    test('future time is rejected', () {
      final errors = CaseFormValidator.validate(
        complete()..occurredAt = now.add(const Duration(hours: 1)),
        targetStatus: CaseStatus.draft,
        now: now,
      );
      expect(errors.single.message, contains('المستقبل'));
    });

    test('required dynamic fields and damage description', () {
      const field = CaseTypeFieldDef(
        fieldKey: 'object_state',
        label: 'حالة الجسم',
        inputType: FieldInputType.select,
        isRequired: true,
      );
      final errors = CaseFormValidator.validate(
        complete()..hasDamage = true,
        targetStatus: CaseStatus.completed,
        fields: const [field],
        now: now,
      );
      expect(errors.map((e) => e.message), [
        'أكمل حقل "حالة الجسم"',
        'اكتب وصف الأضرار',
      ]);
    });

    test('boolean "no" satisfies a required boolean field', () {
      const field = CaseTypeFieldDef(
        fieldKey: 'has_fire',
        label: 'وجود حريق',
        inputType: FieldInputType.boolean,
        isRequired: true,
      );
      final errors = CaseFormValidator.validate(
        complete()..extraFields['has_fire'] = false,
        targetStatus: CaseStatus.completed,
        fields: const [field],
        now: now,
      );
      expect(errors, isEmpty);
    });
  });

  group('CaseContentHasher', () {
    test('is stable regardless of set and map ordering', () {
      final a = complete()
        ..partyIds.addAll(['p1', 'p2'])
        ..extraFields.addAll({'a': 1, 'b': true});
      final b = complete()
        ..partyIds.addAll(['p2', 'p1'])
        ..extraFields.addAll({'b': true, 'a': 1});
      expect(CaseContentHasher.hash(a), CaseContentHasher.hash(b));
    });

    test('ignores surrounding whitespace but detects real changes', () {
      final base = CaseContentHasher.hash(complete());
      expect(
        CaseContentHasher.hash(complete()..locationText = ' جنوب مركز الرايس '),
        base,
      );
      expect(
        CaseContentHasher.hash(complete()..locationText = 'شمال مركز الرايس'),
        isNot(base),
      );
    });

    test('injury count only matters when injuries are reported', () {
      final base = CaseContentHasher.hash(complete());
      expect(CaseContentHasher.hash(complete()..injuriesCount = 3), base);
      expect(
        CaseContentHasher.hash(
          complete()
            ..hasInjuries = true
            ..injuriesCount = 3,
        ),
        isNot(base),
      );
    });
  });

  group('ArabicFormat', () {
    test('formats time and date for field reports', () {
      expect(ArabicFormat.time(DateTime(2026, 9, 25, 19, 30)), '7:30 مساءً');
      expect(ArabicFormat.time(DateTime(2026, 9, 25, 0, 5)), '12:05 صباحًا');
      expect(ArabicFormat.time24(DateTime(2026, 9, 25, 14, 35)), '14:35');
      expect(ArabicFormat.date(DateTime(2026, 9, 1)), '01/09/2026');
      expect(
        ArabicFormat.weekdayDate(DateTime(2026, 9, 25)),
        'الجمعة 25/09/2026',
      );
    });
  });
}
