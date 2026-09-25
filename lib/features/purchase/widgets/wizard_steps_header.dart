import 'package:flutter/material.dart';

import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';

/// Progress chips for the wizard. Backwards is always allowed; forwards only across valid steps.
class WizardStepsHeader extends StatelessWidget {
  final PurchaseFormState form;
  final ValueChanged<WizardStep> onSelect;

  const WizardStepsHeader({super.key, required this.form, required this.onSelect});

  static String label(WizardStep s) => const {
        WizardStep.account: 'Account',
        WizardStep.contact: 'Contact',
        WizardStep.financing: 'Financing',
        WizardStep.payment: 'Payment',
        WizardStep.agreement: 'Agreement',
        WizardStep.review: 'Review',
      }[s]!;

  bool _canJump(int index) {
    final current = form.stepIndex;
    if (index <= current) return form.steps[index] != WizardStep.account || form.needsAccount;
    for (var i = 0; i < index; i++) {
      if (!form.isStepValid(form.steps[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final steps = form.steps;
    final current = form.stepIndex;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _Chip(
              index: i,
              label: label(steps[i]),
              done: i < current,
              active: i == current,
              enabled: _canJump(i),
              onTap: () => onSelect(steps[i]),
            ),
            if (i < steps.length - 1) Container(width: 16, height: 1, color: AppTheme.borderColor),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _Chip({required this.index, required this.label, required this.done, required this.active, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primaryColor : done ? AppTheme.success : AppTheme.textMuted;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppTheme.primaryColorLight : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppTheme.primaryColor : done ? AppTheme.textPrimary : AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
