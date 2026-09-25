import 'package:flutter/material.dart';

/// مفتاح نعم/لا مع عداد اختياري (للإصابات والوفيات).
class YesNoCountTile extends StatelessWidget {
  const YesNoCountTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.count,
    this.onCountChanged,
    this.icon,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final int? count;
  final ValueChanged<int>? onCountChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final showCounter = value && count != null && onCountChanged != null;
    return Column(
      children: [
        SwitchListTile(
          secondary: icon == null ? null : Icon(icon),
          title: Text(title),
          subtitle: Text(value ? 'نعم' : 'لا'),
          value: value,
          onChanged: onChanged,
        ),
        if (showCounter)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text('العدد'),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'إنقاص',
                  iconSize: 28,
                  onPressed: count! > 1
                      ? () => onCountChanged!(count! - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'زيادة',
                  iconSize: 28,
                  onPressed: () => onCountChanged!(count! + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
