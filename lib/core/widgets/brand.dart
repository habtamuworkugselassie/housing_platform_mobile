import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// The small brand primitives the web landing page is built from, so the app and the
/// site read as one product: an eyebrow pill with a gold dot, a section header with an
/// extrabold title, a deep-violet panel with the dotted texture and a gold glow, the gold
/// call-to-action pill, and the tier badge.

/// `• EYEBROW` pill. On light surfaces: violet-50 fill with violet text; on dark panels:
/// translucent white with white text. The dot is always gold.
class EyebrowPill extends StatelessWidget {
  final String text;
  final bool onDark;

  /// Opaque deep-violet fill for use over photos, where the translucent pill would wash out.
  final bool solid;

  const EyebrowPill(this.text, {Key? key, this.onDark = false, this.solid = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: solid
            ? AppTheme.brandDeep.withValues(alpha: 0.78)
            : (onDark ? Colors.white.withValues(alpha: 0.12) : AppTheme.violet50),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.18) : AppTheme.violet100,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.goldBright, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: onDark ? Colors.white : AppTheme.primaryColorDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eyebrow + extrabold title (+ optional subtitle), with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? action;
  final bool onDark;

  const SectionHeader({
    Key? key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.action,
    this.onDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppTheme.textPrimary;
    final bodyColor = onDark ? Colors.white.withValues(alpha: 0.78) : AppTheme.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                EyebrowPill(eyebrow!, onDark: onDark),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: titleColor),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: bodyColor, height: 1.45),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}

/// A rounded deep-violet panel: the home-page hero, the live banner, the stories card.
/// Carries the dotted texture and a gold glow in one corner like the web panels.
class BrandPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool glow;
  final BorderRadius? borderRadius;

  const BrandPanel({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppTheme.brandPanel,
    this.glow = true,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.radiusPanel);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: radius, boxShadow: AppTheme.panelShadow),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
            if (glow)
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppTheme.goldBright.withValues(alpha: 0.28), Colors.transparent],
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    const step = 18.0;
    for (double y = 6; y < size.height; y += step) {
      for (double x = 6; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The gold call-to-action pill (web: `bg-gold-400 text-primary-950`), with an arrow.
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;

  const GoldButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon = LucideIcons.arrowRight,
    this.expand = false,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.goldBright,
        foregroundColor: AppTheme.brandDeep,
        disabledBackgroundColor: AppTheme.goldBright.withValues(alpha: 0.6),
        disabledForegroundColor: AppTheme.brandDeep.withValues(alpha: 0.7),
        shadowColor: AppTheme.goldBright.withValues(alpha: 0.5),
        elevation: 6,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandDeep),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 16)],
              ],
            ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Small uppercase pill for a sponsorship tier or status: gold for Exclusive, violet otherwise.
class TierBadge extends StatelessWidget {
  final String label;
  final bool gold;

  const TierBadge(this.label, {Key? key, this.gold = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gold ? AppTheme.goldBright : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gold ? AppTheme.goldLight : Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: gold ? AppTheme.brandDeep : Colors.white,
        ),
      ),
    );
  }
}

/// `LIVE` pill with a pulsing red dot, used wherever a broadcast is flagged.
class LivePill extends StatelessWidget {
  const LivePill({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          SizedBox(width: 6),
          Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return SizedBox(
          width: 10,
          height: 10,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10 * (0.6 + t * 0.8),
                height: 10 * (0.6 + t * 0.8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF87171).withValues(alpha: (1 - t) * 0.6),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF87171)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A stat tile for panels: big number, small label (the hero's "5 days / Addis / Open").
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool onDark;

  const StatTile({Key? key, required this.value, required this.label, this.onDark = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: onDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: onDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
