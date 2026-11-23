import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ads/ad_frequency_controller.dart';
import 'core/ads/ad_manager.dart';
import 'core/ads/banner_ad_widget.dart';
import 'core/brand/brand.dart';
import 'core/calendar/calendar_data_catalog.dart';
import 'core/calendar/ethiopian_calendar_engine.dart';
import 'core/calendar/ethiopian_date.dart';
import 'core/calendar/gregorian_date.dart';
import 'core/localization/locale_strings.dart';
import 'core/notifications/notification_scheduler.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/home_widget_sync.dart';
import 'data/preferences/user_preferences_repository.dart';
import 'core/localization/app_language.dart';
import 'core/localization/app_localizations_setup.dart';
import 'features/calendar/calendar_home_screen.dart';
import 'features/converter/converter_home_screen.dart';
import 'features/events/events_hub_screen.dart';
import 'features/football/football_screen.dart';
import 'features/holidays/holidays_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shared/components/app_chrome.dart';
import 'features/shared/components/widget_management_dialog.dart';
import 'features/shared/providers.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferencesRepository.initialize();
  try {
    final lang = AppLanguage.fromString(
      UserPreferencesRepository.instance.getSettings().language,
    );
    NotificationScheduler.setLanguage(lang);
    await NotificationScheduler.initialize(language: lang);
    // Rebuild OS alarms after install/update/reboot when reminders stay on.
    await NotificationScheduler.rescheduleFromDatabaseIfEnabled();
  } catch (_) {
    // Plugin channels unavailable in pure unit/widget tests; UI still runs.
  }
  // Initialize Google Mobile Ads & UMP Consent flow (safe in offline/test environments)
  try {
    await AdManager.instance.initialize();
  } catch (e) {
    debugPrint('AdManager init bypassed in test/offline environment: $e');
  }
  // Warm offline calendar datasets (non-blocking if assets missing in tests).
  try {
    await CalendarDataCatalog.warmUp();
  } catch (_) {}
  try {
    final prefs = UserPreferencesRepository.instance;
    final lang = AppLanguage.fromString(prefs.getSettings().language);
    await HomeWidgetSync.sync(
      styleIndex: prefs.getWidgetStyle(),
      lang: lang,
    );
  } catch (_) {}
  runApp(const ProviderScope(child: ZemenApp()));
}

/// Zemen root widget. [EthioCalApp] is kept as a test-compatible alias.
class ZemenApp extends ConsumerWidget {
  const ZemenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final lang = AppLanguage.fromString(settings.language);

    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final lightTheme = AppTheme.getTheme(
      themeMode: 'LIGHT',
      accentPalette: settings.accentPalette,
      systemBrightness: Brightness.light,
    );
    final darkTheme = AppTheme.getTheme(
      themeMode: settings.themeMode == 'AMOLED' ? 'AMOLED' : 'DARK',
      accentPalette: settings.accentPalette,
      systemBrightness: Brightness.dark,
    );

    final ThemeMode themeMode;
    switch (settings.themeMode) {
      case 'LIGHT':
        themeMode = ThemeMode.light;
        break;
      case 'DARK':
      case 'AMOLED':
        themeMode = ThemeMode.dark;
        break;
      case 'SYSTEM':
      default:
        themeMode = ThemeMode.system;
        break;
    }

    final effectiveBrightness = themeMode == ThemeMode.light
        ? Brightness.light
        : (themeMode == ThemeMode.dark ? Brightness.dark : platformBrightness);

    AppTheme.updateAppColors(
      themeMode: settings.themeMode,
      accentPalette: settings.accentPalette,
      systemBrightness: effectiveBrightness,
    );

