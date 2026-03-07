import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/models/property_model.dart';
import '../../../core/network/media_helper.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/property_provider.dart';
import '../../../core/theme/theme.dart';
import '../widgets/property_card.dart';
import '../../property/screens/property_detail_screen.dart';

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  final String organizationId;

  const OrganizationDetailScreen({Key? key, required this.organizationId}) : super(key: key);

  @override
  ConsumerState<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends ConsumerState<OrganizationDetailScreen> {
  OrganizationModel? _organization;
  List<PropertyModel> _properties = [];
  bool _loading = true;
  String? _error;
  int _mediaIndex = 0;

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
      final orgService = ref.read(organizationServiceProvider);
      final propService = ref.read(propertyServiceProvider);
      final org = await orgService.getOrganizationById(widget.organizationId);
      List<PropertyModel> props = [];
      try {
        props = await propService.getPropertiesByOrganization(widget.organizationId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _organization = org;
          _properties = props;
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

  List<OrganizationMediaItem> get _galleryMedia {
    final media = _organization?.media ?? [];
    if (media.isEmpty && _organization?.logoUrl != null) {
      return [OrganizationMediaItem(url: _organization!.logoUrl, mediaKind: 'IMAGE')];
    }
    return media;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Organization'), backgroundColor: AppTheme.scaffoldBackgroundColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _organization == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Organization'), backgroundColor: AppTheme.scaffoldBackgroundColor),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(_error ?? 'Failed to load', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextButton.icon(onPressed: _load, icon: const Icon(LucideIcons.refreshCw, size: 18), label: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final org = _organization!;
    final mediaList = _galleryMedia;
    final currentMedia = _mediaIndex < mediaList.length ? mediaList[_mediaIndex] : null;
    final currentMediaUrl = currentMedia?.url != null ? mediaUrl(currentMedia!.url) : null;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(org.name, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero / media
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (currentMediaUrl != null && currentMediaUrl.isNotEmpty)
                      Image.network(
                        currentMediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderMedia(org),
                      )
                    else
                      _placeholderMedia(org),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                          ),
                        ),
                        child: Row(
                          children: [
                            if (org.logoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  mediaUrl(org.logoUrl)!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    org.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (org.displayLocation.trim().isNotEmpty)
                                    Text(
                                      org.displayLocation,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (mediaList.length > 1)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(mediaList.length, (i) {
                            return GestureDetector(
                              onTap: () => setState(() => _mediaIndex = i),
                              child: Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 32,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _mediaIndex == i ? AppTheme.primaryColor : Colors.white24),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: mediaList[i].url != null
                                      ? Image.network(mediaUrl(mediaList[i].url)!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    org.description?.trim().isNotEmpty == true ? org.description! : 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Contact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (org.email != null && org.email!.trim().isNotEmpty)
                    _ContactRow(
                      icon: LucideIcons.mail,
                      label: 'Email',
                      value: org.email!,
                      onTap: () => launchUrl(Uri.parse('mailto:${org.email}')),
                    ),
                  if (org.phoneNumbers != null && org.phoneNumbers!.isNotEmpty)
                    ...org.phoneNumbers!.map((p) => _ContactRow(icon: LucideIcons.phone, label: 'Phone', value: p.display)),
                  if (org.website != null && org.website!.trim().isNotEmpty)
                    _ContactRow(
                      icon: LucideIcons.globe,
                      label: 'Website',
                      value: org.website!,
                      onTap: () => launchUrl(Uri.parse(org.website!.startsWith('http') ? org.website! : 'https://${org.website}')),
                    ),
                  if ((org.email?.trim().isEmpty ?? true) && (org.phoneNumbers == null || org.phoneNumbers!.isEmpty) && (org.website?.trim().isEmpty ?? true))
                    Text('No contact information available.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Properties
            if (_properties.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Properties (${_properties.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _properties.length,
                itemBuilder: (context, index) {
                  final prop = _properties[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PropertyCard(
                      property: prop,
                      isHorizontal: false,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: prop)),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _placeholderMedia(OrganizationModel org) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(org.name, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  color: onTap != null ? AppTheme.primaryColor : AppTheme.textPrimary,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
