import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/purchase_model.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/financing_math.dart';
import '../widgets/purchase_status_badge.dart';
import 'purchase_order_detail_screen.dart';

class MyPurchaseOrdersScreen extends ConsumerStatefulWidget {
  const MyPurchaseOrdersScreen({super.key});

  @override
  ConsumerState<MyPurchaseOrdersScreen> createState() => _MyPurchaseOrdersScreenState();
}

class _MyPurchaseOrdersScreenState extends ConsumerState<MyPurchaseOrdersScreen> {
  List<PurchaseOrder> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(purchaseServiceProvider).mine();
      if (mounted) setState(() => _orders = page.content);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Could not load purchase orders.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My purchase orders'), backgroundColor: Colors.white, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, style: const TextStyle(color: AppTheme.error)), TextButton(onPressed: _load, child: const Text('Try again'))]))
              : _orders.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('You have not placed any purchase orders yet.', style: TextStyle(color: AppTheme.textSecondary))))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PurchaseOrderDetailScreen(orderId: o.id)));
                              _load();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
                              child: Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(o.orderNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                                    Text(o.propertyTitle ?? 'Property', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                                    Text('${FinancingMath.formatMoney(o.listedPrice, currency: o.currency)} · ${PurchaseOrderLabels.purchaseType(o.purchaseType)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ]),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  PurchaseStatusBadge(o.status),
                                  if (o.pendingSignatures > 0)
                                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('${o.pendingSignatures} to sign', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600))),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
