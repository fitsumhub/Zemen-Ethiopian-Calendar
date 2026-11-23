import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand/brand.dart';
import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/geez_numeral.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/preferences/user_preferences_repository.dart';
import '../shared/components/ethiocal_logo.dart';
import '../shared/providers.dart';

// ---------------------------------------------------------------------------
// Dynamic Theme Tokens & Scope
// ---------------------------------------------------------------------------
class _DynamicTok {
  final AppThemePreset preset;

  const _DynamicTok(this.preset);

  Color get accent => preset.primaryColor;
  Color get accentLight => preset.accentGlow;
  Color get accentDeep => preset.accentDeep;
  Color get borderHi => preset.primaryColor.withValues(alpha: 0.35);
  Color get secondary => preset.secondaryColor;
}

class _ThemeTokScope extends InheritedWidget {
  final _DynamicTok tok;
  final AppThemePreset preset;

  const _ThemeTokScope({
    required this.tok,
    required this.preset,
    required super.child,
  });

  static _ThemeTokScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ThemeTokScope>();
    if (scope == null) {
      final defaultPreset = AppTheme.getPreset(AppTheme.defaultPaletteId);
      return _ThemeTokScope(
        tok: _DynamicTok(defaultPreset),
        preset: defaultPreset,
        child: const SizedBox.shrink(),
      );
    }
    return scope;
  }

  @override
  bool updateShouldNotify(_ThemeTokScope oldWidget) =>
      oldWidget.preset.id != preset.id;
}

// ---------------------------------------------------------------------------
// Design tokens (base canvas & text constants)
// ---------------------------------------------------------------------------
class _Tok {
  static Color get bg => AppColors.darkBg;
  static Color get bgTop => AppColors.canvas;
  static Color get surface => AppColors.darkCard;
  static Color get surfaceHi => AppColors.darkCardElevated;
  static Color get border => AppColors.darkBorder;
  static final borderHi = Color(0x33DE4A4A);
  static Color get accent => AppColors.accent;
  static final emerald = Color(0xFF1FA87A);
  static Color get text => AppColors.darkTextHigh;
  static Color get textMuted => AppColors.darkTextMed;
  static Color get textFaint => AppColors.darkTextLow;
}

