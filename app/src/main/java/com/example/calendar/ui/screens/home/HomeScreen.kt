package com.example.calendar.ui.screens.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.HourglassBottom
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Widgets
import com.example.calendar.ui.components.WidgetManagementDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.content.Intent
import androidx.compose.ui.platform.LocalContext
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.DailyHeritageEngine
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel
import com.example.calendar.ui.navigation.NavScreen
import com.example.calendar.ui.screens.cards.HolidayCardShareDialog
import com.example.calendar.ui.screens.events.AddEditEventDialog
import com.example.calendar.ui.components.DualCalendarDatePickerDialog
import com.example.calendar.ui.components.EthiopianClockDialog
import kotlinx.coroutines.delay
import java.util.Calendar
import java.util.Locale

@Composable
fun HomeScreen(
    viewModel: MainViewModel,
    onNavigate: (NavScreen) -> Unit,
    openClockTrigger: Int = 0,
    onClockTriggerConsumed: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val settings by viewModel.userSettings.collectAsState()
    val todayEth = viewModel.todayEthiopian
    val todayGreg = viewModel.todayGregorian
    val currentLang = viewModel.currentAppLanguage()

    val todayEvents by viewModel.eventsForSelectedDate.collectAsState()
    val upcomingHoliday by viewModel.upcomingHoliday.collectAsState()

    var showAddEventDialog by remember { mutableStateOf(false) }
    var eventToEdit by remember { mutableStateOf<EventEntity?>(null) }
    var showShareCardDialog by remember { mutableStateOf(false) }
    var showDatePickerDialog by remember { mutableStateOf(false) }
    var showEthiopianClockDialog by remember { mutableStateOf(false) }
    var showWidgetDialog by remember { mutableStateOf(false) }

    LaunchedEffect(openClockTrigger) {
        if (openClockTrigger > 0) {
            showEthiopianClockDialog = true
            onClockTriggerConsumed()
        }
    }

    val context = LocalContext.current
    val dailyHeritage = remember(todayEth) { DailyHeritageEngine.getHeritageForDate(todayEth) }

    // Live clock for traditional Ethiopian time
    var currentTimeMillis by remember { mutableStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000)
            currentTimeMillis = System.currentTimeMillis()
        }
    }

    val cal = remember(currentTimeMillis) { Calendar.getInstance() }
    val gHour = cal.get(Calendar.HOUR_OF_DAY)
    val gMin = cal.get(Calendar.MINUTE)
    val ethTime = remember(gHour, gMin) {
        EthiopianTimeConverter.gregorianToEthiopian(gHour, gMin)
    }

    val dow = EthiopianCalendarEngine.getDayOfWeek(todayEth)
    val evangelistIndex = EthiopianCalendarEngine.getEvangelist(todayEth.year)
    val evangelistName = when (evangelistIndex) {
        1 -> "ዘመነ ማቴዎስ (Matthew)"
        2 -> "ዘመነ ማርቆስ (Mark)"
        3 -> "ዘመነ ሉቃስ (Luke)"
        else -> "ዘመነ ዮሐንስ (John)"
    }

    val monthName = LocaleStrings.getMonthName(todayEth.month, currentLang)
    val weekdayName = LocaleStrings.getWeekdayLong(dow, currentLang)
    val formattedDay = todayEth.day.toString()

    val fastingStatus = remember(todayEth) { HolidayEngine.isFastingDay(todayEth) }
    val dailySaint = remember(todayEth.day) {
        HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == todayEth.day }
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 12.dp, bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // 1. HERO CARD: Prominent Ethiopian Date & Traditional Clock
        item {
            ElevatedCard(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("home_hero_card")
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.surfaceVariant,
                                    MaterialTheme.colorScheme.surface
                                )
                            )
                        )
                        .padding(20.dp)
                ) {
                    Column {
                        // Top header: Tricolor mini badge + Year Evangelist
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFF0F9D58))
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFF4B400))
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFDB4437))
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "ኢትዮጵያ (Ethiopia)",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            // Evangelist pill
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = MaterialTheme.colorScheme.primaryContainer,
                                tonalElevation = 2.dp
                            ) {
                                Text(
                                    text = evangelistName,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Large Date Display (Clickable to open Dual Calendar Date Picker)
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color.Transparent,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable { showDatePickerDialog = true }
                                .testTag("home_hero_date_picker_trigger")
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp)
                            ) {
                                Text(
                                    text = formattedDay,
                                    fontSize = 48.sp,
                                    fontWeight = FontWeight.Black,
                                    color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.padding(end = 12.dp)
                                )

                                Column(modifier = Modifier.weight(1f)) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Text(
                                            text = "$monthName ${todayEth.year} ዓ.ም",
                                            fontSize = 21.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onSurface
                                        )
                                        Surface(
                                            shape = RoundedCornerShape(8.dp),
                                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
                                        ) {
                                            Text(
                                                text = "📅 ቀን ምረጥ",
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = MaterialTheme.colorScheme.primary,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
                                            )
                                        }
                                    }
                                    Text(
                                        text = "$weekdayName • ${todayGreg.day}/${todayGreg.month}/${todayGreg.year} G.C.",
                                        fontSize = 13.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Traditional Ethiopian Time ticker bar (Interactive - opens 12-hour clock modal)
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = MaterialTheme.colorScheme.surface,
                            border = androidx.compose.foundation.BorderStroke(
                                1.dp,
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable { showEthiopianClockDialog = true }
                                .testTag("home_ethiopian_clock_trigger")
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        Icons.Default.AccessTime,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "የኢትዮጵያ ሰዓት:",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "${ethTime.period.amharic} ${ethTime.hour}:${String.format(Locale.US, "%02d", ethTime.minute)} (${if (ethTime.isDaytime) "ቀን" else "ሌሊት"})",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }

                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = String.format(Locale.US, "%02d:%02d:%02d", gHour, gMin, cal.get(Calendar.SECOND)),
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "⏱️",
                                        fontSize = 11.sp
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. DAILY OBSERVANCES & FASTING STATUS
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Fasting Card
                if (settings.showFasting) {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = if (fastingStatus.isFasting) Color(0xFF1E3A2B) else MaterialTheme.colorScheme.surfaceVariant
                        ),
                        modifier = Modifier.weight(1f)
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.Star,
                                    contentDescription = null,
                                    tint = if (fastingStatus.isFasting) Color(0xFF34D399) else MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "የጾም ሁኔታ",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (fastingStatus.isFasting) Color(0xFF34D399) else MaterialTheme.colorScheme.primary
                                )
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = fastingStatus.reason,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                color = if (fastingStatus.isFasting) Color.White else MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 2
                            )
                        }
                    }
                }

                // Daily Saint Card
                if (settings.showMonthlySaints && dailySaint != null) {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant
                        ),
                        modifier = Modifier.weight(1f)
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.Event,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.secondary,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "የዕለቱ ታሳቢ (ጽላት)",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.secondary
                                )
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = dailySaint.nameAmharic,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurface,
                                maxLines = 2
                            )
                        }
                    }
                }
            }
        }

        // 2.5 KEN QEN (ቀን ቀን) • DAILY ETHIOPIAN WISDOM & PROVERB
        item {
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.25f)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("home_daily_wisdom_card")
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "✨ ቀን ቀን • የዕለቱ ጥበብ",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = dailyHeritage.proverb.category,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = "«${dailyHeritage.proverb.amharic}»",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = MaterialTheme.colorScheme.onSurface,
                        lineHeight = 22.sp
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = dailyHeritage.proverb.englishTranslation,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        lineHeight = 16.sp
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = dailyHeritage.proverb.meaning,
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.85f),
                        lineHeight = 15.sp
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "ወቅት: ${dailyHeritage.solarPhase}",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                        )

                        TextButton(
                            onClick = {
                                val shareText = buildString {
                                    append("✨ የዕለቱ የኢትዮጵያ ጥበብ (${monthName} ${todayEth.day}፣ ${todayEth.year} ዓ.ም)\n\n")
                                    append("«${dailyHeritage.proverb.amharic}»\n")
                                    append("${dailyHeritage.proverb.englishTranslation}\n\n")
                                    append("ትርጉም: ${dailyHeritage.proverb.meaning}\n")
                                    if (dailySaint != null) {
                                        append("የዕለቱ ጽላት: ${dailySaint.nameAmharic}\n")
                                    }
                                    append("ዘመነ: $evangelistName\n\n")
                                    append("— ከኢትዮጵያ ካላንደር መተግበሪያ (Ethiopian Calendar)")
                                }
                                val sendIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, shareText)
                                }
                                context.startActivity(Intent.createChooser(sendIntent, "የዕለቱን ጥበብ አጋራ"))
                            },
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 2.dp)
                        ) {
                            Icon(
                                Icons.Default.Share,
                                contentDescription = "Share Proverb",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(14.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "አጋራ",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }

        // 3. UPCOMING HOLIDAY COUNTDOWN
        if (upcomingHoliday != null) {
            val holiday = upcomingHoliday!!
            val daysDiff = EthiopianCalendarEngine.daysBetween(todayEth, holiday.ethiopianDate)
            item {
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onNavigate(NavScreen.HOLIDAYS) }
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.padding(end = 8.dp)
                                ) {
                                    Text(
                                        text = "ቀጣይ በዓል",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onPrimary,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                                Text(
                                    text = "${LocaleStrings.getMonthName(holiday.ethiopianDate.month, currentLang)} ${holiday.ethiopianDate.day}",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Text(
                                text = holiday.titleAmharic,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )

                            Text(
                                text = holiday.titleEnglish,
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        // Countdown Pill
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = MaterialTheme.colorScheme.primaryContainer,
                            tonalElevation = 3.dp
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        Icons.Default.HourglassBottom,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "$daysDiff",
                                        fontSize = 20.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                                Text(
                                    text = "ቀናት ቀሩ",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                    }
                }
            }
        }

        // 4. QUICK ACTION BUTTONS
        item {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = LocaleStrings.get("quick_actions", currentLang),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier
                            .clickable { showWidgetDialog = true }
                            .testTag("home_add_widget_button")
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Icon(
                                Icons.Default.Widgets,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(13.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "📱 ዊጄት",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    QuickActionButton(
                        icon = Icons.Default.Add,
                        label = "ማስታወሻ\nመዝግብ",
                        onClick = { showAddEventDialog = true },
                        modifier = Modifier.weight(1f).testTag("quick_action_add_event")
                    )
                    QuickActionButton(
                        icon = Icons.Default.Calculate,
                        label = "ቀን ቀያሪ\nመሳሪያ",
                        onClick = { onNavigate(NavScreen.CONVERTER) },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        icon = Icons.Default.CalendarMonth,
                        label = "ባሕረ ሐሳብ\nቀመር",
                        onClick = { onNavigate(NavScreen.CONVERTER) },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        icon = Icons.Default.Share,
                        label = "የበዓል ካርድ\nአጋራ",
                        onClick = { showShareCardDialog = true },
                        modifier = Modifier.weight(1f).testTag("quick_action_share_card")
                    )
                }
            }
        }

        // 5. TODAY'S PERSONAL EVENTS
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "የዛሬ ማስታወሻዎች (${todayEvents.size})",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                TextButton(onClick = { onNavigate(NavScreen.EVENTS) }) {
                    Text(LocaleStrings.get("view_all", currentLang))
                }
            }
        }

        if (todayEvents.isEmpty()) {
            item {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.DateRange,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.outline,
                            modifier = Modifier.size(40.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = LocaleStrings.get("no_events_today", currentLang),
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedButton(onClick = { showAddEventDialog = true }) {
                            Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("አዲስ ማስታወሻ ያክሉ")
                        }
                    }
                }
            }
        } else {
            items(todayEvents, key = { it.id }) { event ->
                EventListItem(
                    event = event,
                    onToggle = { viewModel.toggleEventCompletion(event) },
                    onDelete = { viewModel.deleteEvent(event) },
                    onEdit = {
                        eventToEdit = event
                        showAddEventDialog = true
                    }
                )
            }
        }
    }

    if (showAddEventDialog) {
        AddEditEventDialog(
            initialDate = todayEth,
            eventToEdit = eventToEdit,
            currentLanguage = currentLang,
            onDismiss = {
                showAddEventDialog = false
                eventToEdit = null
            },
            onSave = { event ->
                viewModel.saveEvent(event)
                showAddEventDialog = false
                eventToEdit = null
            }
        )
    }

    if (showShareCardDialog) {
        HolidayCardShareDialog(
            currentDate = todayEth,
            currentLanguage = currentLang,
            onDismiss = { showShareCardDialog = false }
        )
    }

    if (showDatePickerDialog) {
        DualCalendarDatePickerDialog(
            initialDate = todayEth,
            initialFormat = settings.calendarFormat,
            todayEthiopian = todayEth,
            currentLang = currentLang,
            isSundayFirst = settings.firstDayOfWeek == "SUNDAY",
            onDismissRequest = { showDatePickerDialog = false },
            onDateSelected = { pickedDate, pickedFormat ->
                viewModel.selectDate(pickedDate)
                if (pickedFormat != settings.calendarFormat) {
                    viewModel.setCalendarFormat(pickedFormat)
                }
                showDatePickerDialog = false
                onNavigate(NavScreen.CALENDAR)
            }
        )
    }

    if (showEthiopianClockDialog) {
        EthiopianClockDialog(
            onDismissRequest = { showEthiopianClockDialog = false }
        )
    }

    if (showWidgetDialog) {
        WidgetManagementDialog(
            currentLanguage = currentLang,
            onDismissRequest = { showWidgetDialog = false }
        )
    }
}

