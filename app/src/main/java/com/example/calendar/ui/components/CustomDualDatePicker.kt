package com.example.calendar.ui.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.AssistChip
import androidx.compose.material3.BasicAlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.DialogProperties
import com.example.calendar.core.GeezNumeral
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.domain.EthiopianCalendarDomain
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import java.util.Calendar

/**
 * Custom Date Picker component that seamlessly toggles between
 * the Ethiopian Calendar (🇪🇹 የኢትዮጵያ) and the Gregorian Calendar (🌍 ጎርጎሪያን).
 *
 * Provides bidirectional live-synchronization, tactile day grid selection,
 * month/year navigators, leap-year validation, and quick steppers.
 */
@Composable
fun CustomDualDatePicker(
    initialDate: EthiopianDate,
    initialFormat: String = "ETHIOPIAN", // "ETHIOPIAN" or "GREGORIAN"
    todayEthiopian: EthiopianDate,
    currentLang: AppLanguage = AppLanguage.AMHARIC,
    isSundayFirst: Boolean = true,
    onDateConfirmed: (selectedEthiopianDate: EthiopianDate, selectedFormat: String) -> Unit,
    onDismiss: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    // Current format mode in the date picker: "ETHIOPIAN" or "GREGORIAN"
    var pickerFormat by remember { mutableStateOf(initialFormat) }
    val isEthMode = pickerFormat == "ETHIOPIAN"

    // Ethiopian active selection
    var ethYear by remember { mutableIntStateOf(initialDate.year) }
    var ethMonth by remember { mutableIntStateOf(initialDate.month) }
    var ethDay by remember { mutableIntStateOf(initialDate.day) }

    // Gregorian active selection
    val initialGreg = remember(initialDate) { EthiopianCalendarEngine.toGregorian(initialDate) }
    var gregYear by remember { mutableIntStateOf(initialGreg.year) }
    var gregMonth by remember { mutableIntStateOf(initialGreg.month) }
    var gregDay by remember { mutableIntStateOf(initialGreg.day) }

    // Dropdown/Year edit states
    var showMonthMenu by remember { mutableStateOf(false) }
    var showYearEditor by remember { mutableStateOf(false) }
    var tempYearInput by remember { mutableStateOf(if (isEthMode) ethYear.toString() else gregYear.toString()) }

    // Helper: Days in current month
    val domain = EthiopianCalendarDomain.INSTANCE
    val ethMaxDays = remember(ethYear, ethMonth) {
        domain.getDaysInMonth(ethYear, ethMonth)
    }

    val gregMaxDays = remember(gregYear, gregMonth) {
        when (gregMonth) {
            1, 3, 5, 7, 8, 10, 12 -> 31
            4, 6, 9, 11 -> 30
            2 -> if (LeapYearCalculator.isGregorianLeapYear(gregYear)) 29 else 28
            else -> 30
        }
    }

    // Synchronize functions when switching modes
    fun syncEthToGreg(y: Int, m: Int, d: Int) {
        val safeDay = d.coerceIn(1, domain.getDaysInMonth(y, m))
        val greg = EthiopianCalendarEngine.toGregorian(EthiopianDate(y, m, safeDay))
        gregYear = greg.year
        gregMonth = greg.month
        gregDay = greg.day
    }

    fun syncGregToEth(y: Int, m: Int, d: Int) {
        val maxDays = when (m) {
            1, 3, 5, 7, 8, 10, 12 -> 31
            4, 6, 9, 11 -> 30
            2 -> if (LeapYearCalculator.isGregorianLeapYear(y)) 29 else 28
            else -> 30
        }
        val safeDay = d.coerceIn(1, maxDays)
        val eth = EthiopianCalendarEngine.toEthiopian(GregorianDate(y, m, safeDay))
        ethYear = eth.year
        ethMonth = eth.month
        ethDay = eth.day
    }

    // Calculate current day of week and corresponding representations
    val activeEthiopianDate = remember(ethYear, ethMonth, ethDay) {
        val safeDay = ethDay.coerceIn(1, domain.getDaysInMonth(ethYear, ethMonth))
        EthiopianDate(ethYear, ethMonth, safeDay)
    }

    val activeGregorianDate = remember(gregYear, gregMonth, gregDay) {
        val maxD = when (gregMonth) {
            1, 3, 5, 7, 8, 10, 12 -> 31
            4, 6, 9, 11 -> 30
            2 -> if (LeapYearCalculator.isGregorianLeapYear(gregYear)) 29 else 28
            else -> 30
        }
        val safeDay = gregDay.coerceIn(1, maxD)
        GregorianDate(gregYear, gregMonth, safeDay)
    }

    // Active Day of Week
    val activeDow = remember(isEthMode, activeEthiopianDate, activeGregorianDate) {
        if (isEthMode) {
            EthiopianCalendarEngine.getDayOfWeek(activeEthiopianDate)
        } else {
            val cal = Calendar.getInstance().apply {
                set(Calendar.YEAR, activeGregorianDate.year)
                set(Calendar.MONTH, activeGregorianDate.month - 1)
                set(Calendar.DAY_OF_MONTH, activeGregorianDate.day)
            }
            when (cal.get(Calendar.DAY_OF_WEEK)) {
                Calendar.SUNDAY -> 1
                Calendar.MONDAY -> 2
                Calendar.TUESDAY -> 3
                Calendar.WEDNESDAY -> 4
                Calendar.THURSDAY -> 5
                Calendar.FRIDAY -> 6
                Calendar.SATURDAY -> 7
                else -> 1
            }
        }
    }

    // Associated Evangelist & Season
    val evangelist = remember(ethYear) { LeapYearCalculator.getEvangelist(ethYear) }

    // Holidays for selected date
    val holidaysOnDate = remember(activeEthiopianDate) {
        HolidayEngine.getHolidaysForYear(activeEthiopianDate.year).filter {
            it.ethiopianDate.month == activeEthiopianDate.month && it.ethiopianDate.day == activeEthiopianDate.day
        }
    }

    // Gregorian month names
    val gregorianMonths = listOf(
        1 to "January (ጥር)", 2 to "February (የካቲት)", 3 to "March (መጋቢት)",
        4 to "April (ሚያዝያ)", 5 to "May (ግንቦት)", 6 to "June (ሰኔ)",
        7 to "July (ሐምሌ)", 8 to "August (ነሐሴ)", 9 to "September (መስከረም)",
        10 to "October (ጥቅምት)", 11 to "November (ኅዳር)", 12 to "December (ታኅሣሥ)"
    )

    Card(
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
        modifier = modifier
            .fillMaxWidth()
            .testTag("custom_dual_date_picker")
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp)
        ) {
            // ==============================================================
            // 1. TOP FORMAT TOGGLE (ETHIOPIAN 🇪🇹 vs GREGORIAN 🌍)
            // ==============================================================
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("date_picker_format_toggle")
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(3.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    // Ethiopian Button
                    Surface(
                        shape = RoundedCornerShape(11.dp),
                        color = if (isEthMode) MaterialTheme.colorScheme.primary else Color.Transparent,
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(11.dp))
                            .clickable {
                                if (!isEthMode) {
                                    syncGregToEth(gregYear, gregMonth, gregDay)
                                    pickerFormat = "ETHIOPIAN"
                                }
                            }
                            .testTag("date_picker_toggle_ethiopian")
                    ) {
                        Row(
                            modifier = Modifier.padding(vertical = 7.dp, horizontal = 8.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(text = "🇪🇹", fontSize = 14.sp)
                            Spacer(modifier = Modifier.width(6.dp))
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = "የኢትዮጵያ (ET)",
                                    fontSize = 11.5.sp,
                                    fontWeight = if (isEthMode) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isEthMode) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = "Ethiopian Format",
                                    fontSize = 8.5.sp,
                                    color = if (isEthMode) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                                )
                            }
                        }
                    }

                    // Gregorian Button
                    Surface(
                        shape = RoundedCornerShape(11.dp),
                        color = if (!isEthMode) MaterialTheme.colorScheme.primary else Color.Transparent,
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(11.dp))
                            .clickable {
                                if (isEthMode) {
                                    syncEthToGreg(ethYear, ethMonth, ethDay)
                                    pickerFormat = "GREGORIAN"
                                }
                            }
                            .testTag("date_picker_toggle_gregorian")
                    ) {
                        Row(
                            modifier = Modifier.padding(vertical = 7.dp, horizontal = 8.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(text = "🌍", fontSize = 14.sp)
                            Spacer(modifier = Modifier.width(6.dp))
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = "ጎርጎሪያን (GC)",
                                    fontSize = 11.5.sp,
                                    fontWeight = if (!isEthMode) FontWeight.Bold else FontWeight.Medium,
                                    color = if (!isEthMode) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = "Gregorian Format",
                                    fontSize = 8.5.sp,
                                    color = if (!isEthMode) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // ==============================================================
            // 2. MONTH & YEAR NAVIGATOR BAR
            // ==============================================================
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.45f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 6.dp, vertical = 5.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Previous Month Button
                    IconButton(
                        onClick = {
                            if (isEthMode) {
                                if (ethMonth == 1) {
                                    ethMonth = 13
                                    ethYear -= 1
                                } else {
                                    ethMonth -= 1
                                }
                                val maxD = domain.getDaysInMonth(ethYear, ethMonth)
                                if (ethDay > maxD) ethDay = maxD
                                syncEthToGreg(ethYear, ethMonth, ethDay)
                            } else {
                                if (gregMonth == 1) {
                                    gregMonth = 12
                                    gregYear -= 1
                                } else {
                                    gregMonth -= 1
                                }
                                val maxD = when (gregMonth) {
                                    1, 3, 5, 7, 8, 10, 12 -> 31
                                    4, 6, 9, 11 -> 30
                                    2 -> if (LeapYearCalculator.isGregorianLeapYear(gregYear)) 29 else 28
                                    else -> 30
                                }
                                if (gregDay > maxD) gregDay = maxD
                                syncGregToEth(gregYear, gregMonth, gregDay)
                            }
                        },
                        modifier = Modifier.size(38.dp)
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Previous Month",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }

                    // Month & Year Clickable Selector
                    Box(modifier = Modifier.weight(1f)) {
                        Row(
                            modifier = Modifier
                                .align(Alignment.Center)
                                .clip(RoundedCornerShape(8.dp))
                                .clickable { showMonthMenu = true }
                                .padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            val displayMonthName = if (isEthMode) {
                                LocaleStrings.getMonthName(ethMonth, currentLang)
                            } else {
                                gregorianMonths.firstOrNull { it.first == gregMonth }?.second?.split(" ")?.firstOrNull() ?: "Month"
                            }
                            val displayYear = if (isEthMode) "$ethYear ዓ.ም" else "$gregYear G.C."

                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = "$displayMonthName $displayYear",
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                Text(
                                    text = if (isEthMode) "ዘመነ ${evangelist.amharicName}" else "Ethiopian: ${activeEthiopianDate.month}/${activeEthiopianDate.day}/${activeEthiopianDate.year}",
                                    fontSize = 10.sp,
                                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.85f)
                                )
                            }
                            Spacer(modifier = Modifier.width(3.dp))
                            Text(
                                text = "▾",
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        // Month Selection Dropdown
                        DropdownMenu(
                            expanded = showMonthMenu,
                            onDismissRequest = { showMonthMenu = false }
                        ) {
                            if (isEthMode) {
                                (1..13).forEach { m ->
                                    DropdownMenuItem(
                                        text = {
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Text(
                                                    text = "${m}. ${LocaleStrings.getMonthName(m, currentLang)}",
                                                    fontWeight = if (m == ethMonth) FontWeight.Bold else FontWeight.Normal,
                                                    color = if (m == ethMonth) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                                                )
                                                if (m == 13) {
                                                    Text(
                                                        text = if (LeapYearCalculator.isEthiopianLeapYear(ethYear)) "6 ቀናት" else "5 ቀናት",
                                                        fontSize = 11.sp,
                                                        color = MaterialTheme.colorScheme.secondary
                                                    )
                                                }
                                            }
                                        },
                                        onClick = {
                                            ethMonth = m
                                            val maxD = domain.getDaysInMonth(ethYear, ethMonth)
                                            if (ethDay > maxD) ethDay = maxD
                                            syncEthToGreg(ethYear, ethMonth, ethDay)
                                            showMonthMenu = false
                                        }
                                    )
                                }
                            } else {
                                gregorianMonths.forEach { (m, name) ->
                                    DropdownMenuItem(
                                        text = {
                                            Text(
                                                text = name,
                                                fontWeight = if (m == gregMonth) FontWeight.Bold else FontWeight.Normal,
                                                color = if (m == gregMonth) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                                            )
                                        },
                                        onClick = {
                                            gregMonth = m
                                            val maxD = when (gregMonth) {
                                                1, 3, 5, 7, 8, 10, 12 -> 31
                                                4, 6, 9, 11 -> 30
                                                2 -> if (LeapYearCalculator.isGregorianLeapYear(gregYear)) 29 else 28
                                                else -> 30
                                            }
                                            if (gregDay > maxD) gregDay = maxD
                                            syncGregToEth(gregYear, gregMonth, gregDay)
                                            showMonthMenu = false
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Next Month Button
                    IconButton(
                        onClick = {
                            if (isEthMode) {
                                if (ethMonth == 13) {
                                    ethMonth = 1
                                    ethYear += 1
                                } else {
                                    ethMonth += 1
                                }
                                val maxD = domain.getDaysInMonth(ethYear, ethMonth)
                                if (ethDay > maxD) ethDay = maxD
                                syncEthToGreg(ethYear, ethMonth, ethDay)
                            } else {
                                if (gregMonth == 12) {
                                    gregMonth = 1
                                    gregYear += 1
                                } else {
                                    gregMonth += 1
                                }
                                val maxD = when (gregMonth) {
                                    1, 3, 5, 7, 8, 10, 12 -> 31
                                    4, 6, 9, 11 -> 30
                                    2 -> if (LeapYearCalculator.isGregorianLeapYear(gregYear)) 29 else 28
                                    else -> 30
                                }
                                if (gregDay > maxD) gregDay = maxD
                                syncGregToEth(gregYear, gregMonth, gregDay)
                            }
                        },
                        modifier = Modifier.size(38.dp)
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowForward,
                            contentDescription = "Next Month",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // ==============================================================
            // 3. QUICK YEAR STEPPER CHIPS & "TODAY"
            // ==============================================================
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    AssistChip(
                        onClick = {
                            if (isEthMode) {
                                ethYear -= 1
                                syncEthToGreg(ethYear, ethMonth, ethDay)
                            } else {
                                gregYear -= 1
                                syncGregToEth(gregYear, gregMonth, gregDay)
                            }
                        },
                        label = { Text("-1 ዓመት", fontSize = 10.sp) }
                    )
                    AssistChip(
                        onClick = {
                            if (isEthMode) {
                                ethYear += 1
                                syncEthToGreg(ethYear, ethMonth, ethDay)
                            } else {
                                gregYear += 1
                                syncGregToEth(gregYear, gregMonth, gregDay)
                            }
                        },
                        label = { Text("+1 ዓመት", fontSize = 10.sp) }
                    )
                }

                // Quick Today Button
                FilledTonalButton(
                    onClick = {
                        ethYear = todayEthiopian.year
                        ethMonth = todayEthiopian.month
                        ethDay = todayEthiopian.day
                        syncEthToGreg(ethYear, ethMonth, ethDay)
                    },
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 10.dp, vertical = 2.dp),
                    modifier = Modifier.height(30.dp)
                ) {
                    Icon(Icons.Default.CalendarToday, contentDescription = "Today", modifier = Modifier.size(12.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("ዛሬ (Today)", fontSize = 10.5.sp, fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // ==============================================================
            // 4. WEEKDAY HEADERS
            // ==============================================================
            val weekdayLabels = if (isSundayFirst) {
                listOf("እሑ", "ሰኞ", "ማክ", "ረቡ", "ሐሙ", "ዓር", "ቅዳ")
            } else {
                listOf("ሰኞ", "ማክ", "ረቡ", "ሐሙ", "ዓር", "ቅዳ", "እሑ")
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                weekdayLabels.forEachIndexed { index, label ->
                    val isWeekend = if (isSundayFirst) (index == 0 || index == 6) else (index >= 5)
                    Text(
                        text = label,
                        fontSize = 11.5.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (isWeekend) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                }
            }

            // ==============================================================
            // 5. 7-COLUMN TACTILE DAY SELECTION GRID
            // ==============================================================
            val daysInCurrentMonth = if (isEthMode) ethMaxDays else gregMaxDays

            // Calculate starting day of the week for Day 1
            val firstDayDow = remember(isEthMode, ethYear, ethMonth, gregYear, gregMonth) {
                if (isEthMode) {
                    EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(ethYear, ethMonth, 1))
                } else {
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, gregYear)
                        set(Calendar.MONTH, gregMonth - 1)
                        set(Calendar.DAY_OF_MONTH, 1)
                    }
                    when (cal.get(Calendar.DAY_OF_WEEK)) {
                        Calendar.SUNDAY -> 1
                        Calendar.MONDAY -> 2
                        Calendar.TUESDAY -> 3
                        Calendar.WEDNESDAY -> 4
                        Calendar.THURSDAY -> 5
                        Calendar.FRIDAY -> 6
                        Calendar.SATURDAY -> 7
                        else -> 1
                    }
                }
            }

            // Lead padding cells (0 to 6)
            val leadEmptyCells = if (isSundayFirst) {
                (firstDayDow - 1).coerceAtLeast(0)
            } else {
                (if (firstDayDow == 1) 6 else firstDayDow - 2).coerceAtLeast(0)
            }

            val totalGridCells = leadEmptyCells + daysInCurrentMonth
            val rowCount = kotlin.math.ceil(totalGridCells / 7.0).toInt()

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                for (row in 0 until rowCount) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        for (col in 0 until 7) {
                            val cellIndex = row * 7 + col
                            val dayNumber = cellIndex - leadEmptyCells + 1

                            if (cellIndex < leadEmptyCells || dayNumber > daysInCurrentMonth) {
                                // Empty placeholder cell
                                Box(modifier = Modifier.weight(1f).aspectRatio(1.1f))
                            } else {
                                val isSelected = if (isEthMode) (dayNumber == ethDay) else (dayNumber == gregDay)
                                val isToday = if (isEthMode) {
                                    (ethYear == todayEthiopian.year && ethMonth == todayEthiopian.month && dayNumber == todayEthiopian.day)
                                } else {
                                    val tg = EthiopianCalendarEngine.toGregorian(todayEthiopian)
                                    (gregYear == tg.year && gregMonth == tg.month && dayNumber == tg.day)
                                }

                                // Secondary cross-calendar day number
                                val secondaryDay = remember(isEthMode, ethYear, ethMonth, gregYear, gregMonth, dayNumber) {
                                    if (isEthMode) {
                                        val g = EthiopianCalendarEngine.toGregorian(EthiopianDate(ethYear, ethMonth, dayNumber))
                                        g.day.toString()
                                    } else {
                                        val maxD = when (gregMonth) {
                                            1, 3, 5, 7, 8, 10, 12 -> 31
                                            4, 6, 9, 11 -> 30
                                            2 -> if (LeapYearCalculator.isGregorianLeapYear(gregYear)) 29 else 28
                                            else -> 30
                                        }
                                        val safeD = dayNumber.coerceIn(1, maxD)
                                        val e = EthiopianCalendarEngine.toEthiopian(GregorianDate(gregYear, gregMonth, safeD))
                                        e.day.toString()
                                    }
                                }

                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = when {
                                        isSelected -> MaterialTheme.colorScheme.primary
                                        isToday -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                                        else -> Color.Transparent
                                    },
                                    border = if (isToday && !isSelected) {
                                        androidx.compose.foundation.BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary)
                                    } else null,
                                    modifier = Modifier
                                        .weight(1f)
                                        .aspectRatio(1.1f)
                                        .clip(RoundedCornerShape(10.dp))
                                        .clickable {
                                            if (isEthMode) {
                                                ethDay = dayNumber
                                                syncEthToGreg(ethYear, ethMonth, ethDay)
                                            } else {
                                                gregDay = dayNumber
                                                syncGregToEth(gregYear, gregMonth, gregDay)
                                            }
                                        }
                                        .testTag("day_cell_${dayNumber}")
                                ) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalArrangement = Arrangement.Center,
                                        modifier = Modifier.padding(2.dp)
                                    ) {
                                        Text(
                                            text = dayNumber.toString(),
                                            fontSize = 13.5.sp,
                                            fontWeight = if (isSelected || isToday) FontWeight.ExtraBold else FontWeight.Medium,
                                            color = when {
                                                isSelected -> MaterialTheme.colorScheme.onPrimary
                                                isToday -> MaterialTheme.colorScheme.primary
                                                else -> MaterialTheme.colorScheme.onSurface
                                            }
                                        )
                                        // Small secondary dual date representation
                                        Text(
                                            text = secondaryDay,
                                            fontSize = 8.5.sp,
                                            color = when {
                                                isSelected -> MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                                                else -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // ==============================================================
            // 6. REAL-TIME DUAL SYNCHRONIZATION RESULT CARD
            // ==============================================================
            ElevatedCard(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.45f)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("date_picker_result_card")
            ) {
                Column(modifier = Modifier.padding(10.dp)) {
                    val weekdayName = LocaleStrings.getWeekdayLong(activeDow, currentLang)

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            // Primary Active Date
                            Text(
                                text = if (isEthMode) {
                                    "🇪🇹 ${activeEthiopianDate.day} ${LocaleStrings.getMonthName(activeEthiopianDate.month, currentLang)} ${activeEthiopianDate.year} ዓ.ም"
                                } else {
                                    "🌍 ${activeGregorianDate.day} ${gregorianMonths.firstOrNull { it.first == activeGregorianDate.month }?.second?.split(" ")?.firstOrNull()} ${activeGregorianDate.year} G.C."
                                },
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.onSecondaryContainer
                            )

                            // Cross-Calendar Synchronized Date
                            Text(
                                text = if (isEthMode) {
                                    "👉 ጎርጎሪያን (GC): ${activeGregorianDate.day} ${gregorianMonths.firstOrNull { it.first == activeGregorianDate.month }?.second?.split(" ")?.firstOrNull()} ${activeGregorianDate.year} • $weekdayName"
                                } else {
                                    val geezDay = GeezNumeral.toGeez(activeEthiopianDate.day)
                                    val geezYear = GeezNumeral.toGeez(activeEthiopianDate.year)
                                    "👉 የኢትዮጵያ (ET): $geezDay ${LocaleStrings.getMonthName(activeEthiopianDate.month, currentLang)} $geezYear ዓ.ም • $weekdayName"
                                },
                                fontSize = 11.5.sp,
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        // Ge'ez Numeral Pill
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                            modifier = Modifier.padding(start = 6.dp)
                        ) {
                            Text(
                                text = GeezNumeral.toGeez(activeEthiopianDate.day),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }
                    }

                    // Holiday badge if present
                    if (holidaysOnDate.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        holidaysOnDate.take(1).forEach { h ->
                            Text(
                                text = "✨ ${h.titleAmharic} (${h.titleEnglish})",
                                fontSize = 10.5.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (h.isPublicHoliday) Color(0xFFDC2626) else MaterialTheme.colorScheme.primary,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // ==============================================================
            // 7. CONFIRM & CANCEL ACTIONS
            // ==============================================================
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (onDismiss != null) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.testTag("date_picker_cancel_button")
                    ) {
                        Text("ሰርዝ (Cancel)", fontSize = 13.sp)
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                }

                Button(
                    onClick = {
                        onDateConfirmed(activeEthiopianDate, pickerFormat)
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.testTag("date_picker_confirm_button")
                ) {
                    Icon(Icons.Default.Check, contentDescription = "Confirm", modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "ቀን ምረጥ (Select Date)",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

/**
 * Modal Dialog wrapper for the [CustomDualDatePicker].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DualCalendarDatePickerDialog(
    initialDate: EthiopianDate,
    initialFormat: String = "ETHIOPIAN",
    todayEthiopian: EthiopianDate,
    currentLang: AppLanguage = AppLanguage.AMHARIC,
    isSundayFirst: Boolean = true,
    onDismissRequest: () -> Unit,
    onDateSelected: (selectedDate: EthiopianDate, selectedFormat: String) -> Unit
) {
    BasicAlertDialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(usePlatformDefaultWidth = false),
        modifier = Modifier
            .fillMaxWidth(0.95f)
            .padding(vertical = 16.dp),
        content = {
            CustomDualDatePicker(
                initialDate = initialDate,
                initialFormat = initialFormat,
                todayEthiopian = todayEthiopian,
                currentLang = currentLang,
                isSundayFirst = isSundayFirst,
                onDateConfirmed = { date, format ->
                    onDateSelected(date, format)
                    onDismissRequest()
                },
                onDismiss = onDismissRequest
            )
        }
    )
}