const _gregMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 4;

  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _pageCount - 1) {
      _goTo(_page + 1);
    } else {
      _complete();
    }
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    ref.read(userSettingsProvider.notifier).setOnboardingCompleted(true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    final settings = ref.watch(userSettingsProvider);
    final currentPreset = AppTheme.getPreset(settings.accentPalette);
    final tok = _DynamicTok(currentPreset);

    return _ThemeTokScope(
      tok: tok,
      preset: currentPreset,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _Tok.bg,
          body: Stack(
            children: [
              Positioned.fill(child: _AmbientBackground()),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      page: _page,
                      pageCount: _pageCount,
                      onBack: _page > 0 ? () => _goTo(_page - 1) : null,
                      onSkip: isLast ? null : _complete,
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (p) => setState(() => _page = p),
                        children: [
                          _ThemeSelectionPage(active: _page == 0),
                          _FeaturesPage(active: _page == 1),
                          _PersonalizePage(active: _page == 2),
                          _PreferencesPage(active: _page == 3),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: _PrimaryButton(
                        label: isLast ? 'ጀምር  ·  Get started' : 'ቀጣይ  ·  Continue',
                        icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome: top bar, progress, primary button, background
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final int page;
  final int pageCount;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const _TopBar({required this.page, required this.pageCount, required this.onBack, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedOpacity(
                      opacity: onBack != null ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: onBack == null,
                        child: _CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onTap: onBack ?? () {},
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EthioCalLogo(size: 24),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          Brand.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _Tok.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: onSkip != null ? 1 : 0,
                      duration: Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: onSkip == null,
                        child: TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: _Tok.textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 40),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ዝለል · Skip',
                              maxLines: 1,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _SegmentedProgress(current: page, count: pageCount),
          ),
        ],
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  final int current;
  final int count;

  const _SegmentedProgress({required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return Semantics(
      label: 'Step ${current + 1} of $count',
      child: Row(
        children: List.generate(count, (i) {
          final filled = i <= current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Container(height: 4, color: Colors.white.withValues(alpha: 0.10)),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      widthFactor: filled ? 1 : 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [tok.accentDeep, tok.accentLight]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        shape: CircleBorder(side: BorderSide(color: _Tok.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: _Tok.text)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return Semantics(
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tok.accentLight, tok.accent, tok.accentDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: tok.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Row(
                  key: ValueKey(label),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(icon, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deep ink canvas with soft dynamic theme light pools and faint
/// concentric "sun" rings – a quiet nod to the 13 months of sunshine.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Tok.bgTop, _Tok.bg, _Tok.bg],
          stops: [0, 0.45, 1],
        ),
      ),
      child: CustomPaint(
        painter: _AmbientPainter(
          primaryColor: tok.accent,
          secondaryColor: tok.secondary,
          glowColor: tok.accentLight,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;

  const _AmbientPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset c, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    glow(Offset(size.width * 0.85, size.height * 0.08), size.width * 0.75, primaryColor.withValues(alpha: 0.12));
    glow(Offset(size.width * 0.05, size.height * 0.62), size.width * 0.7, secondaryColor.withValues(alpha: 0.08));

    final ringCenter = Offset(size.width * 0.5, size.height * 0.24);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 5; i++) {
      ring.color = Colors.white.withValues(alpha: 0.035 - i * 0.005);
      canvas.drawCircle(ringCenter, 70.0 + i * 46, ring);
    }

    // 13 faint rays
    final ray = Paint()
      ..color = primaryColor.withValues(alpha: 0.06)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 13; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / 13);
      final p1 = ringCenter + Offset(math.cos(a), math.sin(a)) * 120;
      final p2 = ringCenter + Offset(math.cos(a), math.sin(a)) * 300;
      canvas.drawLine(p1, p2, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.glowColor != glowColor;
}

// ---------------------------------------------------------------------------
// Entrance animation: fades + rises children when their page becomes active.
// One-shot (never repeats) so it settles in tests and respects reduced motion.
// ---------------------------------------------------------------------------
class _Reveal extends StatefulWidget {
  final bool active;
  final int order;
  final Widget child;

  const _Reveal({required this.active, required this.order, required this.child});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 520 + widget.order * 70),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    final start = (widget.order * 70) / (520 + widget.order * 70);
    final curved = CurvedAnimation(
      parent: _c,
      curve: Interval(start.clamp(0.0, 0.9), 1, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(offset: Offset(0, (1 - curved.value) * 18), child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared page layout pieces
// ---------------------------------------------------------------------------

class _PageScaffold extends StatelessWidget {
  final List<Widget> children;

  const _PageScaffold({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: tok.accent, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.6),
    );
  }
}

class _Heading extends StatelessWidget {
  final String amharic;
  final String english;
  final String? body;
  final TextAlign align;

  const _Heading({required this.amharic, required this.english, this.body, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    final cross = align == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(
          amharic,
          textAlign: align,
          style: TextStyle(
            color: _Tok.text,
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          english,
          textAlign: align,
          style: TextStyle(color: _Tok.textMuted, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (body != null) ...[
          SizedBox(height: 14),
          Text(
            body!,
            textAlign: align,
            style: TextStyle(color: _Tok.textMuted, fontSize: 13.5, height: 1.55),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String amharic;
  final String english;

  const _SectionLabel(this.amharic, this.english);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            amharic,
            style: TextStyle(color: _Tok.text, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              english,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _Tok.textFaint, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _Tok.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Tok.border),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 – Dynamic Themes (User chooses theme first in onboarding)
// ---------------------------------------------------------------------------

class _ThemeSelectionPage extends ConsumerWidget {
  final bool active;

  const _ThemeSelectionPage({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentAppLanguageProvider);
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);
    final tok = _ThemeTokScope.of(context).tok;
    final currentPreset = _ThemeTokScope.of(context).preset;

    final eth = EthiopianCalendarEngine.todayEthiopian();
    final greg = EthiopianCalendarEngine.todayGregorian();
    final weekday = LocaleStrings.getWeekdayLong(EthiopianCalendarEngine.getDayOfWeek(eth), lang);
    final day = settings.numeralType == 'GEEZ' ? GeezNumeral.toGeez(eth.day) : '${eth.day}';
    final year = settings.numeralType == 'GEEZ' ? GeezNumeral.toGeez(eth.year) : '${eth.year}';

    return _PageScaffold(
      children: [
        _Reveal(
          active: active,
          order: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tok.accent.withValues(alpha: 0.32),
                    blurRadius: 44,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const EthioCalLogo(size: 104),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Reveal(
          active: active,
          order: 1,
          child: Center(child: _Eyebrow('የኢትዮጵያ ዘመን አቆጣጠር · STEP 1 OF 4')),
        ),
        const SizedBox(height: 8),
        _Reveal(
          active: active,
          order: 2,
          child: _Heading(
            amharic: 'የገጽታ ቀለምዎን ይምረጡ',
            english: 'Choose Your Dynamic Theme',
            body: 'Welcome to ZEMEN. Pick your favorite heritage theme first. The calendar, widgets, and entire experience will dynamically adapt.',
            align: TextAlign.center,
          ),
        ),
        SizedBox(height: 20),
        // Live Date & Theme Preview Card
        _Reveal(
          active: active,
          order: 3,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 240),
            padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: _Tok.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tok.borderHi, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: tok.accent.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tok.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: tok.accent, blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ዛሬ · TODAY',
                          style: TextStyle(
                            color: _Tok.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tok.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tok.borderHi),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(currentPreset.icon, size: 12, color: tok.accent),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                currentPreset.nameEnglish,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tok.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 240),
                      style: TextStyle(
                        color: tok.accent,
                        fontSize: 48,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                      ),
                      child: Text(day),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${LocaleStrings.getMonthName(eth.month, lang)} $year',
                            style: TextStyle(
                              color: _Tok.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            weekday,
                            style: TextStyle(
                              color: _Tok.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: _Tok.border),
                ),
                Row(
                  children: [
                    Icon(Icons.public_rounded, size: 15, color: tok.accent.withValues(alpha: 0.8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_gregMonths[greg.month - 1]} ${greg.day}, ${greg.year} G.C.  ·  ${currentPreset.subtitleEnglish}',
                        style: TextStyle(
                          color: _Tok.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Reveal(
          active: active,
          order: 4,
          child: _SectionLabel('የገጽታ አማራጮች', '5 Dynamic Themes'),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < AppTheme.presets.length; i++) ...[
          _Reveal(
            active: active,
            order: 5 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ThemePresetCard(
                preset: AppTheme.presets[i],
                selected: settings.accentPalette == AppTheme.presets[i].id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setAccentPalette(AppTheme.presets[i].id);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.nameEnglish} theme, ${preset.subtitleEnglish}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? preset.primaryColor.withValues(alpha: 0.13)
                  : _Tok.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? preset.primaryColor
                    : _Tok.border.withValues(alpha: 0.8),
                width: selected ? 1.8 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: preset.primaryColor.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Theme icon + swatches
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: preset.primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: preset.primaryColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      preset.icon,
                      size: 22,
                      color: preset.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 14),
                // Titles and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              preset.nameAmharic,
                              style: TextStyle(
                                color: selected ? preset.primaryColor : _Tok.text,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '· ${preset.nameEnglish}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? preset.primaryColor.withValues(alpha: 0.85)
                                    : _Tok.textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        preset.subtitleAmharic,
                        style: TextStyle(
                          color: _Tok.textFaint,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      // 3-dot color swatch preview
                      Row(
                        children: [
                          _ColorDot(color: preset.primaryColor, size: 9),
                          SizedBox(width: 4),
                          _ColorDot(color: preset.secondaryColor, size: 9),
                          SizedBox(width: 4),
                          _ColorDot(color: preset.accentGlow, size: 9),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              preset.subtitleEnglish,
                              style: TextStyle(
                                color: selected
                                    ? preset.primaryColor.withValues(alpha: 0.9)
                                    : _Tok.textMuted.withValues(alpha: 0.7),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Animated Radio Dot with Checkmark
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? preset.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? preset.primaryColor
                          : _Tok.borderHi,
                      width: 1.8,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: preset.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorDot({required this.color, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 – Features
// ---------------------------------------------------------------------------

class _Feature {
  final IconData icon;
  final String title;
  final String caption;
  final Color tint;

  _Feature(this.icon, this.title, this.caption, this.tint);
}

final _features = [
  _Feature(
    Icons.calendar_month_rounded,
    'ድርብ ቀን መቁጠሪያ',
    'Ethiopian + Gregorian, side by side — 13 months and Pagume',
    _Tok.accent,
  ),
  _Feature(
    Icons.auto_awesome_rounded,
    'ባሕረ ሐሳብ እና በዓላት',
    'Movable feasts, fasting, saints, and cultural days',
    Color(0xFFA78BFA),
  ),
  _Feature(
    Icons.event_available_rounded,
    'የእርስዎ ሕይወት',
    'Events, reminders, widgets — on your calendar',
    Color(0xFFFB923C),
  ),
];

class _FeaturesPage extends StatelessWidget {
  final bool active;

  const _FeaturesPage({required this.active});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        _Reveal(active: active, order: 0, child: _Eyebrow('ዘመን · Your calendar first')),
        const SizedBox(height: 10),
        _Reveal(
          active: active,
          order: 1,
          child: _Heading(
            amharic: 'ቀን መቁጠሪያው ማዕከል ነው',
            english: 'The calendar is the heart of Zemen',
            body: 'Everything else supports the date you are looking at — not the other way around.',
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < _features.length; i++) ...[
          _Reveal(
            active: active,
            order: 2 + i,
            child: _FeatureCard(feature: _features[i]),
          ),
          if (i < _features.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;
    final tint = feature.tint == _Tok.accent ? tok.accent : feature.tint;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Tok.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.10), _Tok.surface.withValues(alpha: 0.9)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: tint, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(color: _Tok.text, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.caption,
                  style: TextStyle(color: _Tok.textMuted, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 – Personalize (language, numerals, week start)
// ---------------------------------------------------------------------------

final _languages = [
  for (final lang in AppLanguage.values)
    (lang.preferenceValue, lang.nativeName, lang.displayName),
];

class _PersonalizePage extends ConsumerWidget {
  final bool active;

  const _PersonalizePage({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);
    final today = EthiopianCalendarEngine.todayEthiopian();

    return _PageScaffold(
      children: [
        _Reveal(active: active, order: 0, child: _Eyebrow('ያብጁ · Personalize')),
        const SizedBox(height: 10),
        _Reveal(
          active: active,
          order: 1,
          child: _Heading(amharic: 'የእርስዎ ምርጫ', english: 'Make it yours'),
        ),
        const SizedBox(height: 24),
        _Reveal(
          active: active,
          order: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('ቋንቋ', 'Language'),
              _GlassCard(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < _languages.length; i++) ...[
                      _LanguageRow(
                        native: _languages[i].$2,
                        english: _languages[i].$3,
                        selected: settings.language == _languages[i].$1,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setLanguage(_languages[i].$1);
                        },
                      ),
                      if (i < _languages.length - 1)
                        Divider(height: 1, indent: 18, endIndent: 18, color: _Tok.border),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Reveal(
          active: active,
          order: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('የቁጥር ቅርጽ', 'Numerals'),
              Row(
                children: [
                  Expanded(
                    child: _PreviewOption(
                      preview: '${today.day}',
                      title: 'ዓለም አቀፍ',
                      caption: '1, 2, 3',
                      selected: settings.numeralType == 'ARABIC',
                      onTap: () => notifier.setNumeralType('ARABIC'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PreviewOption(
                      preview: GeezNumeral.toGeez(today.day),
                      title: 'ግዕዝ',
                      caption: '፩, ፪, ፫',
                      selected: settings.numeralType == 'GEEZ',
                      onTap: () => notifier.setNumeralType('GEEZ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Reveal(
          active: active,
          order: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('ሳምንቱ የሚጀምረው', 'Week starts on'),
              _Segmented(
                options: const [('MONDAY', 'ሰኞ · Monday'), ('SUNDAY', 'እሑድ · Sunday')],
                value: settings.firstDayOfWeek,
                onChanged: notifier.setFirstDayOfWeek,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Reveal(
          active: active,
          order: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('የገጽታ ቀለም', 'Active Theme'),
              _GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final p in AppTheme.presets)
                      Semantics(
                        button: true,
                        selected: settings.accentPalette == p.id,
                        label: p.nameEnglish,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.setAccentPalette(p.id);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: settings.accentPalette == p.id
                                    ? p.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: p.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: settings.accentPalette == p.id
                                    ? [
                                        BoxShadow(
                                          color: p.primaryColor.withValues(alpha: 0.45),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: settings.accentPalette == p.id
                                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String native;
  final String english;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({required this.native, required this.english, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      native,
                      style: TextStyle(
                        color: selected ? tok.accent : _Tok.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (native != english) Text(english, style: TextStyle(color: _Tok.textFaint, fontSize: 12)),
                  ],
                ),
              ),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? tok.accent : Colors.transparent,
        border: Border.all(color: selected ? tok.accent : tok.borderHi, width: 1.6),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
    );
  }
}

class _PreviewOption extends StatelessWidget {
  final String preview;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  const _PreviewOption({
    required this.preview,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 220),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: selected ? tok.accent.withValues(alpha: 0.12) : _Tok.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? tok.accent : _Tok.border, width: selected ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        style: TextStyle(
                          color: selected ? tok.accent : _Tok.text,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _RadioDot(selected: selected),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(color: _Tok.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                Text(caption, style: TextStyle(color: _Tok.textFaint, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _Segmented({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _Tok.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Tok.border),
      ),
      child: Row(
        children: [
          for (final (key, label) in options)
            Expanded(
              child: Semantics(
                selected: value == key,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(key);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == key ? _Tok.surfaceHi : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: value == key ? tok.borderHi : Colors.transparent),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value == key ? tok.accent : _Tok.textMuted,
                        fontSize: 13,
                        fontWeight: value == key ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4 – Preferences & ready
// ---------------------------------------------------------------------------

class _PreferencesPage extends ConsumerWidget {
  final bool active;

  const _PreferencesPage({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSettings settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);

    return _PageScaffold(
      children: [
        _Reveal(
          active: active,
          order: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _Tok.emerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _Tok.emerald.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.verified_rounded, color: _Tok.emerald, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Reveal(
          active: active,
          order: 1,
          child: _Heading(
            amharic: 'ሊጨርሱ ነው',
            english: 'Almost there',
            body: 'Fine-tune what you see. You can change any of this later in Settings.',
          ),
        ),
        const SizedBox(height: 24),
        _Reveal(
          active: active,
          order: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('ዋና የቀን መቁጠሪያ', 'Default calendar'),
              _Segmented(
                options: const [('ETHIOPIAN', '🇪🇹  ኢትዮጵያ'), ('GREGORIAN', '🌍  Gregorian')],
                value: settings.calendarFormat,
                onChanged: notifier.setCalendarFormat,
              ),
            ],
          ),
        ),
        SizedBox(height: 22),
        _Reveal(
          active: active,
          order: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('በቀን መቁጠሪያው ላይ', 'On your calendar'),
              _GlassCard(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _ToggleRow(
                      icon: Icons.restaurant_rounded,
                      tint: _Tok.emerald,
                      title: 'የአጽዋማት ማድመቂያ',
                      subtitle: 'Highlight fasting days',
                      value: settings.showFasting,
                      onChanged: notifier.setShowFasting,
                    ),
                    Divider(height: 1, indent: 66, color: _Tok.border),
                    _ToggleRow(
                      icon: Icons.church_rounded,
                      tint: Color(0xFFF472B6),
                      title: 'የወር ጽላቶች',
                      subtitle: "Show each day's monthly saint",
                      value: settings.showMonthlySaints,
                      onChanged: notifier.setShowMonthlySaints,
                    ),
                    Divider(height: 1, indent: 66, color: _Tok.border),
                    _ToggleRow(
                      icon: Icons.notifications_rounded,
                      tint: const Color(0xFFFB923C),
                      title: 'ማሳወቂያዎች',
                      subtitle: 'Reminders for holidays & events',
                      value: settings.notificationsEnabled,
                      onChanged: notifier.setNotificationsEnabled,
                    ),
                    Divider(height: 1, indent: 66, color: _Tok.border),
                    _ToggleRow(
                      icon: Icons.sports_soccer_rounded,
                      tint: const Color(0xFF38BDF8),
                      title: 'እግር ኳስ',
                      subtitle: 'Optional Football tab — off by default',
                      value: settings.showFootball,
                      onChanged: notifier.setShowFootball,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tok = _ThemeTokScope.of(context).tok;

    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: tint, size: 19),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: _Tok.text, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: _Tok.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: tok.accent,
                inactiveThumbColor: _Tok.textMuted,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
