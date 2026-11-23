package com.example.calendar.ui.screens.settings

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import androidx.core.net.toUri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material3.OutlinedButton
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import com.example.calendar.notification.NotificationScheduler
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.ColorLens
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.FileDownload
import androidx.compose.material.icons.filled.FormatListNumbered
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Today
import androidx.compose.ui.res.painterResource
import com.example.R
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.TextButton
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import com.example.calendar.data.IcsExporter
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val settings by viewModel.userSettings.collectAsState()
    val allEvents by viewModel.allEvents.collectAsState()
    val currentLang = viewModel.currentAppLanguage()

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // App Header Brand
        item {
            ElevatedCard(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("🇪🇹", fontSize = 24.sp)
                    }

                    Spacer(modifier = Modifier.width(14.dp))

                    Column {
                        Text(
                            text = "EthioCal Pro",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = "የኢትዮጵያ ቀን መቁጠሪያ እና መገልገያ • v1.0.0",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "100% Offline-First • Safe & Private",
                            fontSize = 11.sp,
                            color = Color(0xFF10B981),
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }

        // Section: Localization & Display
        item {
            SettingsSectionHeader(title = "ቋንቋ እና ቁጥሮች (Language & Numerals)")
        }

        item {
            Card(shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Language picker
                    var langExp by remember { mutableStateOf(false) }
                    val languages = listOf(
                        "ENGLISH" to "English",
                        "AMHARIC" to "አማርኛ (Amharic)",
                        "OROMO" to "Afaan Oromoo",
                        "TIGRINYA" to "ትግርኛ (Tigrinya)",
                        "FRENCH" to "Français"
                    )

                    ExposedDropdownMenuBox(
                        expanded = langExp,
                        onExpandedChange = { langExp = !langExp },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        OutlinedTextField(
                            value = languages.firstOrNull { it.first == settings.language }?.second ?: "English",
                            onValueChange = {},
                            readOnly = true,
                            leadingIcon = { Icon(Icons.Default.Language, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
                            label = { Text("ቋንቋ (App Language)") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = langExp) },
                            modifier = Modifier.fillMaxWidth().menuAnchor(MenuAnchorType.PrimaryNotEditable)
                        )
                        ExposedDropdownMenu(expanded = langExp, onDismissRequest = { langExp = false }) {
                            languages.forEach { (code, name) ->
                                DropdownMenuItem(
                                    text = { Text(name) },
                                    onClick = {
                                        viewModel.setLanguage(code)
                                        langExp = false
                                    }
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Numeral type
                    Text("የቁጥሮች ቅርጽ (Numeral Format):", fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "✓ መደበኛ ቁጥሮች (Standard Arabic Numerals: 1, 2, 3...)",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // First day of week
                    Text("የሳምንት መጀመሪያ ቀን (First Day of Week):", fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = settings.firstDayOfWeek == "SUNDAY",
                            onClick = { viewModel.setFirstDayOfWeek("SUNDAY") },
                            label = { Text("እሑድ (Sunday)") },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = settings.firstDayOfWeek == "MONDAY",
                            onClick = { viewModel.setFirstDayOfWeek("MONDAY") },
                            label = { Text("ሰኞ (Monday)") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }

        // Section: Appearance & Theming
        item {
            SettingsSectionHeader(title = "ገጽታ እና ቀለሞች (Appearance & Theme)")
        }

        item {
            Card(shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Theme mode
                    Text("የስክሪን ገጽታ (Theme Mode):", fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        listOf(
                            "SYSTEM" to "ስርዓት",
                            "LIGHT" to "ብርሃን",
                            "DARK" to "ጨለማ"
                        ).forEach { (mode, label) ->
                            FilterChip(
                                selected = settings.themeMode == mode,
                                onClick = { viewModel.setThemeMode(mode) },
                                label = { Text(label, fontSize = 12.sp) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Color palette
                    Text("የቀለም ስብስብ (Ethiopian Color Palette):", fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        listOf(
                            "GOLD_EMERALD" to "ወርቅና ሐረግ",
                            "ROYAL_INDIGO" to "ላሊበላ",
                            "CRIMSON" to "አክሱም",
                            "TERRACOTTA" to "ስሜን"
                        ).forEach { (pal, label) ->
                            FilterChip(
                                selected = settings.accentPalette == pal,
                                onClick = { viewModel.setAccentPalette(pal) },
                                label = { Text(label, fontSize = 11.sp) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
        }

        // Section: Observances & Notifications
        item {
            SettingsSectionHeader(title = "አጽዋማት እና ማሳሰቢያዎች (Observances & Alerts)")
        }

        item {
            var hasNotificationPermission by remember {
                mutableStateOf(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                )
            }

            var canScheduleExact by remember {
                mutableStateOf(NotificationScheduler.canScheduleExactAlarms(context))
            }

            LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
                hasNotificationPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.POST_NOTIFICATIONS
                    ) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }
                canScheduleExact = NotificationScheduler.canScheduleExactAlarms(context)
            }

            val activeReminderCount = remember(allEvents) {
                NotificationScheduler.countActiveScheduledEvents(allEvents)
            }

            val permissionLauncher = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.RequestPermission()
            ) { isGranted ->
                hasNotificationPermission = isGranted
                if (isGranted) {
                    viewModel.setNotificationsEnabled(true)
                    Toast.makeText(context, "የማሳሰቢያ ፈቃድ ተፈቅዷል (Notifications enabled)", Toast.LENGTH_SHORT).show()
                }
            }

            Card(shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("የጾም ሁኔታዎች ይታዩ", fontWeight = FontWeight.SemiBold)
                            Text("Show fasting status & seasons", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = settings.showFasting,
                            onCheckedChange = { viewModel.setShowFasting(it) }
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("የወር ጽላቶች ይታዩ", fontWeight = FontWeight.SemiBold)
                            Text("Show monthly commemorative saints", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = settings.showMonthlySaints,
                            onCheckedChange = { viewModel.setShowMonthlySaints(it) }
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("የማስታወሻ ደወል (AlarmManager)", fontWeight = FontWeight.SemiBold)
                            Text("Event & task reminder alerts", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = settings.notificationsEnabled,
                            onCheckedChange = { enabled ->
                                if (enabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission) {
                                    permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                } else {
                                    viewModel.setNotificationsEnabled(enabled)
                                }
                            },
                            modifier = Modifier.testTag("notifications_toggle")
                        )
                    }

                    // Warning if exact alarm permission is missing on Android 12+
                    if (settings.notificationsEnabled && !canScheduleExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.5f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text(
                                    text = "⚠️ ትክክለኛ አላርም ፈቃድ ያስፈልጋል (Exact Alarms)",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.error
                                )
                                Text(
                                    text = "ማሳሰቢያዎች በሰዓቱ በትክክል እንዲደርሱ የስርዓቱን ትክክለኛ አላርም ፈቃድ ይፍቀዱ።",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                                Spacer(modifier = Modifier.height(6.dp))
                                OutlinedButton(
                                    onClick = {
                                        try {
                                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                                data = "package:${context.packageName}".toUri()
                                            }
                                            context.startActivity(intent)
                                        } catch (_: Exception) {
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("ፈቃድ ይስጡ (Grant Alarm Permission)", fontSize = 12.sp)
                                }
                            }
                        }
                    }

                    // Active reminders summary + Test AlarmManager notification button
                    if (settings.notificationsEnabled) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.45f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "🔔 ንቁ የታቀዱ ማሳሰቢያዎች (Active Alerts): $activeReminderCount",
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                TextButton(
                                    onClick = {
                                        viewModel.resyncAllReminders { count ->
                                            Toast.makeText(
                                                context,
                                                "🔄 $count ማሳሰቢያዎች በ AlarmManager ታድሰዋል (Resynced $count alerts)",
                                                Toast.LENGTH_SHORT
                                            ).show()
                                        }
                                    },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                                ) {
                                    Text("አድስ (Resync)", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))
                        OutlinedButton(
                            onClick = {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission) {
                                    permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                } else {
                                    viewModel.testNotification()
                                    Toast.makeText(
                                        context,
                                        "🔔 የሙከራ ማሳሰቢያ በ AlarmManager በ2 ሰከንድ ውስጥ ይደርስዎታል (Test reminder scheduled)",
                                        Toast.LENGTH_SHORT
                                    ).show()
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("test_notification_button")
                        ) {
                            Icon(
                                Icons.Default.Notifications,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("የሙከራ ማሳሰቢያ ይላኩ (Test Alarm Alert)", fontSize = 12.sp)
                        }

                        Spacer(modifier = Modifier.height(10.dp))
                        var showSettingsBulkDialog by remember { mutableStateOf(false) }
                        OutlinedButton(
                            onClick = { showSettingsBulkDialog = true },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("bulk_schedule_holidays_button")
                        ) {
                            Icon(
                                Icons.Default.NotificationsActive,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = Color(0xFFF59E0B)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("የበዓላት ማሳሰቢያዎችን ያዘጋጁ (Schedule All Holiday Alerts)", fontSize = 12.sp)
                        }

                        if (showSettingsBulkDialog) {
                            var defaultAlertHour by remember { mutableIntStateOf(8) }
                            AlertDialog(
                                onDismissRequest = { showSettingsBulkDialog = false },
                                title = {
                                    Text("ሁሉንም የዓመቱን በዓላት ማሳሰቢያ ያድርጉ", fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                },
                                text = {
                                    Column {
                                        Text(
                                            text = "ለ ${viewModel.todayEthiopian.year} ዓ.ም ብሔራዊ እና የሃይማኖት በዓላት በሙሉ የማሳሰቢያ ደወል ይቀመጥላቸዋል።",
                                            fontSize = 12.5.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Spacer(modifier = Modifier.height(12.dp))
                                        Text("የማሳሰቢያ ሰዓት ይምረጡ:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                        Spacer(modifier = Modifier.height(6.dp))
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            listOf(
                                                7 to "7:00 AM",
                                                8 to "8:00 AM",
                                                9 to "9:00 AM",
                                                12 to "12:00 PM"
                                            ).forEach { (h, lbl) ->
                                                FilterChip(
                                                    selected = defaultAlertHour == h,
                                                    onClick = { defaultAlertHour = h },
                                                    label = { Text(lbl, fontSize = 11.sp) },
                                                    modifier = Modifier.weight(1f)
                                                )
                                            }
                                        }
                                    }
                                },
                                confirmButton = {
                                    Button(
                                        onClick = {
                                            viewModel.scheduleAllAnnualHolidays(viewModel.todayEthiopian.year, defaultAlertHour, 0, reminderMinutesBefore = 0) { count ->
                                                Toast.makeText(context, "🔔 ለ $count በዓላት ማሳሰቢያ ተይዟል! (Scheduled reminders for $count holidays)", Toast.LENGTH_LONG).show()
                                            }
                                            showSettingsBulkDialog = false
                                        }
                                    ) {
                                        Text("አስቀምጥ (Schedule All)")
                                    }
                                },
                                dismissButton = {
                                    TextButton(onClick = { showSettingsBulkDialog = false }) {
                                        Text("ይቅር (Cancel)")
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }

        // Section: Data & Calendar Integration
        item {
            SettingsSectionHeader(title = "የስልክ ካላንደር እና መረጃ ውህደት (System Integration & Sync)")
        }

        item {
            val calendarPermissionLauncher = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.RequestMultiplePermissions()
            ) { perms ->
                val allGranted = perms.values.all { it }
                if (allGranted) {
                    viewModel.syncEventsToDeviceCalendar(context) { msg ->
                        Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
                    }
                } else {
                    Toast.makeText(context, "የስልክ ካላንደር ፈቃድ አልተሰጠም (Calendar permission denied)", Toast.LENGTH_SHORT).show()
                }
            }

            val importCalendarPermissionLauncher = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.RequestMultiplePermissions()
            ) { perms ->
                val allGranted = perms.values.all { it }
                if (allGranted) {
                    viewModel.importEventsFromDeviceCalendar(context) { msg ->
                        Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
                    }
                } else {
                    Toast.makeText(context, "የስልክ ካላንደር ፈቃድ አልተሰጠም (Calendar permission denied)", Toast.LENGTH_SHORT).show()
                }
            }

            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Today,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "የስልክ ካላንደር ውህደት (Android CalendarProvider)",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                            Text(
                                text = "ከ Google Calendar፣ Wear OS እና ከስልክዎ ካላንደር ጋር በቀጥታ ያመሳስሉ",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = {
                                if (com.example.calendar.data.AndroidCalendarSyncManager.hasCalendarPermissions(context)) {
                                    viewModel.syncEventsToDeviceCalendar(context) { msg ->
                                        Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
                                    }
                                } else {
                                    calendarPermissionLauncher.launch(
                                        arrayOf(
                                            Manifest.permission.READ_CALENDAR,
                                            Manifest.permission.WRITE_CALENDAR
                                        )
                                    )
                                }
                            },
                            modifier = Modifier
                                .weight(1f)
                                .testTag("btn_sync_to_device_cal")
                        ) {
                            Text("ወደ ስልክ አስምር (Export)", fontSize = 11.sp)
                        }

                        OutlinedButton(
                            onClick = {
                                if (com.example.calendar.data.AndroidCalendarSyncManager.hasCalendarPermissions(context)) {
                                    viewModel.importEventsFromDeviceCalendar(context) { msg ->
                                        Toast.makeText(context, msg, Toast.LENGTH_LONG).show()
                                    }
                                } else {
                                    importCalendarPermissionLauncher.launch(
                                        arrayOf(
                                            Manifest.permission.READ_CALENDAR,
                                            Manifest.permission.WRITE_CALENDAR
                                        )
                                    )
                                }
                            },
                            modifier = Modifier
                                .weight(1f)
                                .testTag("btn_import_from_device_cal")
                        ) {
                            Text("ከስልክ አምጣ (Import)", fontSize = 11.sp)
                        }
                    }
                }
            }
        }

        // Section: ICS Export
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        val icsData = IcsExporter.exportToIcs(allEvents)
                        val sendIntent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_TEXT, icsData)
                            type = "text/calendar"
                        }
                        context.startActivity(Intent.createChooser(sendIntent, "Export Calendar Events (ICS)"))
                    }
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.FileDownload, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("ሁሉንም ማስታወሻዎች በ ICS አጋራ", fontWeight = FontWeight.Bold)
                            Text("Export all events to iCalendar (.ics) format", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }

        // Section: Home Screen Widget Info & Management
        item {
            var showWidgetDialog by remember { mutableStateOf(false) }

            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showWidgetDialog = true }
                    .testTag("settings_widget_card")
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF59E0B).copy(alpha = 0.2f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Today,
                            contentDescription = null,
                            tint = Color(0xFFF59E0B),
                            modifier = Modifier.size(22.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("የመነሻ ስክሪን ዊጄት (Home Screen Widget)", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        Text(
                            text = "የኢትዮጵያ ቀን፣ የግዕዝ ቁጥር፣ የኢትዮጵያ ሰዓት እና የጾም ሁኔታዎችን በመነሻ ስክሪንዎ ላይ ለማየት ይንኩ",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            if (showWidgetDialog) {
                com.example.calendar.ui.components.WidgetManagementDialog(
                    currentLanguage = currentLang,
                    onDismissRequest = { showWidgetDialog = false }
                )
            }
        }

        // Section: Replay Onboarding Tour
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        viewModel.setOnboardingCompleted(false)
                        Toast.makeText(context, "Opening Welcome Tour...", Toast.LENGTH_SHORT).show()
                    }
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    androidx.compose.foundation.Image(
                        painter = painterResource(id = R.drawable.ic_ethiocal_logo),
                        contentDescription = null,
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Replay App Introduction Tour", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                        Text("መተግበሪያውን እና የቀን ቀያሪውን መግቢያ እንደገና ይመልከቱ", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }

        // Section: Privacy & AdMob
        item {
            Card(shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Security, contentDescription = null, tint = Color(0xFF10B981))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("ግላዊነት እና ደህንነት (Privacy & Offline First)", fontWeight = FontWeight.Bold)
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "ይህ መተግበሪያ የግል ማስታወሻዎችዎን በሙሉ በራስዎ ስልክ ላይ ብቻ ደህንነቱ በተጠበቀ የRoom ዳታቤዝ ያስቀምጣል። ምንም ዓይነት የግል መረጃ ወደ ውጫዊ ሰርቨር አይላክም። ቀን ቀያሪው፣ የበዓላት ዝርዝሩ እና ባሕረ ሐሳቡ ያለ ኢንተርኔት (100% Offline) ይሰራሉ።",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        lineHeight = 16.sp
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = "📢 Google AdMob: አላስፈላጊ እና የሚያቋርጡ ማስታወቂያዎች የሉም። ቀን በመቀየር ወይም ማስታወሻ በመመዝገብ ወቅት ምንም ዓይነት ማስታወቂያ አይኖርም።",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        fontSize = 13.sp,
        fontWeight = FontWeight.Bold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = 4.dp)
    )
}
