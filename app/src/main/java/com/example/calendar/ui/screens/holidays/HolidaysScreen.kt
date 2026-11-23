package com.example.calendar.ui.screens.holidays

import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Church
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.RestaurantMenu
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.data.EventEntity
import com.example.calendar.data.IcsExporter
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

/**
 * Enhanced, Comprehensive Ethiopian Holidays & Celebrations Hub.
 * Features 4 high-fidelity modules:
 * 1. Annual Holidays (ዓመታዊ በዓላት) - Public, Orthodox, Islamic, Cultural, Fasting with Live Countdown
 * 2. Fasting Guide (አጽዋማት) - Today's Fasting Status & The 7 Canonical Fasts
 * 3. Monthly Saints (የወር ጽላቶች) - Complete 1-30 Day Saint & Tabot Directory
 * 4. Card Studio (የካርድ ስቱዲዮ) - Festive greeting card maker with authentic blessings
 */
@Composable
fun HolidaysScreen(
    viewModel: MainViewModel,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    var selectedTab by remember { mutableIntStateOf(0) }
    var selectedYear by remember { mutableIntStateOf(todayEth.year) }

    var activeDetailHoliday by remember { mutableStateOf<HolidayEngine.Holiday?>(null) }
    var cardStudioHoliday by remember { mutableStateOf<HolidayEngine.Holiday?>(null) }
    var detailReminderHoliday by remember { mutableStateOf<HolidayEngine.Holiday?>(null) }

    data class HolidayTabItem(val titleEn: String, val titleLocal: String, val icon: ImageVector)

    val tabs = remember {
        listOf(
            HolidayTabItem("Holidays (በዓላት)", "Annual Feasts", Icons.Default.Event),
            HolidayTabItem("Fasting (አጽዋማት)", "7 Canonical Fasts", Icons.Default.RestaurantMenu),
            HolidayTabItem("Saints (ጽላቶች)", "Monthly 1-30", Icons.Default.Church),
            HolidayTabItem("Card Studio (ካርድ)", "Greeting Maker", Icons.Default.CardGiftcard)
        )
    }

    Column(modifier = modifier.fillMaxSize()) {
        // High-density professional Scrollable Tab Bar
        Surface(
            tonalElevation = 2.dp,
            shadowElevation = 1.dp,
            color = MaterialTheme.colorScheme.surface
        ) {
            ScrollableTabRow(
                selectedTabIndex = selectedTab,
                edgePadding = 12.dp,
                containerColor = MaterialTheme.colorScheme.surface,
                contentColor = MaterialTheme.colorScheme.primary,
                indicator = { tabPositions ->
                    if (selectedTab < tabPositions.size) {
                        TabRowDefaults.SecondaryIndicator(
                            Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                            color = MaterialTheme.colorScheme.primary,
                            height = 3.dp
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                tabs.forEachIndexed { index, tab ->
                    val isSelected = selectedTab == index
                    Tab(
                        selected = isSelected,
                        onClick = { selectedTab = index },
                        text = {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(vertical = 4.dp)
                            ) {
                                Icon(
                                    imageVector = tab.icon,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp),
                                    tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Column {
                                    Text(
                                        text = tab.titleEn,
                                        fontSize = 12.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                        color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                                        maxLines = 1
                                    )
                                    Text(
                                        text = tab.titleLocal,
                                        fontSize = 9.5.sp,
                                        color = if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                                        maxLines = 1
                                    )
                                }
                            }
                        }
                    )
                }
            }
        }

        // Animated Tab Content Container
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp)
        ) {
            AnimatedContent(
                targetState = selectedTab,
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                label = "HolidaysTabTransition"
            ) { targetTab ->
                when (targetTab) {
                    0 -> AnnualHolidaysTab(
                        viewModel = viewModel,
                        selectedYear = selectedYear,
                        onYearChange = { selectedYear = it },
                        onSelectHolidayForDetail = { activeDetailHoliday = it },
                        onOpenCardShare = {
                            cardStudioHoliday = it
                            selectedTab = 3
                        },
                        onNavigateToCalendar = onNavigateToCalendar
                    )
                    1 -> FastingGuideTab(
                        viewModel = viewModel,
                        selectedYear = selectedYear
                    )
                    2 -> MonthlySaintsTab(
                        viewModel = viewModel,
                        onNavigateToCalendar = onNavigateToCalendar
                    )
                    3 -> GreetingCardStudioTab(
                        viewModel = viewModel,
                        preSelectedHoliday = cardStudioHoliday
                    )
                }
            }
        }
    }

    // Modal Holiday Detail Dossier Dialog
    if (activeDetailHoliday != null) {
        val holiday = activeDetailHoliday!!
        HolidayDetailDialog(
            holiday = holiday,
            currentLang = currentLang,
            todayEth = todayEth,
            onDismiss = { activeDetailHoliday = null },
            onAddToEvents = { h ->
                activeDetailHoliday = null
                detailReminderHoliday = h
            },
            onExportIcs = { h ->
                val g = EthiopianCalendarEngine.toGregorian(h.ethiopianDate)
                val singleEvent = EventEntity(
                    title = "${h.titleAmharic} (${h.titleEnglish})",
                    description = h.description,
                    category = "HOLIDAY",
                    ethiopianYear = h.ethiopianDate.year,
                    ethiopianMonth = h.ethiopianDate.month,
                    ethiopianDay = h.ethiopianDate.day,
                    gregorianYear = g.year,
                    gregorianMonth = g.month,
                    gregorianDay = g.day,
                    isAllDay = true
                )
                val icsContent = IcsExporter.exportToIcs(listOf(singleEvent))
                val intent = Intent().apply {
                    action = Intent.ACTION_SEND
                    putExtra(Intent.EXTRA_TEXT, icsContent)
                    type = "text/calendar"
                }
                context.startActivity(Intent.createChooser(intent, "Export .ICS Holiday Calendar"))
            },
            onShareCard = { h ->
                cardStudioHoliday = h
                selectedTab = 3
            },
            onNavigateToCalendar = onNavigateToCalendar
        )
    }

    if (detailReminderHoliday != null) {
        val h = detailReminderHoliday!!
        val existing = viewModel.getEventForHoliday(h)
        SetHolidayReminderDialog(
            holiday = h,
            existingEvent = existing,
            currentLang = currentLang,
            onDismiss = { detailReminderHoliday = null },
            onSaveReminder = { hour, minute, onEve, offset ->
                viewModel.scheduleHolidayReminder(h, hour, minute, onEve, offset) {
                    Toast.makeText(
                        context,
                        "🔔 ማሳሰቢያ ተይዟል! (Reminder set for %02d:%02d)".format(hour, minute),
                        Toast.LENGTH_SHORT
                    ).show()
                }
            },
            onDeleteReminder = {
                viewModel.cancelHolidayReminder(h) {
                    Toast.makeText(context, "የበዓል ማሳሰቢያው ተሰርዟል (Reminder removed)", Toast.LENGTH_SHORT).show()
                }
            }
        )
    }
}
