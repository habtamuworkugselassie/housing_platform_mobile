import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/network/media_helper.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import 'organization_detail_screen.dart';

class OrganizationListScreen extends ConsumerStatefulWidget {
  final String organizationType;
  final String title;

  const OrganizationListScreen({
    Key? key,
    required this.organizationType,
    required this.title,
  }) : super(key: key);

  @override
  ConsumerState<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends ConsumerState<OrganizationListScreen> {
  List<OrganizationModel> _organizations = [];
  List<SupplierSubcategoryRef> _subcategories = [];
  String? _selectedSubcategoryId;
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
      final service = ref.read(organizationServiceProvider);
      List<SupplierSubcategoryRef> subs = [];
      if (widget.organizationType == 'SUPPLIER') {
        try {
          subs = await service.getSupplierSubcategoriesPublic();
        } catch (_) {}
      } else {
        _selectedSubcategoryId = null;
      }
      final list = await service.getMarketplaceOrganizations(
        widget.organizationType,
        subcategoryId: _selectedSubcategoryId,
      );
      if (mounted) {
        setState(() {
          _subcategories = subs;
          _organizations = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(widget.title),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.organizationType == 'SUPPLIER' && _subcategories.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: DropdownButtonFormField<String?>(
                            value: _selectedSubcategoryId,
                            decoration: InputDecoration(
                              labelText: 'Material type',
                              filled: true,
                              fillColor: AppTheme.surfaceColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All types'),
                              ),
                              ..._subcategories.map(
                                (s) => DropdownMenuItem<String?>(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedSubcategoryId = v);
                              _load();
                            },
                          ),
                        ),
                      Expanded(
                        child: _organizations.isEmpty
                            ? _emptyView()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _organizations.length,
                                itemBuilder: (context, index) =>
                                    _OrganizationTile(organization: _organizations[index]),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.building2, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No organizations in this category yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  final OrganizationModel organization;

  const _OrganizationTile({required this.organization});

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizationDetailScreen(organizationId: organization.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = mediaUrl(organization.logoUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _onTap(context),
        isThreeLine: organization.supplierSubcategories.isNotEmpty,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: logoUrl != null && logoUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  logoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderLogo(),
                ),
              )
            : _placeholderLogo(),
        title: Text(
          organization.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (organization.displayLocation.trim().isNotEmpty)
              Text(
                organization.displayLocation,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (organization.supplierSubcategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: organization.supplierSubcategories
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
        trailing: organization.verified
            ? const Icon(LucideIcons.badgeCheck, color: AppTheme.verifiedBadgeBlue, size: 20)
            : null,
      ),
    );
  }

  Widget _placeholderLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        organization.name.isNotEmpty ? organization.name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