    return MaterialApp(
      title: Brand.displayName,
      debugShowCheckedModeBanner: false,
      locale: lang.locale,
      supportedLocales: AppLanguage.values.map((l) => l.locale).toList(),
      localizationsDelegates: AppLocalizationsSetup.delegates,
      localeResolutionCallback: AppLocalizationsSetup.resolveLocale,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      // Temporary bridge for plugins still on package:flutter/material.dart.
      // ignore: deprecated_member_use
      builder: (context, child) {
        final currentBrightness = Theme.of(context).brightness;
        AppTheme.updateAppColors(
          themeMode: settings.themeMode,
          accentPalette: settings.accentPalette,
          systemBrightness: currentBrightness,
        );
        // ignore: deprecated_member_use
        return MaterialUiCompatibilityBridge(
          delegates: AppLocalizationsSetup.legacyDelegates,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: settings.onboardingCompleted
          ? const MainNavigationShell()
          : OnboardingScreen(
              onFinish: () {
                ref.read(userSettingsProvider.notifier).setOnboardingCompleted(true);
              },
            ),
    );
  }
}

typedef EthioCalApp = ZemenApp;

/// Stable destinations used by Home, widgets, and the shell.
abstract final class AppDest {
  static const calendar = 'CALENDAR';
  static const converter = 'CONVERTER';
  static const holidays = 'HOLIDAYS';
  static const events = 'EVENTS';
  static const football = 'FOOTBALL';
}

/// Zemen shell: dark dual-date header + hamburger + horizontal top tabs.
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
    _handleWidgetDestinations();
  }

  void _handleWidgetDestinations() {
    HomeWidgetSync.setDestinationHandler(_navigateFromDestination);
    HomeWidgetSync.getInitialDestination().then((dest) {
      if (dest != null && mounted) {
        _navigateFromDestination(dest);
      }
    });
  }

  List<String> _visibleDestinations(bool showFootball) => [
        AppDest.calendar,
        AppDest.converter,
        AppDest.holidays,
        AppDest.events,
        if (showFootball) AppDest.football,
      ];

  int _indexForDestination(String dest, {required bool showFootball}) {
    final list = _visibleDestinations(showFootball);
    final i = list.indexOf(dest.toUpperCase());
    return i < 0 ? 0 : i;
  }

  void _navigateFromDestination(String dest) {
    final showFootball = ref.read(userSettingsProvider).showFootball;
    final i = _indexForDestination(dest, showFootball: showFootball);
    if (_currentTabIndex != i) setState(() => _currentTabIndex = i);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app may have been backgrounded across midnight.
    if (state == AppLifecycleState.resumed) {
      _refreshTodayIfChanged();
      _scheduleMidnightRefresh();
      // Re-arm Ethiopian recurring reminders that OS cannot repeat natively.
      final settings = ref.read(userSettingsProvider);
      if (settings.notificationsEnabled) {
        NotificationScheduler.setLanguage(
          AppLanguage.fromString(settings.language),
        );
        unawaited(
          ref.read(eventsNotifierProvider.notifier).rescheduleAllReminders(),
        );
      }
      // Keep home-screen widgets current after resume / day change.
      unawaited(_syncHomeWidget());
    }
  }

  Future<void> _syncHomeWidget() async {
    try {
      final prefs = UserPreferencesRepository.instance;
      final lang = AppLanguage.fromString(prefs.getSettings().language);
      await HomeWidgetSync.sync(
        styleIndex: prefs.getWidgetStyle(),
        lang: lang,
      );
    } catch (_) {}
  }

  /// Keeps "today" correct when the app stays open across midnight.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        _refreshTodayIfChanged();
        unawaited(_syncHomeWidget());
        _scheduleMidnightRefresh();
      },
    );
  }

  void _refreshTodayIfChanged() {
    final previous = ref.read(todayEthiopianProvider);
    final actual = EthiopianCalendarEngine.todayEthiopian();
    if (previous == actual) return;
    final wasOnToday = ref.read(selectedDateProvider) == previous;
    ref.invalidate(todayEthiopianProvider);
    ref.invalidate(todayGregorianProvider);
    // Follow the new day only if the user was looking at "today".
    if (wasOnToday) _jumpToCalendarDateKeepingTab(actual);
  }

  void _jumpToCalendarDateKeepingTab(EthiopianDate date) {
    ref.read(selectedDateProvider.notifier).state = date;
    final isGreg = ref.read(userSettingsProvider).calendarFormat == 'GREGORIAN';
    final g = EthiopianCalendarEngine.toGregorian(date);
    ref.read(viewYearProvider.notifier).state = isGreg ? g.year : date.year;
    ref.read(viewMonthProvider.notifier).state = isGreg ? g.month : date.month;
  }

  /// System back: close the drawer, then return to Calendar, then exit.
  void _handleBack() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
      return;
    }
    if (_currentTabIndex != 0) setState(() => _currentTabIndex = 0);
  }

  static const _navLabelKeys = {
    AppDest.calendar: 'nav_calendar',
    AppDest.converter: 'nav_converter',
    AppDest.holidays: 'nav_holidays',
    AppDest.events: 'nav_events',
    AppDest.football: 'nav_football',
  };

  void _jumpToCalendarDate(EthiopianDate date) {
    _jumpToCalendarDateKeepingTab(date);
    ref.read(calendarViewModeProvider.notifier).state = 'MONTH';
    setState(() => _currentTabIndex = 0);
  }

  void _selectTab(int i, List<String> destinations) {
    if (i < 0 || i >= destinations.length) return;
    AdFrequencyController.instance.recordUserAction(
      'tab_switched_${_navLabelKeys[destinations[i]] ?? destinations[i]}',
    );
    setState(() => _currentTabIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final todayEth = ref.watch(todayEthiopianProvider);
    final todayGreg = ref.watch(todayGregorianProvider);
    final lang = ref.watch(currentAppLanguageProvider);
    final settings = ref.watch(userSettingsProvider);
    final isGregPrimary = settings.calendarFormat == 'GREGORIAN';
    final destinations = _visibleDestinations(settings.showFootball);
    if (_currentTabIndex >= destinations.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentTabIndex >= destinations.length) {
          setState(() => _currentTabIndex = 0);
        }
      });
    }
    final safeIndex = _currentTabIndex.clamp(0, destinations.length - 1);
    final tabs = [
      for (final dest in destinations)
        LocaleStrings.get(_navLabelKeys[dest]!, lang),
    ];

    final pages = <Widget>[
      for (final dest in destinations)
        switch (dest) {
          AppDest.converter => ConverterHomeScreen(
              onNavigateToCalendar: _jumpToCalendarDate,
            ),
          AppDest.holidays => HolidaysScreen(
              onNavigateToCalendar: _jumpToCalendarDate,
            ),
          AppDest.events => EventsHubScreen(onOpenDate: _jumpToCalendarDate),
          AppDest.football => const FootballScreen(),
          _ => CalendarHomeScreen(),
        },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: AppColors.canvas,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: AppColors.canvas,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: _currentTabIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.canvas,
        drawer: _AppDrawer(
          lang: lang,
          destinations: destinations,
          selectedIndex: safeIndex,
          onSelectTab: (i) {
            Navigator.of(context).pop();
            _selectTab(i, destinations);
          },
          onOpenHome: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HomeScreen(
                  onNavigateDestination: (dest) {
                    Navigator.of(context).pop();
                    _navigateFromDestination(dest);
                  },
                ),
              ),
            );
          },
          onOpenSettings: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          onOpenWidgets: () {
            Navigator.of(context).pop();
            showWidgetPickerSheet(context, lang);
          },
        ),
        body: Column(
          children: [
            _AppHeader(
              ethDate: todayEth,
              gregDate: todayGreg,
              isGregPrimary: isGregPrimary,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              tabs: tabs,
              selectedIndex: safeIndex,
              onTabSelected: (i) => _selectTab(i, destinations),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth > 1100 ? 1080.0 : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.02, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey('${destinations[safeIndex]}|$safeIndex'),
                          child: pages[safeIndex],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Banner on non-calendar tabs only — keep the calendar view ad-free.
            if (safeIndex != 0)
              const SafeArea(
                top: false,
                child: BannerAdWidget(),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatefulWidget {
  final EthiopianDate ethDate;
  final GregorianDate gregDate;
  final bool isGregPrimary;
  final VoidCallback onMenu;
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _AppHeader({
    required this.ethDate,
    required this.gregDate,
    this.isGregPrimary = false,
    required this.onMenu,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<_AppHeader> {
  final ScrollController _tabScroll = ScrollController();
  final List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _tabKeys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollSelectedIntoView());
  }

  @override
  void didUpdateWidget(covariant _AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollSelectedIntoView());
    }
  }

  @override
  void dispose() {
    _tabScroll.dispose();
    super.dispose();
  }

  void _scrollSelectedIntoView() {
    if (widget.selectedIndex < 0 || widget.selectedIndex >= _tabKeys.length) return;
    final ctx = _tabKeys[widget.selectedIndex].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.45,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final width = MediaQuery.sizeOf(context).width;
    final ethSize = width < 360 ? 22.0 : width < 480 ? 25.0 : width > 1100 ? 30.0 : 28.0;
    final ethText = '${widget.ethDate.day}-${widget.ethDate.month}-${widget.ethDate.year}';
    final gregText = '${widget.gregDate.day}-${widget.gregDate.month}-${widget.gregDate.year}';
    final primaryText = widget.isGregPrimary ? gregText : ethText;
    final secondaryText = widget.isGregPrimary ? ethText : gregText;

    return Container(
      color: AppColors.canvas,
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(width < 360 ? 0 : 2, 8, width < 360 ? 10 : 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: widget.onMenu,
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: EdgeInsets.all(width < 360 ? 8 : 12),
                  ),
                  icon: Icon(Icons.menu_rounded, size: width < 360 ? 24 : 26),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey('$primaryText|$secondaryText'),
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${Brand.shortName} · ${Brand.nameAm}',
                          style: GoogleFonts.outfit(
                            color: AppColors.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            height: 1,
                          ).copyWith(fontFamilyFallback: AppTheme.ethiopicFontFallbacks),
                        ),
                        SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            primaryText,
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: ethSize,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                              letterSpacing: -0.4
                            ).copyWith(fontFamilyFallback: AppTheme.ethiopicFontFallbacks),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          secondaryText,
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ).copyWith(fontFamilyFallback: AppTheme.ethiopicFontFallbacks),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: width < 360 ? 40 : 48), // Balances the menu icon symmetrically
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.builder(
              controller: _tabScroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 6),
              itemCount: widget.tabs.length,
              itemBuilder: (context, i) {
                final selected = i == widget.selectedIndex;
                return KeyedSubtree(
                  key: _tabKeys[i],
                  child: InkWell(
                    onTap: () => widget.onTabSelected(i),
                    splashColor: AppColors.accent.withValues(alpha: 0.15),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? AppColors.accent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 180),
                        style: GoogleFonts.outfit(
                          color: selected ? AppColors.accent : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14.5,
                        ).copyWith(fontFamilyFallback: AppTheme.ethiopicFontFallbacks),
                        child: Text(widget.tabs[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final AppLanguage lang;
  final List<String> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenWidgets;

  const _AppDrawer({
    required this.lang,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onOpenHome,
    required this.onOpenSettings,
    required this.onOpenWidgets,
  });

  static const _drawerIcons = {
    AppDest.calendar: Icons.calendar_month_rounded,
    AppDest.converter: Icons.swap_horiz_rounded,
    AppDest.holidays: Icons.celebration_outlined,
    AppDest.events: Icons.event_outlined,
    AppDest.football: Icons.sports_soccer_rounded,
  };

  static const _drawerLabels = {
    AppDest.calendar: 'nav_calendar',
    AppDest.converter: 'nav_converter',
    AppDest.holidays: 'nav_holidays',
    AppDest.events: 'nav_events',
    AppDest.football: 'nav_football',
  };

  @override
  Widget build(BuildContext context) {
    final today = EthiopianCalendarEngine.todayEthiopian();
    final month = LocaleStrings.getMonthName(today.month, lang);
    return Drawer(
      semanticLabel: 'Navigation menu',
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceElevated, AppColors.canvas],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Brand.shortName,
                    style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    Brand.nameAm,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    Brand.tagline,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$month ${today.day}, ${today.year}',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            _drawerItem(Icons.home_rounded, LocaleStrings.get('nav_home', lang), false, onOpenHome),
            for (var i = 0; i < destinations.length; i++)
              _drawerItem(
                _drawerIcons[destinations[i]]!,
                LocaleStrings.get(_drawerLabels[destinations[i]]!, lang),
                selectedIndex == i,
                () => onSelectTab(i),
              ),
            _drawerItem(Icons.widgets_outlined, LocaleStrings.get('nav_home_widgets', lang), false, onOpenWidgets),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 1, color: AppColors.surfaceBorder),
            ),
            _drawerItem(Icons.settings_outlined, LocaleStrings.get('nav_settings', lang), false, onOpenSettings),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(Brand.displayNameBilingual, style: AppChrome.mute(size: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: selected,
          selectedTileColor: Colors.transparent,
          leading: Icon(icon, color: selected ? AppColors.accent : AppColors.textSecondary),
          title: Text(
            label,
            style: AppChrome.title(
              size: 15,
              weight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
