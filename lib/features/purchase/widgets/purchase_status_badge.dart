import 'package:flutter/material.dart';

import '../../../core/models/purchase_model.dart';
import '../../../core/theme/theme.dart';

class PurchaseStatusBadge extends StatelessWidget {
  final String status;
  const PurchaseStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'COMPLETED':
      case 'FINANCING_APPROVED':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case 'AWAITING_PAYMENT':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'FINANCING_PARTIALLY_APPROVED':
      case 'FINANCING_REJECTED':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'CANCELLED':
      case 'REJECTED':
      case 'EXPIRED':
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF374151);
        break;
      default:
        bg = AppTheme.surfaceMuted;
        fg = AppTheme.primaryColorDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(PurchaseOrderLabels.status(status), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
