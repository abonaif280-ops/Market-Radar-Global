import 'package:flutter/material.dart';

import '../../../../../core/db/seed_data.dart';
import '../../../../../core/utils/arabic_format.dart';
import '../../../domain/case_form_data.dart';
import '../../widgets/lookup_dropdown.dart';

/// الخطوة 2: الوقت والمكان ومصدر البلاغ.
class BasicsStep extends StatelessWidget {
  const BasicsStep({super.key, required this.data, required this.onChanged});

  final CaseFormData data;

  /// يُستدعى بعد أي تعديل على [data] لإعادة الرسم.
  final VoidCallback onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: data.occurredAt,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) return;
    final t = data.occurredAt;
    data.occurredAt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      t.hour,
      t.minute,
    );
    onChanged();
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(data.occurredAt),
    );
    if (picked == null) return;
    final d = data.occurredAt;
    data.occurredAt = DateTime(
      d.year,
      d.month,
      d.day,
      picked.hour,
      picked.minute,
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                icon: Icons.calendar_today,
                label: 'التاريخ',
                value: ArabicFormat.date(data.occurredAt),
                onTap: () => _pickDate(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerTile(
                icon: Icons.schedule,
                label: 'الوقت',
                value: ArabicFormat.time(data.occurredAt),
                onTap: () => _pickTime(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LookupDropdown(
          listKey: LookupKeys.reportSource,
          label: 'مصدر البلاغ *',
          icon: Icons.call_received,
          value: data.reportSourceId,
          onChanged: (id) {
            data.reportSourceId = id;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        LookupDropdown(
          listKey: LookupKeys.governorate,
          label: 'المحافظة *',
          icon: Icons.location_city,
          value: data.governorateId,
          onChanged: (id) {
            data.changeGovernorate(id);
            onChanged();
          },
        ),
        if (data.governorateId != null) ...[
          const SizedBox(height: 16),
          LookupDropdown(
            listKey: LookupKeys.center,
            parentId: data.governorateId,
            label: 'المركز',
            icon: Icons.apartment,
            allowClear: true,
            value: data.centerId,
            onChanged: (id) {
              data.centerId = id;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.locationText,
          decoration: const InputDecoration(
            labelText: 'الموقع',
            hintText: 'مثال: جنوب مركز الرايس',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onChanged: (v) {
            data.locationText = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.locationDescription,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'وصف الموقع',
            prefixIcon: Icon(Icons.notes),
          ),
          onChanged: (v) => data.locationDescription = v,
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
