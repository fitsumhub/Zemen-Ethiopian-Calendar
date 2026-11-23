import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../../../core/calendar/geez_numeral.dart';

class GeezNumeralsTab extends StatefulWidget {
  const GeezNumeralsTab({super.key});

  @override
  State<GeezNumeralsTab> createState() => _GeezNumeralsTabState();
}

class _GeezNumeralsTabState extends State<GeezNumeralsTab> {
  int _currentNumber = 2017;
  final TextEditingController _controller = TextEditingController(text: '2017');

  void _updateNumber(int val) {
    final clamped = val.clamp(1, 999999);
    setState(() {
      _currentNumber = clamped;
      _controller.text = '$clamped';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final geezString = GeezNumeral.toGeez(_currentNumber);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Live Output Display Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('የግዕዝ ቁጥር (Ge\'ez Numeral):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  geezString,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'የአረብኛ ቁጥር (Arabic): $_currentNumber',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('ኮፒ (Copy)'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: geezString));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$geezString ኮፒ ተደርጓል')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Input Field & Stepper Controls
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ቁጥር ያስገቡ (Enter Number)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    setState(() => _currentNumber = parsed.clamp(1, 999999));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.remove),
              onPressed: () => _updateNumber(_currentNumber - 1),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: () => _updateNumber(_currentNumber + 1),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick Steppers Wrap
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ActionChip(label: const Text('+1'), onPressed: () => _updateNumber(_currentNumber + 1)),
            ActionChip(label: const Text('+5'), onPressed: () => _updateNumber(_currentNumber + 5)),
            ActionChip(label: const Text('+10'), onPressed: () => _updateNumber(_currentNumber + 10)),
            ActionChip(label: const Text('+100'), onPressed: () => _updateNumber(_currentNumber + 100)),
            ActionChip(label: const Text('+1,000'), onPressed: () => _updateNumber(_currentNumber + 1000)),
            ActionChip(label: const Text('2017 (ዘንድሮ)'), onPressed: () => _updateNumber(2017)),
            ActionChip(label: const Text('አጽዳ (Clear)'), onPressed: () => _updateNumber(1)),
          ],
        ),
        const SizedBox(height: 20),

        // Reference Chart Table
        const Text('የግዕዝ አኃዛት ማመሳከሪያ ሠንጠረዥ (Reference Table):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),

        // Units 1 to 9
        const Text('አሃዞች (Units 1 - 9):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: List.generate(9, (i) {
            final num = i + 1;
            final geez = GeezNumeral.toGeez(num);
            return _GeezCell(geez: geez, arabic: '$num', onTap: () => _updateNumber(num));
          }),
        ),
        const SizedBox(height: 14),

        // Tens 10 to 90
        const Text('አስሮች (Tens 10 - 90):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: List.generate(9, (i) {
            final num = (i + 1) * 10;
            final geez = GeezNumeral.toGeez(num);
            return _GeezCell(geez: geez, arabic: '$num', onTap: () => _updateNumber(num));
          }),
        ),
        const SizedBox(height: 14),

        // Hundreds & Thousands
        const Text('መቶዎች እና ሺዎች (Hundreds & Thousands):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _GeezCell(geez: '፻', arabic: '100', onTap: () => _updateNumber(100))),
            const SizedBox(width: 8),
            Expanded(child: _GeezCell(geez: '፲፻', arabic: '1,000', onTap: () => _updateNumber(1000))),
            const SizedBox(width: 8),
            Expanded(child: _GeezCell(geez: '፼', arabic: '10,000', onTap: () => _updateNumber(10000))),
          ],
        ),
      ],
    );
  }
}

class _GeezCell extends StatelessWidget {
  final String geez;
  final String arabic;
  final VoidCallback onTap;

  const _GeezCell({required this.geez, required this.arabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(geez, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text(arabic, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
