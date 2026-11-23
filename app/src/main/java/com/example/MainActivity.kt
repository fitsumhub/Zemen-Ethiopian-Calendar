package com.example

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.ui.res.painterResource
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.foundation.Image
import androidx.compose.ui.res.painterResource
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel
import com.example.calendar.ui.navigation.NavScreen
import com.example.calendar.ui.screens.calendar.CalendarScreen
import com.example.calendar.ui.screens.converter.ConverterScreen
import com.example.calendar.ui.screens.events.EventsScreen
import com.example.calendar.ui.screens.holidays.HolidaysScreen
import com.example.calendar.ui.screens.home.HomeScreen
import com.example.calendar.ui.screens.onboarding.OnboardingScreen
import com.example.calendar.ui.screens.settings.SettingsScreen
import com.example.calendar.notification.NotificationScheduler
import com.example.ui.theme.EthioCalTheme

class MainActivity : ComponentActivity() {

    private val navScreenFlow = androidx.compose.runtime.mutableStateOf<NavScreen?>(null)
    private val navRequestSeq = androidx.compose.runtime.mutableIntStateOf(0)
    private val clockTriggerFlow = androidx.compose.runtime.mutableIntStateOf(0)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Ensure notification channel is configured
        NotificationScheduler.initNotificationChannel(this)

        handleNavigationIntent(intent)

        setContent {
            val mainViewModel: MainViewModel = viewModel()
            val userSettings by mainViewModel.userSettings.collectAsState()

            // Notification permission request for Android 13+
            val context = LocalContext.current
            val notificationPermissionLauncher = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.RequestPermission()
            ) { /* Granted or denied handled gracefully */ }

            LaunchedEffect(Unit) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    if (ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    }
                }
            }

            EthioCalTheme(
                themeMode = userSettings.themeMode,
                accentPalette = userSettings.accentPalette
            ) {
                if (!userSettings.onboardingCompleted) {
                    OnboardingScreen(
                        viewModel = mainViewModel,
                        onFinish = {
                            mainViewModel.setOnboardingCompleted(true)
                        }
                    )
                } else {
                    EthioCalApp(
                        viewModel = mainViewModel,
                        initialTargetScreen = navScreenFlow.value,
                        navRequestSeq = navRequestSeq.intValue,
                        openClockTrigger = clockTriggerFlow.intValue,
                        onClockTriggerConsumed = { clockTriggerFlow.intValue = 0 }
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNavigationIntent(intent)
    }

    private fun handleNavigationIntent(intent: Intent?) {
        val target = intent?.getStringExtra("navigate_to") ?: return
        val targetScreen = when (target) {
            "EVENTS", "ADD_EVENT" -> NavScreen.EVENTS
            "CALENDAR" -> NavScreen.CALENDAR
            "CONVERTER" -> NavScreen.CONVERTER
            "HOLIDAYS" -> NavScreen.HOLIDAYS
            "SETTINGS" -> NavScreen.SETTINGS
            "CLOCK" -> {
                clockTriggerFlow.intValue += 1
                NavScreen.HOME
            }
            else -> null
        }
        if (targetScreen != null) {
            navScreenFlow.value = targetScreen
            navRequestSeq.intValue += 1
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EthioCalApp(
    viewModel: MainViewModel,
    initialTargetScreen: NavScreen? = null,
    navRequestSeq: Int = 0,
    openClockTrigger: Int = 0,
    onClockTriggerConsumed: () -> Unit = {}
) {
    var currentScreen by remember { mutableStateOf(initialTargetScreen ?: NavScreen.HOME) }

    LaunchedEffect(initialTargetScreen, navRequestSeq) {
        if (initialTargetScreen != null) {
            currentScreen = initialTargetScreen
        }
    }
    val userSettings by viewModel.userSettings.collectAsState()
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    // BackHandler: Return to Home if on another tab
    BackHandler(enabled = currentScreen != NavScreen.HOME) {
        currentScreen = NavScreen.HOME
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Enhanced EthioCal Pro Logo Emblem
                        Image(
                            painter = painterResource(id = R.drawable.ic_ethiocal_logo),
                            contentDescription = "EthioCal Pro Logo",
                            modifier = Modifier
                                .size(34.dp)
                                .clip(CircleShape)
                        )

                        Spacer(modifier = Modifier.width(10.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "EthioCal Pro",
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            val monthName = LocaleStrings.getMonthName(todayEth.month, currentLang)
                            val dayText = todayEth.day.toString()
                            Text(
                                text = "$monthName $dayText፣ ${todayEth.year} ዓ.ም",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        // Today quick jump button
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier
                                .clickable {
                                    viewModel.goToToday()
                                    currentScreen = NavScreen.CALENDAR
                                }
                                .padding(end = 8.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.CalendarToday,
                                    contentDescription = "Today",
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(14.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = LocaleStrings.get("today", currentLang),
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                windowInsets = WindowInsets.statusBars
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                windowInsets = WindowInsets.navigationBars,
                modifier = Modifier.testTag("bottom_nav_bar")
            ) {
                NavScreen.values().forEach { screen ->
                    val selected = currentScreen == screen
                    val label = LocaleStrings.get(screen.stringKey, currentLang)

                    NavigationBarItem(
                        selected = selected,
                        onClick = { currentScreen = screen },
                        icon = {
                            Icon(
                                screen.icon,
                                contentDescription = label,
                                modifier = Modifier.size(22.dp)
                            )
                        },
                        label = {
                            Text(
                                text = label,
                                fontSize = 10.sp,
                                fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                                maxLines = 1
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = MaterialTheme.colorScheme.primary,
                            selectedTextColor = MaterialTheme.colorScheme.primary,
                            indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                            unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                            unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                        ),
                        modifier = Modifier.testTag("nav_item_${screen.route}")
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (currentScreen) {
                NavScreen.HOME -> HomeScreen(
                    viewModel = viewModel,
                    onNavigate = { currentScreen = it },
                    openClockTrigger = openClockTrigger,
                    onClockTriggerConsumed = onClockTriggerConsumed
                )
                NavScreen.CALENDAR -> CalendarScreen(
                    viewModel = viewModel
                )
                NavScreen.CONVERTER -> ConverterScreen(
                    viewModel = viewModel,
                    onNavigateToCalendar = { date ->
                        viewModel.selectDate(date)
                        currentScreen = NavScreen.CALENDAR
                    }
                )
                NavScreen.HOLIDAYS -> HolidaysScreen(
                    viewModel = viewModel,
                    onNavigateToCalendar = { date ->
                        viewModel.selectDate(date)
                        currentScreen = NavScreen.CALENDAR
                    }
                )
                NavScreen.EVENTS -> EventsScreen(
                    viewModel = viewModel
                )
                NavScreen.SETTINGS -> SettingsScreen(
                    viewModel = viewModel
                )
            }
        }
    }
}
