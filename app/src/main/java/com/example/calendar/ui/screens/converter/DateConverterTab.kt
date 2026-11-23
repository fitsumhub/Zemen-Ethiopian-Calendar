package com.example.calendar.ui.screens.converter

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.EthiopianSeason
import com.example.calendar.core.GeezNumeral
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.engine.WorldCountryEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel
import com.example.calendar.ui.screens.events.AddEditEventDialog
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Dual-Direction Ethiopian ⇄ Gregorian Date Converter.
 * Connected Input -> Floating Swap Bridge -> Result Hero flow with theme-aware contrast,
 * synced direction swapping, tactile steppers, calendar pickers, and 1-tap actions.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DateConverterTab(
    viewModel: MainViewModel,
    currentLang: AppLanguage,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null
) {
    val context = LocalContext.current
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA
    var isEthToGreg by remember { mutableStateOf(true) }

    val todayEth = viewModel.todayEthiopian
    val todayGreg = viewModel.todayGregorian

    var ethYear by remember { mutableIntStateOf(todayEth.year) }
    var ethMonth by remember { mutableIntStateOf(todayEth.month) }
    var ethDay by remember { mutableIntStateOf(todayEth.day) }

    var gregYear by remember { mutableIntStateOf(todayGreg.year) }
    var gregMonth by remember { mutableIntStateOf(todayGreg.month) }
    var gregDay by remember { mutableIntStateOf(todayGreg.day) }

    var showEthGridPicker by remember { mutableStateOf(false) }
    var showGregMaterialPicker by remember { mutableStateOf(false) }
    var showYearInputDialog by remember { mutableStateOf(false) }
    var yearInputText by remember { mutableStateOf("") }
    var showAddReminderDialog by remember { mutableStateOf(false) }

    var showCulturalDetails by remember { mutableStateOf(true) }
    var showWorldFormats by remember { mutableStateOf(false) }
    var showOtherCalendars by remember { mutableStateOf(false) }

    val ethiopianMonths = remember {
        listOf(
            Triple(1, "መስከረም", "Meskerem"),
            Triple(2, "ጥቅምት", "Tikimt"),
            Triple(3, "ኅዳር", "Hidar"),
            Triple(4, "ታኅሣሥ", "Tahsas"),
            Triple(5, "ጥር", "Tir"),
            Triple(6, "የካቲት", "Yakatit"),
            Triple(7, "መጋቢት", "Magabit"),
            Triple(8, "ሚያዝያ", "Miyazya"),
            Triple(9, "ግንቦት", "Ginbot"),
            Triple(10, "ሰኔ", "Sene"),
            Triple(11, "ሐምሌ", "Hamle"),
            Triple(12, "ነሐሴ", "Nehase"),
            Triple(13, "ጳጉሜን", "Pagume")
        )
    }

    val gregorianMonths = remember {
        listOf(
            Triple(1, "January", "ጃንዩወሪ"),
            Triple(2, "February", "ፌብሩወሪ"),
            Triple(3, "March", "ማርች"),
            Triple(4, "April", "ኤፕሪል"),
            Triple(5, "May", "ሜይ"),
            Triple(6, "June", "ጁን"),
            Triple(7, "July", "ጁላይ"),
            Triple(8, "August", "ኦገስት"),
            Triple(9, "September", "ሴፕቴምበር"),
            Triple(10, "October", "ኦክቶበር"),
            Triple(11, "November", "ኖቬምበር"),
            Triple(12, "December", "ዲሴምበር")
        )
    }

    val isEthLeap = LeapYearCalculator.isEthiopianLeapYear(ethYear)
    val maxEthDays = EthiopianDate.daysInMonth(ethYear, ethMonth)
    val maxGregDays = GregorianDate.daysInMonth(gregYear, gregMonth)

    val (calculatedEth, calculatedGreg) = if (isEthToGreg) {
        val safeDay = ethDay.coerceIn(1, maxEthDays)
        val eth = EthiopianDate(ethYear, ethMonth, safeDay)
        val greg = EthiopianCalendarEngine.toGregorian(eth)
        Pair(eth, greg)
    } else {
        val safeDay = gregDay.coerceIn(1, maxGregDays)
        val greg = GregorianDate(gregYear, gregMonth, safeDay)
        val eth = EthiopianCalendarEngine.toEthiopian(greg)
        Pair(eth, greg)
    }

    val jdn = EthiopianCalendarEngine.ethiopianToJdn(calculatedEth)
    val dow = EthiopianCalendarEngine.getDayOfWeek(calculatedEth)
    val dowNameEn = LocaleStrings.getWeekdayLong(dow, AppLanguage.ENGLISH)
    val dowNameAm = LocaleStrings.getWeekdayLong(dow, AppLanguage.AMHARIC)
    val dowNameCurrent = LocaleStrings.getWeekdayLong(dow, currentLang)

    val ethMonthNameAm = LocaleStrings.getMonthName(calculatedEth.month, AppLanguage.AMHARIC)
    val ethMonthNameCurrent = LocaleStrings.getMonthName(calculatedEth.month, currentLang)
    val ethMonthNameEn = ethiopianMonths.firstOrNull { it.first == calculatedEth.month }?.third ?: "Month ${calculatedEth.month}"
    val gregMonthNameEn = gregorianMonths.firstOrNull { it.first == calculatedGreg.month }?.second ?: "Month ${calculatedGreg.month}"

    val geezDayStr = GeezNumeral.toGeez(calculatedEth.day)
    val geezMonthStr = GeezNumeral.toGeez(calculatedEth.month)
    val geezYearStr = GeezNumeral.toGeez(calculatedEth.year)
    val fullGeezDate = "$geezDayStr/$geezMonthStr/$geezYearStr ዓ.ም"

    val daysDiff = EthiopianCalendarEngine.daysBetween(todayEth, calculatedEth)
    val relativeBadge = when {
        daysDiff == 0L -> if (isGeezScript) "ዛሬ (Today)" else "Today"
        daysDiff == 1L -> if (isGeezScript) "ነገ (Tomorrow)" else "Tomorrow"
        daysDiff == -1L -> if (isGeezScript) "ትናንት (Yesterday)" else "Yesterday"
        daysDiff > 1L -> if (isGeezScript) "ከ$daysDiff ቀናት በኋላ" else "In $daysDiff days"
        else -> if (isGeezScript) "ከ${-daysDiff} ቀናት በፊት" else "${-daysDiff} days ago"
    }

    val holidays = HolidayEngine.getHolidaysForYear(calculatedEth.year).filter { it.ethiopianDate == calculatedEth }
    val saint = HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == calculatedEth.day }
    val fasting = HolidayEngine.isFastingDay(calculatedEth)
    val evangelist = EthiopianCalendarEngine.getEvangelist(calculatedEth.year)
    val evangelistName = when (evangelist) {
        1 -> "ዘመነ ማቴዎስ (Matthew)"
        2 -> "ዘመነ ማርቆስ (Mark)"
        3 -> "ዘመነ ሉቃስ (Luke)"
        else -> "ዘመነ ዮሐንስ (John)"
    }
    val season = EthiopianSeason.fromEthiopianDate(calculatedEth)

    var swapRotation by remember { mutableFloatStateOf(0f) }
    val animatedRotation by animateFloatAsState(
        targetValue = swapRotation,
        animationSpec = spring(stiffness = Spring.StiffnessMediumLow),
        label = "swap_rotation"
    )

    fun performSwap() {
        swapRotation += 180f
        if (isEthToGreg) {
            gregYear = calculatedGreg.year
            gregMonth = calculatedGreg.month
            gregDay = calculatedGreg.day
        } else {
            ethYear = calculatedEth.year
            ethMonth = calculatedEth.month
            ethDay = calculatedEth.day
        }
        isEthToGreg = !isEthToGreg
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 84.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. DIRECTION SEGMENTED CAPSULE
        item {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    listOf(
                        true to "🇪🇹 Ethiopian ➔ 🌍 Gregorian",
                        false to "🌍 Gregorian ➔ 🇪🇹 Ethiopian"
                    ).forEach { (ethToGregOption, label) ->
                        val active = isEthToGreg == ethToGregOption
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (active) MaterialTheme.colorScheme.primary else Color.Transparent,
                            modifier = Modifier
                                .weight(1f)
                                .minimumInteractiveComponentSize()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable {
                                    if (isEthToGreg != ethToGregOption) {
                                        performSwap()
                                    }
                                }
                        ) {
                            Box(
                                contentAlignment = Alignment.Center,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 10.dp)
                            ) {
                                Text(
                                    text = label,
                                    fontSize = 11.5.sp,
                                    fontWeight = if (active) FontWeight.Bold else FontWeight.Medium,
                                    color = if (active) {
                                        MaterialTheme.colorScheme.onPrimary
                                    } else {
                                        MaterialTheme.colorScheme.onSurfaceVariant
                                    },
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }
                }
            }
        }

        // 2. INPUT CARD (FROM DATE)
        item {
            Card(
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("converter_input_card")
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Header + Quick Calendar & Today Chips
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = if (isEthToGreg) "FROM • ETHIOPIAN (E.C.)" else "FROM • GREGORIAN (G.C.)",
                                fontSize = 10.5.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = MaterialTheme.colorScheme.primary,
                                letterSpacing = 0.8.sp
                            )
                            Text(
                                text = if (isEthToGreg) "የኢትዮጵያ ቀን" else "Gregorian Date",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            AssistChip(
                                onClick = {
                                    if (isEthToGreg) showEthGridPicker = true
                                    else showGregMaterialPicker = true
                                },
                                label = { Text(if (isGeezScript) "ካላንደር" else "Pick", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                                leadingIcon = {
                                    Icon(
                                        Icons.Default.DateRange,
                                        contentDescription = "Pick Date",
                                        modifier = Modifier.size(15.dp),
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                },
                                colors = AssistChipDefaults.assistChipColors(
                                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f),
                                    labelColor = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            )

                            AssistChip(
                                onClick = {
                                    if (isEthToGreg) {
                                        ethYear = todayEth.year
                                        ethMonth = todayEth.month
                                        ethDay = todayEth.day
                                    } else {
                                        gregYear = todayGreg.year
                                        gregMonth = todayGreg.month
                                        gregDay = todayGreg.day
                                    }
                                },
                                label = { Text(if (isGeezScript) "ዛሬ" else "Today", fontSize = 11.sp) },
                                leadingIcon = {
                                    Icon(Icons.Default.Today, contentDescription = "Reset to Today", modifier = Modifier.size(14.dp))
                                }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // YEAR STEPPER CAPSULE
                    Text(
                        text = if (isEthToGreg) "Year (ዓመተ ምሕረት)" else "Year (G.C.)",
                        fontSize = 11.5.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(6.dp))

                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 8.dp, vertical = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                YearStepPill(label = "-5") {
                                    if (isEthToGreg) ethYear = (ethYear - 5).coerceAtLeast(1)
                                    else gregYear = (gregYear - 5).coerceAtLeast(1)
                                }
                                YearStepPill(label = "-1") {
                                    if (isEthToGreg) ethYear = (ethYear - 1).coerceAtLeast(1)
                                    else gregYear = (gregYear - 1).coerceAtLeast(1)
                                }
                            }

                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = MaterialTheme.colorScheme.primaryContainer,
                                modifier = Modifier
                                    .minimumInteractiveComponentSize()
                                    .clip(RoundedCornerShape(12.dp))
                                    .clickable {
                                        yearInputText = if (isEthToGreg) ethYear.toString() else gregYear.toString()
                                        showYearInputDialog = true
                                    }
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
                                ) {
                                    Text(
                                        text = if (isEthToGreg) "$ethYear ዓ.ም" else "$gregYear G.C.",
                                        fontSize = 17.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Icon(
                                        Icons.Default.Edit,
                                        contentDescription = "Edit Year",
                                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                        modifier = Modifier.size(14.dp)
                                    )
                                }
                            }

                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                YearStepPill(label = "+1") {
                                    if (isEthToGreg) ethYear = (ethYear + 1).coerceAtMost(9999)
                                    else gregYear = (gregYear + 1).coerceAtMost(9999)
                                }
                                YearStepPill(label = "+5") {
                                    if (isEthToGreg) ethYear = (ethYear + 5).coerceAtMost(9999)
                                    else gregYear = (gregYear + 5).coerceAtMost(9999)
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // MONTH CAROUSEL
                    Text(
                        text = if (isGeezScript) "ወር (Select Month)" else "Month",
                        fontSize = 11.5.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(6.dp))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        if (isEthToGreg) {
                            ethiopianMonths.forEach { (m, nameAm, nameEn) ->
                                MonthPill(
                                    number = m,
                                    primaryName = if (isGeezScript) nameAm else nameEn,
                                    secondaryName = if (isGeezScript) nameEn else nameAm,
                                    isSelected = ethMonth == m,
                                    onClick = {
                                        ethMonth = m
                                        val max = EthiopianDate.daysInMonth(ethYear, m)
                                        if (ethDay > max) ethDay = max
                                    }
                                )
                            }
                        } else {
                            gregorianMonths.forEach { (m, nameEn, nameAm) ->
                                MonthPill(
                                    number = m,
                                    primaryName = nameEn,
                                    secondaryName = nameAm,
                                    isSelected = gregMonth == m,
                                    onClick = {
                                        gregMonth = m
                                        val max = GregorianDate.daysInMonth(gregYear, m)
                                        if (gregDay > max) gregDay = max
                                    }
                                )
                            }
                        }
                    }

                    // Pagume or February leap notice
                    if (isEthToGreg && ethMonth == 13) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = if (isEthLeap) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = if (isEthLeap) "⭐ Pagume $ethYear has 6 days (Leap Year / ዘመነ ሉቃስ)" else "ℹ️ Pagume $ethYear has 5 days (Common Year)",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = if (isEthLeap) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                            )
                        }
                    } else if (!isEthToGreg && gregMonth == 2) {
                        val isGLeap = LeapYearCalculator.isGregorianLeapYear(gregYear)
                        Spacer(modifier = Modifier.height(8.dp))
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = if (isGLeap) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = if (isGLeap) "⭐ February $gregYear has 29 days (Leap Year)" else "ℹ️ February $gregYear has 28 days (Common Year)",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = if (isGLeap) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // DAY STEPPER
                    val currentDay = if (isEthToGreg) ethDay else gregDay
                    val maxDays = if (isEthToGreg) maxEthDays else maxGregDays

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = if (isGeezScript) "ቀን (Day)" else "Day",
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "1 – $maxDays",
                                fontSize = 10.5.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f)
                            )
                        }

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            DayStepPill(label = "-7") {
                                if (isEthToGreg) ethDay = (ethDay - 7).coerceIn(1, maxDays)
                                else gregDay = (gregDay - 7).coerceIn(1, maxDays)
                            }
                            DayStepPill(label = "-1") {
                                if (isEthToGreg) ethDay = (ethDay - 1).coerceIn(1, maxDays)
                                else gregDay = (gregDay - 1).coerceIn(1, maxDays)
                            }

                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier
                                    .size(48.dp)
                                    .clip(RoundedCornerShape(12.dp))
                                    .clickable {
                                        if (isEthToGreg) showEthGridPicker = true
                                        else showGregMaterialPicker = true
                                    }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        text = currentDay.toString(),
                                        fontSize = 20.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.onPrimary
                                    )
                                }
                            }

                            DayStepPill(label = "+1") {
                                if (isEthToGreg) ethDay = (ethDay + 1).coerceIn(1, maxDays)
                                else gregDay = (gregDay + 1).coerceIn(1, maxDays)
                            }
                            DayStepPill(label = "+7") {
                                if (isEthToGreg) ethDay = (ethDay + 7).coerceIn(1, maxDays)
                                else gregDay = (gregDay + 7).coerceIn(1, maxDays)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // NOTABLE HOLIDAY PRESETS
                    Text(
                        text = if (isGeezScript) "ታዋቂ በዓላት (Presets)" else "Notable Presets",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        if (isEthToGreg) {
                            listOf(
                                "🇪🇹 Enkutatash (1/1)" to (1 to 1),
                                "✝️ Meskel (1/17)" to (1 to 17),
                                "🎄 Genna (4/29)" to (4 to 29),
                                "🕊️ Timket (5/11)" to (5 to 11),
                                "⚔️ Adwa (6/23)" to (6 to 23),
                                "🌸 Fasika (8/12)" to (8 to 12)
                            ).forEach { (label, pair) ->
                                FilterChip(
                                    selected = ethMonth == pair.first && ethDay == pair.second,
                                    onClick = {
                                        ethMonth = pair.first
                                        ethDay = pair.second.coerceIn(1, EthiopianDate.daysInMonth(ethYear, pair.first))
                                    },
                                    label = { Text(label, fontSize = 11.sp) }
                                )
                            }
                        } else {
                            listOf(
                                "New Year (Jan 1)" to (1 to 1),
                                "Genna (Jan 7)" to (1 to 7),
                                "Timket (Jan 19)" to (1 to 19),
                                "Adwa (Mar 2)" to (3 to 2),
                                "Eth. New Year (Sep 11)" to (9 to 11),
                                "Meskel (Sep 27)" to (9 to 27)
                            ).forEach { (label, pair) ->
                                FilterChip(
                                    selected = gregMonth == pair.first && gregDay == pair.second,
                                    onClick = {
                                        gregMonth = pair.first
                                        gregDay = pair.second.coerceIn(1, GregorianDate.daysInMonth(gregYear, pair.first))
                                    },
                                    label = { Text(label, fontSize = 11.sp) }
                                )
                            }
                        }
                    }
                }
            }
        }

        // 2.5 FLOATING SWAP BRIDGE
        item {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
                )

                Surface(
                    shape = RoundedCornerShape(24.dp),
                    color = MaterialTheme.colorScheme.primary,
                    shadowElevation = 4.dp,
                    modifier = Modifier
                        .minimumInteractiveComponentSize()
                        .clip(RoundedCornerShape(24.dp))
                        .clickable { performSwap() }
                        .testTag("swap_converter_direction")
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.SwapVert,
                            contentDescription = "Swap Direction",
                            tint = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier
                                .size(20.dp)
                                .rotate(animatedRotation)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (isEthToGreg) "Swap to Greg ➔ Eth" else "Swap to Eth ➔ Greg",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    }
                }
            }
        }

        // 3. CONVERSION RESULT HERO CARD (Theme-aware High-Contrast Gradient Surface)
        item {
            ElevatedCard(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("converter_result_card")
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.55f),
                                    MaterialTheme.colorScheme.surfaceVariant
                                )
                            )
                        )
                        .padding(18.dp)
                ) {
                    Column {
                        // Header + Relative Badge
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(MaterialTheme.colorScheme.secondary)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = if (isEthToGreg) "CONVERTED GREGORIAN" else "CONVERTED ETHIOPIAN",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = MaterialTheme.colorScheme.primary,
                                    letterSpacing = 0.8.sp
                                )
                            }

                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = MaterialTheme.colorScheme.surface
                            ) {
                                Text(
                                    text = relativeBadge,
                                    fontSize = 10.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Visual Source -> Target Bridge Pill
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = MaterialTheme.colorScheme.surface.copy(alpha = 0.85f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = if (isEthToGreg) {
                                        "🇪🇹 $ethMonthNameCurrent ${calculatedEth.day}, ${calculatedEth.year}"
                                    } else {
                                        "🌍 $gregMonthNameEn ${calculatedGreg.day}, ${calculatedGreg.year}"
                                    },
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )
                                Icon(
                                    Icons.AutoMirrored.Filled.ArrowForward,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier
                                        .padding(horizontal = 6.dp)
                                        .size(15.dp)
                                )
                                Text(
                                    text = if (isEthToGreg) {
                                        "🌍 $gregMonthNameEn ${calculatedGreg.day}, ${calculatedGreg.year}"
                                    } else {
                                        "🇪🇹 $ethMonthNameCurrent ${calculatedEth.day}, ${calculatedEth.year}"
                                    },
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Main Headline Date
                        if (isEthToGreg) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.14f)
                                ) {
                                    Text(
                                        text = dowNameEn,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = dowNameAm,
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Text(
                                text = "$gregMonthNameEn ${calculatedGreg.day}, ${calculatedGreg.year} G.C.",
                                fontSize = 25.sp,
                                fontWeight = FontWeight.Black,
                                color = MaterialTheme.colorScheme.onSurface
                            )

                            Text(
                                text = "ISO 8601: ${calculatedGreg.year}-${String.format(Locale.US, "%02d", calculatedGreg.month)}-${String.format(Locale.US, "%02d", calculatedGreg.day)}",
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        } else {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.14f)
                                ) {
                                    Text(
                                        text = dowNameCurrent,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = dowNameEn,
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Text(
                                text = "$ethMonthNameAm ${calculatedEth.day}፣ ${calculatedEth.year} ዓ.ም",
                                fontSize = 25.sp,
                                fontWeight = FontWeight.Black,
                                color = MaterialTheme.colorScheme.onSurface
                            )

                            Text(
                                text = "$ethMonthNameEn ${calculatedEth.day}, ${calculatedEth.year} E.C.",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        // Ge'ez Numeral Pill
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = MaterialTheme.colorScheme.surface,
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = "Ge'ez:",
                                        fontSize = 11.5.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = fullGeezDate,
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                }

                                TextButton(
                                    onClick = {
                                        val clip = ClipData.newPlainText("Geez Date", fullGeezDate)
                                        (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                        Toast.makeText(context, "Copied $fullGeezDate", Toast.LENGTH_SHORT).show()
                                    },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Icon(Icons.Default.ContentCopy, contentDescription = "Copy Ge'ez", modifier = Modifier.size(13.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Copy", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Primary Actions Row
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedButton(
                                onClick = {
                                    val textToCopy = if (isEthToGreg) {
                                        "$dowNameEn, $gregMonthNameEn ${calculatedGreg.day}, ${calculatedGreg.year} G.C. (${calculatedEth.day}/${calculatedEth.month}/${calculatedEth.year} E.C.)"
                                    } else {
                                        "$dowNameAm፣ $ethMonthNameAm ${calculatedEth.day}፣ ${calculatedEth.year} ዓ.ም (${calculatedGreg.day}/${calculatedGreg.month}/${calculatedGreg.year} G.C.)"
                                    }
                                    val clip = ClipData.newPlainText("Converted Date", textToCopy)
                                    (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                    Toast.makeText(context, "Date copied!", Toast.LENGTH_SHORT).show()
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(if (isGeezScript) "ቅዳ" else "Copy", fontSize = 12.sp)
                            }

                            OutlinedButton(
                                onClick = {
                                    val shareText = buildString {
                                        append("📅 EthioCal Date Conversion\n\n")
                                        append("🇪🇹 $ethMonthNameAm ${calculatedEth.day}፣ ${calculatedEth.year} ዓ.ም ($dowNameAm)\n")
                                        append("፲ $fullGeezDate\n")
                                        append("🌍 $dowNameEn, $gregMonthNameEn ${calculatedGreg.day}, ${calculatedGreg.year} G.C.\n")
                                        if (saint != null) append("✨ ${saint.nameAmharic}\n")
                                        append("🌿 ${fasting.reason}")
                                    }
                                    val sendIntent = Intent(Intent.ACTION_SEND).apply {
                                        type = "text/plain"
                                        putExtra(Intent.EXTRA_TEXT, shareText)
                                    }
                                    context.startActivity(Intent.createChooser(sendIntent, "Share Converted Date"))
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(if (isGeezScript) "አጋራ" else "Share", fontSize = 12.sp)
                            }

                            Button(
                                onClick = { onNavigateToCalendar?.invoke(calculatedEth) },
                                modifier = Modifier.weight(1.25f)
                            ) {
                                Icon(Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(if (isGeezScript) "ካላንደር" else "Calendar", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Secondary Actions: Schedule Reminder & Quick Save
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            FilledTonalButton(
                                onClick = { showAddReminderDialog = true },
                                modifier = Modifier.weight(1.1f)
                            ) {
                                Icon(Icons.Default.NotificationsActive, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(if (isGeezScript) "ማሳሰቢያ አዘጋጅ" else "Set Reminder", fontSize = 11.5.sp, fontWeight = FontWeight.Bold)
                            }

                            OutlinedButton(
                                onClick = {
                                    val defaultTitle = if (isEthToGreg) "$ethMonthNameAm ${calculatedEth.day} ማስታወሻ" else "$gregMonthNameEn ${calculatedGreg.day} Reminder"
                                    val event = EventEntity(
                                        title = defaultTitle,
                                        description = "Saved from Date Converter on ${todayEth.day}/${todayEth.month}/${todayEth.year}",
                                        category = "TASK",
                                        ethiopianYear = calculatedEth.year,
                                        ethiopianMonth = calculatedEth.month,
                                        ethiopianDay = calculatedEth.day,
                                        gregorianYear = calculatedGreg.year,
                                        gregorianMonth = calculatedGreg.month,
                                        gregorianDay = calculatedGreg.day,
                                        hour = 9,
                                        minute = 0,
                                        isAllDay = true,
                                        reminderMinutesBefore = 0,
                                        colorHex = "#10B981"
                                    )
                                    viewModel.saveEvent(event)
                                    Toast.makeText(context, "Saved to My Events!", Toast.LENGTH_SHORT).show()
                                },
                                modifier = Modifier.weight(0.9f)
                            ) {
                                Icon(Icons.Default.Today, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(if (isGeezScript) "አስቀምጥ" else "Quick Save", fontSize = 11.5.sp)
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        // 1-Tap Copy Format Chips
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            listOf(
                                "🇪🇹 አማርኛ" to "$dowNameAm፣ $ethMonthNameAm ${calculatedEth.day}፣ ${calculatedEth.year} ዓ.ም",
                                "🌍 English" to "$dowNameEn, $gregMonthNameEn ${calculatedGreg.day}, ${calculatedGreg.year} G.C.",
                                "፲ Ge'ez" to fullGeezDate,
                                "📋 ISO 8601" to "${calculatedGreg.year}-${String.format(Locale.US, "%02d", calculatedGreg.month)}-${String.format(Locale.US, "%02d", calculatedGreg.day)}"
                            ).forEach { (label, text) ->
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = MaterialTheme.colorScheme.surface,
                                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .clickable {
                                            val clip = ClipData.newPlainText(label, text)
                                            (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                            Toast.makeText(context, "Copied: $text", Toast.LENGTH_SHORT).show()
                                        }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 5.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(11.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(label, fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Medium)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. ACCORDION 1: LITURGICAL & CULTURAL INSIGHTS
        item {
            ExpandableDetailCard(
                title = if (isGeezScript) "የዕለቱ ባሕላዊ እና መንፈሳዊ መረጃ" else "Cultural & Liturgical Insights",
                subtitle = "Fasting, Saint observance, Evangelist & Season",
                icon = "✨",
                isExpanded = showCulturalDetails,
                onToggle = { showCulturalDetails = !showCulturalDetails }
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Fasting Status:", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (fasting.isFasting) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surfaceVariant
                        ) {
                            Text(
                                text = if (fasting.isFasting) "🌿 ${fasting.reason}" else "🍽️ Non-fasting",
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (fasting.isFasting) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Daily Saint:", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(
                            text = if (saint != null) "✨ ${if (isGeezScript) saint.nameAmharic else saint.nameEnglish}" else "Regular Day",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Evangelist Year:", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(
                            text = evangelistName,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Ethiopian Season:", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(
                            text = "${season.emoji} ${season.englishName} (${season.amharicName})",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }

                    if (holidays.isNotEmpty()) {
                        holidays.forEach { h ->
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.primaryContainer,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("🎉", fontSize = 14.sp)
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "${h.titleEnglish} (${h.titleAmharic})",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 5. ACCORDION 2: INTERNATIONAL DATE FORMATS
        item {
            ExpandableDetailCard(
                title = if (isGeezScript) "ዓለምአቀፍ የቀን አቀማመጦች" else "International Date Formats",
                subtitle = "ISO 8601, UK/EU, US & Julian Day Number",
                icon = "🌐",
                isExpanded = showWorldFormats,
                onToggle = { showWorldFormats = !showWorldFormats }
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    FormatRow(label = "ISO 8601 (YYYY-MM-DD)", value = "${calculatedGreg.year}-${String.format(Locale.US, "%02d", calculatedGreg.month)}-${String.format(Locale.US, "%02d", calculatedGreg.day)}")
                    FormatRow(label = "UK / Europe (DD/MM/YYYY)", value = "${String.format(Locale.US, "%02d", calculatedGreg.day)}/${String.format(Locale.US, "%02d", calculatedGreg.month)}/${calculatedGreg.year}")
                    FormatRow(label = "United States (MM/DD/YYYY)", value = "${String.format(Locale.US, "%02d", calculatedGreg.month)}/${String.format(Locale.US, "%02d", calculatedGreg.day)}/${calculatedGreg.year}")
                    FormatRow(label = "Julian Day Number (JDN)", value = jdn.toString())
                }
            }
        }

        // 6. ACCORDION 3: OTHER CALENDAR SYSTEMS
        item {
            val worldCalendars = remember(calculatedEth, calculatedGreg, jdn) {
                WorldCountryEngine.computeEuropeanAndWorldCalendarDetails(calculatedEth, calculatedGreg, jdn)
            }

            ExpandableDetailCard(
                title = if (isGeezScript) "ተጓዳኝ የዓለም ካላንደሮች" else "Equivalent World Calendars",
                subtitle = "Islamic Hijri, Coptic & Julian calendars",
                icon = "🏛️",
                isExpanded = showOtherCalendars,
                onToggle = { showOtherCalendars = !showOtherCalendars }
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    FormatRow(label = "🌙 Islamic Hijri", value = worldCalendars.hijriDateStr)
                    FormatRow(label = "☦️ Coptic Calendar", value = "${worldCalendars.copticDay}/${calculatedEth.month}/${worldCalendars.copticYear} A.M.")
                    FormatRow(label = "📜 Julian Calendar", value = "${worldCalendars.julianDay}/${worldCalendars.julianMonth}/${worldCalendars.julianYear} O.S.")
                }
            }
        }
    }

    if (showYearInputDialog) {
        AlertDialog(
            onDismissRequest = { showYearInputDialog = false },
            title = {
                Text(
                    text = if (isEthToGreg) "Enter Ethiopian Year (E.C.)" else "Enter Gregorian Year (G.C.)",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column {
                    Text(
                        text = "Enter any year from 1 to 9999.",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = yearInputText,
                        onValueChange = { yearInputText = it },
                        singleLine = true,
                        label = { Text("Year") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    yearInputText.toIntOrNull()?.let { y ->
                        if (y in 1..9999) {
                            if (isEthToGreg) ethYear = y
                            else gregYear = y
                        }
                    }
                    showYearInputDialog = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showYearInputDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showEthGridPicker) {
        AlertDialog(
            onDismissRequest = { showEthGridPicker = false },
            title = {
                Text(
                    text = "${LocaleStrings.getMonthName(ethMonth, currentLang)} $ethYear ዓ.ም",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column {
                    Text(
                        text = "Tap any day to select:",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(7),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                        modifier = Modifier.height(240.dp)
                    ) {
                        items((1..maxEthDays).toList()) { d ->
                            val isSelected = d == ethDay
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .clickable {
                                        ethDay = d
                                        showEthGridPicker = false
                                    }
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        text = d.toString(),
                                        fontSize = 12.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                        color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
                                    )
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showEthGridPicker = false }) {
                    Text("Close")
                }
            }
        )
    }

    if (showGregMaterialPicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                set(gregYear, gregMonth - 1, gregDay, 12, 0, 0)
            }.timeInMillis
        )
        DatePickerDialog(
            onDismissRequest = { showGregMaterialPicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                            timeInMillis = millis
                        }
                        gregYear = cal.get(Calendar.YEAR)
                        gregMonth = cal.get(Calendar.MONTH) + 1
                        gregDay = cal.get(Calendar.DAY_OF_MONTH)
                    }
                    showGregMaterialPicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showGregMaterialPicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    if (showAddReminderDialog) {
        AddEditEventDialog(
            initialDate = calculatedEth,
            eventToEdit = null,
            currentLanguage = currentLang,
            onDismiss = { showAddReminderDialog = false },
            onSave = { newEvent ->
                viewModel.saveEvent(newEvent)
                showAddReminderDialog = false
                Toast.makeText(context, "Event & reminder scheduled!", Toast.LENGTH_SHORT).show()
            }
        )
    }
}

@Composable
private fun MonthPill(
    number: Int,
    primaryName: String,
    secondaryName: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f),
        border = BorderStroke(
            1.dp,
            if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
        ),
        modifier = Modifier
            .minimumInteractiveComponentSize()
            .clip(RoundedCornerShape(12.dp))
            .clickable { onClick() }
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp)
        ) {
            Text(
                text = "$number. $primaryName",
                fontSize = 12.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = secondaryName,
                fontSize = 9.5.sp,
                color = if (isSelected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.75f)
            )
        }
    }
}

@Composable
private fun YearStepPill(
    label: String,
    onClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
        modifier = Modifier
            .size(width = 38.dp, height = 36.dp)
            .clip(RoundedCornerShape(10.dp))
            .clickable { onClick() }
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(label, fontSize = 11.5.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
private fun DayStepPill(
    label: String,
    onClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
        modifier = Modifier
            .size(width = 38.dp, height = 38.dp)
            .clip(RoundedCornerShape(10.dp))
            .clickable { onClick() }
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(label, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
        }
    }
}

@Composable
private fun ExpandableDetailCard(
    title: String,
    subtitle: String,
    icon: String,
    isExpanded: Boolean,
    onToggle: () -> Unit,
    content: @Composable () -> Unit
) {
    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .minimumInteractiveComponentSize()
                    .clickable { onToggle() },
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(icon, fontSize = 17.sp)
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(title, fontWeight = FontWeight.Bold, fontSize = 13.5.sp, color = MaterialTheme.colorScheme.onSurface)
                        Text(subtitle, fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Icon(
                    imageVector = if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = if (isExpanded) "Collapse" else "Expand",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            AnimatedVisibility(
                visible = isExpanded,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Column(modifier = Modifier.padding(top = 10.dp)) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(1.dp)
                            .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    content()
                }
            }
        }
    }
}

@Composable
private fun FormatRow(label: String, value: String) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .clickable {
                val clip = ClipData.newPlainText(label, value)
                (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                Toast.makeText(context, "Copied: $value", Toast.LENGTH_SHORT).show()
            }
            .padding(horizontal = 4.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontSize = 11.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(value, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
            Spacer(modifier = Modifier.width(6.dp))
            Icon(Icons.Default.ContentCopy, contentDescription = "Copy", modifier = Modifier.size(13.dp), tint = MaterialTheme.colorScheme.primary)
        }
    }
}