@Composable
private fun QuickActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        tonalElevation = 2.dp,
        modifier = modifier.clickable { onClick() }
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 4.dp)
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = label,
                fontSize = 10.sp,
                lineHeight = 13.sp,
                fontWeight = FontWeight.Medium,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
fun EventListItem(
    event: EventEntity,
    onToggle: () -> Unit,
    onDelete: () -> Unit,
    onEdit: (() -> Unit)? = null
) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
        ),
        modifier = Modifier
            .fillMaxWidth()
            .let { mod -> if (onEdit != null) mod.clickable { onEdit() } else mod }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onToggle) {
                Icon(
                    imageVector = if (event.isCompleted) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                    contentDescription = "Toggle Complete",
                    tint = if (event.isCompleted) Color(0xFF10B981) else MaterialTheme.colorScheme.outline
                )
            }

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = event.title,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (event.isCompleted) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
                    style = if (event.isCompleted) androidx.compose.ui.text.TextStyle(
                        textDecoration = androidx.compose.ui.text.style.TextDecoration.LineThrough
                    ) else androidx.compose.ui.text.TextStyle()
                )
                if (event.description.isNotEmpty()) {
                    Text(
                        text = event.description,
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1
                    )
                }
                Row(
                    modifier = Modifier.padding(top = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant
                    ) {
                        Text(
                            text = if (event.isAllDay) "ሙሉ ቀን" else com.example.calendar.notification.NotificationScheduler.formatClock12h(event.hour, event.minute),
                            fontSize = 10.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    if (event.reminderMinutesBefore >= 0 && !event.isCompleted) {
                        val alertClock = com.example.calendar.notification.NotificationScheduler.formatClock12h(event.hour, event.minute)
                        val offsetShort = com.example.calendar.notification.NotificationScheduler.formatReminderOffsetShort(event.reminderMinutesBefore)
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.7f)
                        ) {
                            Text(
                                text = if (event.reminderMinutesBefore == 0) "🔔 $alertClock" else "🔔 $alertClock (-$offsetShort)",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                    if (event.recurrence != "NONE") {
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = MaterialTheme.colorScheme.secondaryContainer
                        ) {
                            Text(
                                text = event.recurrence,
                                fontSize = 10.sp,
                                color = MaterialTheme.colorScheme.onSecondaryContainer,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}
