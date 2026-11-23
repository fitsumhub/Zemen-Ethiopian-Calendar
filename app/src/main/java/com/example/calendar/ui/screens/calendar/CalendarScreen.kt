package com.example.calendar.ui.screens.calendar

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CalendarToday
import com.example.calendar.ui.components.CustomDualDatePicker
import com.example.calendar.ui.components.DualCalendarDatePickerDialog
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import com.example.calendar.core.GeezNumeral
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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
import android.content.Intent
import androidx.compose.ui.platform.LocalContext
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.DailyHeritageEngine
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel
import com.example.calendar.ui.screens.events.AddEditEventDialog
import com.example.calendar.ui.screens.home.EventListItem

/**
 * Returns a short English abbreviation for Gregorian month number (1..12).
 */
private fun getGregorianMonthAbbr(month: Int): String {
    return when (month) {
        1 -> "Jan"
        2 -> "Feb"
        3 -> "Mar"
        4 -> "Apr"
        5 -> "May"
        6 -> "Jun"
        7 -> "Jul"
        8 -> "Aug"
        9 -> "Sep"
        10 -> "Oct"
        11 -> "Nov"
        12 -> "Dec"
        else -> ""
    }
}

/**
 * Computes the Gregorian month/year range that corresponds to an Ethiopian month.
 */
private fun getGregorianRangeForEthMonth(year: Int, month: Int): String {
    val gStart = EthiopianCalendarEngine.toGregorian(EthiopianDate(year, month, 1))
    val daysInMonth = EthiopianDate.daysInMonth(year, month)
    val gEnd = EthiopianCalendarEngine.toGregorian(EthiopianDate(year, month, daysInMonth))

    val startAbbr = getGregorianMonthAbbr(gStart.month)
    val endAbbr = getGregorianMonthAbbr(gEnd.month)

    return if (gStart.year == gEnd.year) {
        if (gStart.month == gEnd.month) {
            "$startAbbr ${gStart.year}"
        } else {
            "$startAbbr – $endAbbr ${gStart.year}"
        }
    } else {
        "$startAbbr ${gStart.year} – $endAbbr ${gEnd.year}"
    }
}

@Composable
fun CalendarScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val settings by viewModel.userSettings.collectAsState()
    val currentLang = viewModel.currentAppLanguage()
    val isSundayStart = settings.firstDayOfWeek == "SUNDAY"

    val viewYear by viewModel.viewYear.collectAsState()
    val viewMonth by viewModel.viewMonth.collectAsState()
    val selectedDate by viewModel.selectedDate.collectAsState()
    val viewMode by viewModel.calendarViewMode.collectAsState()

    val allEvents by viewModel.allEvents.collectAsState()
    val yearHolidays by viewModel.holidaysForViewYear.collectAsState()

    var showAddEventDialog by remember { mutableStateOf(false) }
    var eventToEdit by remember { mutableStateOf<EventEntity?>(null) }
    var showMonthYearPickerDialog by remember { mutableStateOf(false) }
    var showDualDatePickerDialog by remember { mutableStateOf(false) }
    var isInlinePickerExpanded by remember { mutableStateOf(false) }

    val monthName = LocaleStrings.getMonthName(viewMonth, currentLang)
    val todayEth = viewModel.todayEthiopian
    val gregRangeText = remember(viewYear, viewMonth) {
        getGregorianRangeForEthMonth(viewYear, viewMonth)
    }
    val evangelist = remember(viewYear) {
        LeapYearCalculator.getEvangelist(viewYear)
    }

    val calendarFormat = settings.calendarFormat
    val isGregorianFormat = calendarFormat == "GREGORIAN"

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 14.dp)
    ) {
        // 1. Visual Date Format Toggle Component (Ethiopian 🇪🇹 vs Gregorian 🌍)
        CalendarFormatToggle(
            currentFormat = calendarFormat,
            onFormatSelected = { viewModel.setCalendarFormat(it) },
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp, bottom = 4.dp)
        )

        // 2. View Mode Switcher: Month, Week, Year, Day
        Surface(
            shape = RoundedCornerShape(14.dp),
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 4.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(3.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                listOf(
                    "MONTH" to ("ወር" to "Month"),
                    "WEEK" to ("ሳምንት" to "Week"),
                    "YEAR" to ("ዓመት" to "Year"),
                    "DAY" to ("ቀን" to "Day")
                ).forEach { (mode, labels) ->
                    val isSelected = viewMode == mode
                    Surface(
                        shape = RoundedCornerShape(11.dp),
                        color = if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent,
                        modifier = Modifier
                            .weight(1f)
                            .clickable { viewModel.setCalendarViewMode(mode) }
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                            modifier = Modifier.padding(vertical = 6.dp)
                        ) {
                            Text(
                                text = labels.first,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = labels.second,
                                fontSize = 9.sp,
                                color = if (isSelected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
            }
        }

        // 3. Month & Year Navigation Card with Dual-Calendar Clarity
        val isCurrentMonthAndYear = viewYear == todayEth.year && viewMonth == todayEth.month
        val englishMonthName = if (viewMonth in 1..13) LocaleStrings.ETHIOPIAN_MONTHS_ENGLISH[viewMonth - 1] else ""

        ElevatedCard(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.elevatedCardColors(
                containerColor = MaterialTheme.colorScheme.surface
            ),
            elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 6.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Prev Button
                IconButton(
                    onClick = {
                        if (viewMode == "YEAR") viewModel.prevYear() else viewModel.prevMonth()
                    },
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Previous Month/Year",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                // Month & Year Header (Tapping opens Dual Calendar Date Picker Dialog)
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.55f),
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 4.dp)
                        .clickable { showDualDatePickerDialog = true }
                        .testTag("calendar_month_year_header_picker")
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 6.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = if (isGregorianFormat) {
                                    if (viewMode == "YEAR") "Year $viewYear E.C. (GC)" else "$gregRangeText G.C."
                                } else {
                                    if (viewMode == "YEAR") "$viewYear ዓ.ም" else "$monthName $viewYear ዓ.ም"
                                },
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                            Spacer(modifier = Modifier.width(3.dp))
                            Text(
                                text = "▾",
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        // Corresponding English name, Gregorian Month Range + Evangelist
                        Text(
                            text = if (isGregorianFormat) {
                                if (viewMode == "YEAR") "ዘመነ ${evangelist.amharicName}" else "$monthName $viewYear ዓ.ም ($englishMonthName) • ዘመነ ${evangelist.amharicName}"
                            } else {
                                if (viewMode == "YEAR") "ዘመነ ${evangelist.amharicName}" else "$englishMonthName • $gregRangeText"
                            },
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.9f),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(3.dp)
                ) {
                    // Go to Today Button
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = if (!isCurrentMonthAndYear) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f),
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .clickable { viewModel.goToToday() }
                            .testTag("calendar_go_to_today_button")
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 7.dp, vertical = 6.dp)
                        ) {
                            Icon(
                                Icons.Default.CalendarToday,
                                contentDescription = "Go to Today",
                                tint = if (!isCurrentMonthAndYear) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(13.dp)
                            )
                            Spacer(modifier = Modifier.width(3.dp))
                            Text(
                                text = "ዛሬ",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (!isCurrentMonthAndYear) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }

                    // Pick Date Button (Toggles Inline Custom Date Picker within main view)
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = if (isInlinePickerExpanded) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp,
                            if (isInlinePickerExpanded) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                        ),
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .clickable { isInlinePickerExpanded = !isInlinePickerExpanded }
                            .testTag("toggle_custom_date_picker_button")
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 7.dp, vertical = 6.dp)
                        ) {
                            Icon(
                                Icons.Default.CalendarMonth,
                                contentDescription = "Custom Date Picker",
                                tint = if (isInlinePickerExpanded) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(13.dp)
                            )
                            Spacer(modifier = Modifier.width(3.dp))
                            Text(
                                text = "ቀን ምረጥ",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (isInlinePickerExpanded) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    // Next Button
                    IconButton(
                        onClick = {
                            if (viewMode == "YEAR") viewModel.nextYear() else viewModel.nextMonth()
                        },
                        modifier = Modifier.size(40.dp)
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowForward,
                            contentDescription = "Next Month/Year",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }

        // Custom Dual Calendar Date Picker (Inline seamlessly within the main view)
        AnimatedVisibility(
            visible = isInlinePickerExpanded,
            enter = androidx.compose.animation.expandVertically() + androidx.compose.animation.fadeIn(),
            exit = androidx.compose.animation.shrinkVertically() + androidx.compose.animation.fadeOut()
        ) {
            CustomDualDatePicker(
                initialDate = selectedDate,
                initialFormat = calendarFormat,
                todayEthiopian = todayEth,
                currentLang = currentLang,
                isSundayFirst = isSundayStart,
                onDateConfirmed = { pickedDate, pickedFormat ->
                    viewModel.selectDate(pickedDate)
                    if (pickedFormat != calendarFormat) {
                        viewModel.setCalendarFormat(pickedFormat)
                    }
                    isInlinePickerExpanded = false
                },
                onDismiss = { isInlinePickerExpanded = false },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
            )
        }

        // Return to Today Quick Notice (Displays when user browses away from current month/year)
        if (!isCurrentMonthAndYear && viewMode == "MONTH") {
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp)
                    .clickable { viewModel.goToToday() }
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "ዛሬ: ${LocaleStrings.getMonthName(todayEth.month, currentLang)} ${todayEth.day}፣ ${todayEth.year} ዓ.ም",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text(
                        text = "ወደ ዛሬ ተመለስ ➜",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }

        // 3. Pagume (13th Month) Explanatory Banner
        if (viewMonth == 13 && viewMode != "YEAR") {
            val isLeap = LeapYearCalculator.isEthiopianLeapYear(viewYear)
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.5f),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 6.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = "Pagume Info",
                        tint = MaterialTheme.colorScheme.onTertiaryContainer,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "ጳጉሜ (13ኛው ወር) — በዚህ ዓመት ${if (isLeap) "6 ቀናት (ዘመነ ሉቃስ)" else "5 ቀናት"} አሉት።",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onTertiaryContainer
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // 4. View content based on viewMode
        when (viewMode) {
            "MONTH" -> {
                MonthViewContent(
                    year = viewYear,
                    month = viewMonth,
                    selectedDate = selectedDate,
                    todayDate = viewModel.todayEthiopian,
                    isSundayStart = isSundayStart,
                    currentLang = currentLang,
                    numeralType = settings.numeralType,
                    calendarFormat = calendarFormat,
                    events = allEvents,
                    holidays = yearHolidays,
                    onSelectDate = { viewModel.selectDate(it) },
                    onAddEvent = {
                        eventToEdit = null
                        showAddEventDialog = true
                    },
                    onEditEvent = { ev ->
                        eventToEdit = ev
                        showAddEventDialog = true
                    }
                )
            }
            "WEEK" -> {
                WeekViewContent(
                    centerDate = selectedDate,
                    todayDate = viewModel.todayEthiopian,
                    currentLang = currentLang,
                    calendarFormat = calendarFormat,
                    events = allEvents,
                    holidays = yearHolidays,
                    onSelectDate = { viewModel.selectDate(it) },
                    onAddEvent = {
                        eventToEdit = null
                        showAddEventDialog = true
                    }
                )
            }
            "YEAR" -> {
                YearViewContent(
                    year = viewYear,
                    selectedDate = selectedDate,
                    todayDate = viewModel.todayEthiopian,
                    currentLang = currentLang,
                    calendarFormat = calendarFormat,
                    isSundayStart = isSundayStart,
                    onSelectMonth = { m ->
                        viewModel.setMonthAndYear(viewYear, m)
                        viewModel.setCalendarViewMode("MONTH")
                    },
                    onSelectDate = { d ->
                        viewModel.selectDate(d)
                        viewModel.setCalendarViewMode("DAY")
                    },
                    onPrevYear = { viewModel.prevYear() },
                    onNextYear = { viewModel.nextYear() }
                )
            }
            "DAY" -> {
                DayViewContent(
                    date = selectedDate,
                    todayDate = viewModel.todayEthiopian,
                    currentLang = currentLang,
                    calendarFormat = calendarFormat,
                    events = allEvents,
                    holidays = yearHolidays,
                    onAddEvent = {
                        eventToEdit = null
                        showAddEventDialog = true
                    },
                    onEditEvent = { ev ->
                        eventToEdit = ev
                        showAddEventDialog = true
                    },
                    onToggleEvent = { viewModel.toggleEventCompletion(it) },
                    onDeleteEvent = { viewModel.deleteEvent(it) },
                    onSelectDate = { viewModel.selectDate(it) }
                )
            }
        }
    }

    // Interactive Dual Calendar Date Picker Dialog
    if (showDualDatePickerDialog) {
        DualCalendarDatePickerDialog(
            initialDate = selectedDate,
            initialFormat = calendarFormat,
            todayEthiopian = todayEth,
            currentLang = currentLang,
            isSundayFirst = isSundayStart,
            onDismissRequest = { showDualDatePickerDialog = false },
            onDateSelected = { pickedDate, pickedFormat ->
                viewModel.selectDate(pickedDate)
                if (pickedFormat != calendarFormat) {
                    viewModel.setCalendarFormat(pickedFormat)
                }
                showDualDatePickerDialog = false
            }
        )
    }

    // Interactive Month & Year Navigator Dialog
    if (showMonthYearPickerDialog) {
        MonthYearNavigatorDialog(
            currentYear = viewYear,
            currentMonth = viewMonth,
            todayYear = todayEth.year,
            currentLang = currentLang,
            onDismiss = { showMonthYearPickerDialog = false },
            onSelect = { selectedYear, selectedMonth ->
                viewModel.setMonthAndYear(selectedYear, selectedMonth)
                showMonthYearPickerDialog = false
            }
        )
    }

    // Add / Edit Event Dialog
    if (showAddEventDialog) {
        AddEditEventDialog(
            initialDate = selectedDate,
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
}

/**
 * Clean, interactive modal for switching Ethiopian months and years instantly.
 */
@Composable
private fun MonthYearNavigatorDialog(
    currentYear: Int,
    currentMonth: Int,
    todayYear: Int,
    currentLang: AppLanguage,
    onDismiss: () -> Unit,
    onSelect: (year: Int, month: Int) -> Unit
) {
    var dialogYear by remember { mutableStateOf(currentYear) }
    var customYearInput by remember { mutableStateOf(currentYear.toString()) }
    var isEditingYear by remember { mutableStateOf(false) }

    val gregorianRangeList = listOf(
        "Sep – Oct", "Oct – Nov", "Nov – Dec", "Dec – Jan",
        "Jan – Feb", "Feb – Mar", "Mar – Apr", "Apr – May",
        "May – Jun", "Jun – Jul", "Jul – Aug", "Aug – Sep",
        "Sep (5/6d)"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Column {
                Text(
                    text = "ወርና ዓመት ይምረጡ (Select Month & Year)",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "የሚፈልጉትን ወር ጠቅ በማድረግ በቀላሉ ይክፈቱ",
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                // Year Stepper Bar
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 6.dp, vertical = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(
                            onClick = {
                                dialogYear -= 1
                                customYearInput = dialogYear.toString()
                            },
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(Icons.Default.ChevronLeft, contentDescription = "Year - 1")
                        }

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.clickable { isEditingYear = !isEditingYear }
                        ) {
                            Text(
                                text = "$dialogYear ዓ.ም",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("✏️", fontSize = 11.sp)
                        }

                        IconButton(
                            onClick = {
                                dialogYear += 1
                                customYearInput = dialogYear.toString()
                            },
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(Icons.Default.ChevronRight, contentDescription = "Year + 1")
                        }
                    }
                }

                // Optional Custom Year Text Input
                if (isEditingYear) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        OutlinedTextField(
                            value = customYearInput,
                            onValueChange = { customYearInput = it },
                            label = { Text("ዓመት (Year)") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        Button(
                            onClick = {
                                customYearInput.toIntOrNull()?.let { y ->
                                    if (y in 1..9999) {
                                        dialogYear = y
                                        isEditingYear = false
                                    }
                                }
                            }
                        ) {
                            Text("ቀይር")
                        }
                    }
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Quick Year Jumps Row
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    listOf(
                        "ዛሬ ($todayYear)" to todayYear,
                        "+5" to todayYear + 5,
                        "+10" to todayYear + 10,
                        "+25" to todayYear + 25,
                        "-5" to todayYear - 5,
                        "-10" to todayYear - 10
                    ).forEach { (label, targetY) ->
                        FilterChip(
                            selected = dialogYear == targetY,
                            onClick = {
                                dialogYear = targetY
                                customYearInput = targetY.toString()
                            },
                            label = { Text(label, fontSize = 10.sp) },
                            colors = FilterChipDefaults.filterChipColors()
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "13ቱ የኢትዮጵያ ወራት (13 Ethiopian Months):",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(6.dp))

                // Grid of 13 Months with Gregorian translations
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(260.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    items((1..13).toList()) { m ->
                        val isSelected = m == currentMonth && dialogYear == currentYear
                        val mName = LocaleStrings.getMonthName(m, currentLang)
                        val gSpan = gregorianRangeList[m - 1]

                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = when {
                                isSelected -> MaterialTheme.colorScheme.primary
                                m == 13 -> MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.6f)
                                else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onSelect(dialogYear, m) }
                        ) {
                            Column(
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 6.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "$m. $mName",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = gSpan,
                                    fontSize = 9.sp,
                                    color = if (isSelected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("ዝጋ (Close)")
            }
        }
    )
}

/**
 * Calendar Month View with crystal-clear date numbers, dual-dates, and informative legend.
 */
@Composable
private fun MonthViewContent(
    year: Int,
    month: Int,
    selectedDate: EthiopianDate,
    todayDate: EthiopianDate,
    isSundayStart: Boolean,
    currentLang: AppLanguage,
    numeralType: String = "ARABIC",
    calendarFormat: String = "ETHIOPIAN",
    events: List<EventEntity>,
    holidays: List<HolidayEngine.Holiday>,
    onSelectDate: (EthiopianDate) -> Unit,
    onAddEvent: () -> Unit,
    onEditEvent: (EventEntity) -> Unit
) {
    val daysInMonth = EthiopianDate.daysInMonth(year, month)
    val firstDayOfWeek = EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(year, month, 1))
    val isGreg = calendarFormat == "GREGORIAN"

    // Weekdays header order
    val weekDaysOrder = if (isSundayStart) {
        listOf(7, 1, 2, 3, 4, 5, 6)
    } else {
        listOf(1, 2, 3, 4, 5, 6, 7)
    }

    val offset = if (isSundayStart) {
        if (firstDayOfWeek == 7) 0 else firstDayOfWeek
    } else {
        firstDayOfWeek - 1
    }

    val totalCells = offset + daysInMonth

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Weekday Header Row with Dual Language clarity & Sunday highlight
        item {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceAround
                ) {
                    weekDaysOrder.forEach { dow ->
                        val isSunday = dow == 7
                        val isSaturday = dow == 6
                        val primaryWd = if (isGreg) LocaleStrings.WEEKDAYS_ENGLISH_SHORT[dow - 1] else LocaleStrings.getWeekdayShort(dow, currentLang)
                        val secondaryWd = if (isGreg) LocaleStrings.getWeekdayShort(dow, currentLang) else LocaleStrings.WEEKDAYS_ENGLISH_SHORT[dow - 1]
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = primaryWd,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = when {
                                    isSunday -> Color(0xFFDC2626) // Traditional Ethiopian calendar Sunday in red
                                    isSaturday -> MaterialTheme.colorScheme.primary
                                    else -> MaterialTheme.colorScheme.onSurface
                                },
                                textAlign = TextAlign.Center
                            )
                            Text(
                                text = secondaryWd,
                                fontSize = 9.sp,
                                color = when {
                                    isSunday -> Color(0xFFDC2626).copy(alpha = 0.8f)
                                    else -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                                },
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }

        // Calendar Grid Card
        item {
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(6.dp)) {
                    val rows = (totalCells + 6) / 7
                    for (row in 0 until rows) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceAround
                        ) {
                            for (col in 0..6) {
                                val cellIndex = row * 7 + col
                                val dayNum = cellIndex - offset + 1
                                if (dayNum in 1..daysInMonth) {
                                    val cellDate = EthiopianDate(year, month, dayNum)
                                    val isToday = cellDate == todayDate
                                    val isSelected = cellDate == selectedDate
                                    val gDate = EthiopianCalendarEngine.toGregorian(cellDate)

                                    val cellHolidays = holidays.filter { it.ethiopianDate == cellDate }
                                    val cellEvents = events.filter {
                                        it.ethiopianYear == year && it.ethiopianMonth == month && it.ethiopianDay == dayNum
                                    }
                                    val hasPublicHoliday = cellHolidays.any { it.isPublicHoliday }
                                    val hasReligiousHoliday = cellHolidays.any { !it.isPublicHoliday }
                                    val isFasting = HolidayEngine.isFastingDay(cellDate).isFasting

                                    val dayDisplayString = if (numeralType == "GEEZ") {
                                        GeezNumeral.toGeez(dayNum)
                                    } else {
                                        dayNum.toString()
                                    }

                                    val primaryDayText = if (isGreg) gDate.day.toString() else dayDisplayString
                                    val secondaryDayText = if (isGreg) dayDisplayString else gDate.day.toString()

                                    val cellDow = weekDaysOrder[col]

                                    Box(
                                        modifier = Modifier
                                            .weight(1f)
                                            .aspectRatio(0.85f)
                                            .padding(2.dp)
                                            .clip(RoundedCornerShape(12.dp))
                                            .background(
                                                when {
                                                    isToday && isSelected -> MaterialTheme.colorScheme.primaryContainer
                                                    isSelected -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.7f)
                                                    isToday -> MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
                                                    hasPublicHoliday -> Color(0xFFEF4444).copy(alpha = 0.08f)
                                                    else -> Color.Transparent
                                                }
                                            )
                                            .border(
                                                width = when {
                                                    isToday && isSelected -> 2.5.dp
                                                    isSelected -> 2.dp
                                                    isToday -> 2.dp
                                                    else -> 0.dp
                                                },
                                                color = when {
                                                    isToday && isSelected -> MaterialTheme.colorScheme.primary
                                                    isSelected -> MaterialTheme.colorScheme.primary
                                                    isToday -> MaterialTheme.colorScheme.primary
                                                    else -> Color.Transparent
                                                },
                                                shape = RoundedCornerShape(12.dp)
                                            )
                                            .clickable { onSelectDate(cellDate) }
                                            .testTag("day_cell_${dayNum}"),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Column(
                                            horizontalAlignment = Alignment.CenterHorizontally,
                                            verticalArrangement = Arrangement.Center,
                                            modifier = Modifier.padding(1.dp)
                                        ) {
                                            // DISTINCT CIRCLE HIGHLIGHT FOR TODAY'S DATE
                                            Box(
                                                modifier = Modifier
                                                    .size(30.dp)
                                                    .clip(CircleShape)
                                                    .background(
                                                        when {
                                                            isToday -> MaterialTheme.colorScheme.primary // Distinct circle highlight
                                                            isSelected -> MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                                                            else -> Color.Transparent
                                                        }
                                                    ),
                                                contentAlignment = Alignment.Center
                                            ) {
                                                Text(
                                                    text = primaryDayText,
                                                    fontSize = if (!isGreg && numeralType == "GEEZ") 12.sp else 15.sp,
                                                    fontWeight = if (isToday || isSelected) FontWeight.ExtraBold else FontWeight.Bold,
                                                    color = when {
                                                        isToday -> MaterialTheme.colorScheme.onPrimary // Standout crisp text on distinct primary circle!
                                                        isSelected -> MaterialTheme.colorScheme.primary
                                                        hasPublicHoliday -> Color(0xFFDC2626)
                                                        cellDow == 7 -> Color(0xFFDC2626) // Sunday in red
                                                        else -> MaterialTheme.colorScheme.onSurface
                                                    }
                                                )
                                            }

                                            // Secondary Day Number (Muted Subtext)
                                            Text(
                                                text = secondaryDayText,
                                                fontSize = 9.sp,
                                                fontWeight = FontWeight.Medium,
                                                color = when {
                                                    isSelected -> MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.85f)
                                                    isToday -> MaterialTheme.colorScheme.primary
                                                    cellDow == 7 -> Color(0xFFDC2626).copy(alpha = 0.7f)
                                                    else -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                                                }
                                            )

                                            // Status Indicator Dots
                                            Row(
                                                modifier = Modifier.padding(top = 2.dp),
                                                horizontalArrangement = Arrangement.spacedBy(2.dp)
                                            ) {
                                                if (hasPublicHoliday) {
                                                    Box(
                                                        modifier = Modifier
                                                            .size(4.dp)
                                                            .clip(CircleShape)
                                                            .background(Color(0xFFEF4444))
                                                    )
                                                }
                                                if (hasReligiousHoliday) {
                                                    Box(
                                                        modifier = Modifier
                                                            .size(4.dp)
                                                            .clip(CircleShape)
                                                            .background(Color(0xFF8B5CF6))
                                                    )
                                                }
                                                if (cellEvents.isNotEmpty()) {
                                                    Box(
                                                        modifier = Modifier
                                                            .size(4.dp)
                                                            .clip(CircleShape)
                                                            .background(Color(0xFFF59E0B))
                                                    )
                                                }
                                                if (isFasting) {
                                                    Box(
                                                        modifier = Modifier
                                                            .size(3.5.dp)
                                                            .clip(CircleShape)
                                                            .background(Color(0xFF10B981))
                                                    )
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    Spacer(modifier = Modifier.weight(1f).aspectRatio(0.85f))
                                }
                            }
                        }
                    }
                }
            }
        }

        // Calendar Legend (Clear explanation of Today, Holidays, Feasts, Events, and Fasting)
        item {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 6.dp)
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    LegendItem(color = MaterialTheme.colorScheme.primary, label = if (isGreg) "🔵 Today (ዛሬ)" else "🔵 ዛሬ (Today)")
                    Spacer(modifier = Modifier.width(10.dp))
                    LegendItem(color = Color(0xFFEF4444), label = if (isGreg) "🔴 Holiday" else "🔴 በዓል (Holiday)")
                    Spacer(modifier = Modifier.width(10.dp))
                    LegendItem(color = Color(0xFF8B5CF6), label = if (isGreg) "🟣 Feast" else "🟣 ሃይማኖታዊ (Feast)")
                    Spacer(modifier = Modifier.width(10.dp))
                    LegendItem(color = Color(0xFFF59E0B), label = if (isGreg) "🟡 Event" else "🟡 ማስታወሻ (Event)")
                    Spacer(modifier = Modifier.width(10.dp))
                    LegendItem(color = Color(0xFF10B981), label = if (isGreg) "🟢 Fasting" else "🟢 ጾም (Fasting)")
                }
            }
        }

        // Selected Date Inspector Card
        item {
            val selDow = EthiopianCalendarEngine.getDayOfWeek(selectedDate)
            val selGDate = EthiopianCalendarEngine.toGregorian(selectedDate)
            val selHolidays = holidays.filter { it.ethiopianDate == selectedDate }
            val selEvents = events.filter {
                it.ethiopianYear == selectedDate.year && it.ethiopianMonth == selectedDate.month && it.ethiopianDay == selectedDate.day
            }
            val selSaint = HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == selectedDate.day }
            val selFasting = HolidayEngine.isFastingDay(selectedDate)
            val isToday = selectedDate == todayDate
            val daysDiff = EthiopianCalendarEngine.daysBetween(todayDate, selectedDate)
            val geezDayNum = GeezNumeral.toGeez(selectedDate.day)
            val relativeLabel = if (isGreg) {
                when {
                    daysDiff == 0L -> "⭐ Today (ዛሬ)"
                    daysDiff == 1L -> "Tomorrow (ነገ)"
                    daysDiff == -1L -> "Yesterday (ትናንት)"
                    daysDiff > 1L -> "In $daysDiff days"
                    else -> "${-daysDiff} days ago"
                }
            } else {
                when {
                    daysDiff == 0L -> "⭐ ዛሬ (Today)"
                    daysDiff == 1L -> "ነገ (Tomorrow)"
                    daysDiff == -1L -> "ትናንት (Yesterday)"
                    daysDiff > 1L -> "ከ $daysDiff ቀናት በኋላ (In $daysDiff days)"
                    else -> "ከ ${-daysDiff} ቀናት በፊት (${-daysDiff} days ago)"
                }
            }

            val headlineText = if (isGreg) {
                "${LocaleStrings.WEEKDAYS_ENGLISH_LONG[selDow - 1]}, ${getGregorianMonthAbbr(selGDate.month)} ${selGDate.day}, ${selGDate.year} G.C."
            } else {
                "${LocaleStrings.getMonthName(selectedDate.month, currentLang)} ${selectedDate.day} ($geezDayNum)፣ ${selectedDate.year} ዓ.ም"
            }

            val sublineText = if (isGreg) {
                "${LocaleStrings.getMonthName(selectedDate.month, currentLang)} ${selectedDate.day} ($geezDayNum)፣ ${selectedDate.year} ዓ.ም • ${LocaleStrings.getWeekdayLong(selDow, currentLang)}"
            } else {
                "${LocaleStrings.getWeekdayLong(selDow, currentLang)} (${LocaleStrings.WEEKDAYS_ENGLISH_LONG[selDow - 1]}) • ${selGDate.day} ${getGregorianMonthAbbr(selGDate.month)} ${selGDate.year} G.C."
            }

            ElevatedCard(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 3.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Header Row: Full Date + Relative Badge
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = headlineText,
                                    fontSize = 17.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = if (isToday) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f)
                                ) {
                                    Text(
                                        text = relativeLabel,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isToday) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimaryContainer,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }

                            Text(
                                text = sublineText,
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        // Add Event Button
                        IconButton(
                            onClick = onAddEvent,
                            modifier = Modifier
                                .size(38.dp)
                                .background(MaterialTheme.colorScheme.primaryContainer, CircleShape)
                        ) {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = "Add Event",
                                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Daily Fasting & Saint Observance Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Fasting Chip
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (selFasting.isFasting) Color(0xFF10B981).copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.weight(1f)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = if (selFasting.isFasting) "🐟 ጾም ነው" else "🍽️ ፍስክ ነው",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (selFasting.isFasting) Color(0xFF047857) else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        // Daily Saint Chip
                        if (selSaint != null) {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.5f),
                                modifier = Modifier.weight(1f)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "✨ ${selSaint.nameAmharic}",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onSecondaryContainer,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }
                        }
                    }

                    // Holidays on this day
                    if (selHolidays.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(10.dp))
                        selHolidays.forEach { h ->
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (h.isPublicHoliday) Color(0xFFEF4444).copy(alpha = 0.12f) else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f),
                                border = androidx.compose.foundation.BorderStroke(
                                    1.dp,
                                    if (h.isPublicHoliday) Color(0xFFEF4444).copy(alpha = 0.4f) else MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
                                ),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 3.dp)
                            ) {
                                Column(modifier = Modifier.padding(10.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = if (h.isPublicHoliday) "🔴 የሕዝብ በዓል: " else "🟣 ",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (h.isPublicHoliday) Color(0xFFDC2626) else MaterialTheme.colorScheme.primary
                                        )
                                        Text(
                                            text = "${h.titleAmharic} (${h.titleEnglish})",
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (h.isPublicHoliday) Color(0xFFDC2626) else MaterialTheme.colorScheme.onPrimaryContainer
                                        )
                                    }
                                    if (h.description.isNotEmpty()) {
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = h.description,
                                            fontSize = 11.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Events on this day
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "የቀኑ ማስታወሻዎች (Events & Notes):",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(4.dp))

                    if (selEvents.isEmpty()) {
                        Text(
                            text = "ምንም የተመዘገበ ማስታወሻ የለም። ማስታወሻ ለማስቀመጥ የ + ምልክቱን ይጫኑ።",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        selEvents.forEach { ev ->
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 2.dp)
                                    .clickable { onEditEvent(ev) }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("📌", fontSize = 12.sp)
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = ev.title,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = MaterialTheme.colorScheme.onSurface,
                                        modifier = Modifier.weight(1f),
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                    if (ev.reminderMinutesBefore >= 0 && !ev.isCompleted) {
                                        val alertTime = com.example.calendar.notification.NotificationScheduler.formatClock12h(ev.hour, ev.minute)
                                        Surface(
                                            shape = RoundedCornerShape(6.dp),
                                            color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.7f),
                                            modifier = Modifier.padding(horizontal = 4.dp)
                                        ) {
                                            Text(
                                                text = "🔔 $alertTime",
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                            )
                                        }
                                    }
                                    Text(
                                        text = if (ev.isAllDay) "ሙሉ ቀን" else com.example.calendar.notification.NotificationScheduler.formatClock12h(ev.hour, ev.minute),
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun LegendItem(color: Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(7.dp)
                .clip(CircleShape)
                .background(color)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = label,
            fontSize = 10.sp,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Week View Content with dual-date cards and event markers.
 */
@Composable
private fun WeekViewContent(
    centerDate: EthiopianDate,
    todayDate: EthiopianDate,
    currentLang: AppLanguage,
    calendarFormat: String = "ETHIOPIAN",
    events: List<EventEntity>,
    holidays: List<HolidayEngine.Holiday>,
    onSelectDate: (EthiopianDate) -> Unit,
    onAddEvent: () -> Unit
) {
    val centerJdn = EthiopianCalendarEngine.ethiopianToJdn(centerDate)
    val centerDow = EthiopianCalendarEngine.getDayOfWeek(centerDate)
    val startOfWeekJdn = centerJdn - (centerDow - 1)

    val weekDates = (0..6).map { offset ->
        EthiopianCalendarEngine.jdnToEthiopian(startOfWeekJdn + offset)
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(weekDates) { date ->
            val isToday = date == todayDate
            val isSelected = date == centerDate
            val dow = EthiopianCalendarEngine.getDayOfWeek(date)
            val gDate = EthiopianCalendarEngine.toGregorian(date)
            val dayHolidays = holidays.filter { it.ethiopianDate == date }
            val dayEvents = events.filter {
                it.ethiopianYear == date.year && it.ethiopianMonth == date.month && it.ethiopianDay == date.day
            }

            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
                ),
                border = androidx.compose.foundation.BorderStroke(
                    width = if (isToday) 1.5.dp else 1.dp,
                    color = if (isToday) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onSelectDate(date) }
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(42.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (isToday) MaterialTheme.colorScheme.primary
                                        else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = date.day.toString(),
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isToday) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.primary
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text(
                                    text = "${LocaleStrings.getWeekdayLong(dow, currentLang)} • ${LocaleStrings.getMonthName(date.month, currentLang)}",
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "${gDate.day} ${getGregorianMonthAbbr(gDate.month)} ${gDate.year} G.C.",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        if (isToday) {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.primary
                            ) {
                                Text(
                                    text = "⭐ ዛሬ (Today)",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimary,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                )
                            }
                        }
                    }

                    if (dayHolidays.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(6.dp))
                        dayHolidays.forEach { h ->
                            Text(
                                text = "🎉 ${h.titleAmharic}",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium,
                                color = if (h.isPublicHoliday) Color(0xFFEF4444) else MaterialTheme.colorScheme.primary
                            )
                        }
                    }

                    if (dayEvents.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        dayEvents.forEach { ev ->
                            Text(
                                text = "📌 ${ev.title}",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Year View Content showing all 13 months with interactive mini calendar grids,
 * Gregorian coverage, and Pagume highlight.
 */
@Composable
private fun YearViewContent(
    year: Int,
    selectedDate: EthiopianDate,
    todayDate: EthiopianDate,
    currentLang: AppLanguage,
    calendarFormat: String = "ETHIOPIAN",
    isSundayStart: Boolean = false,
    onSelectMonth: (Int) -> Unit,
    onSelectDate: (EthiopianDate) -> Unit,
    onPrevYear: () -> Unit,
    onNextYear: () -> Unit
) {
    val evangelist = LeapYearCalculator.getEvangelist(year)
    val isLeap = LeapYearCalculator.isEthiopianLeapYear(year)
    var viewStyle by remember { mutableStateOf("MINI_CALENDARS") } // "MINI_CALENDARS" or "TILES"

    val gregorianRangeList = listOf(
        "Sep – Oct", "Oct – Nov", "Nov – Dec", "Dec – Jan",
        "Jan – Feb", "Feb – Mar", "Mar – Apr", "Apr – May",
        "May – Jun", "Jun – Jul", "Jul – Aug", "Aug – Sep",
        "Sep (5/6d)"
    )

    val weekDaysOrder = if (isSundayStart) {
        listOf(7, 1, 2, 3, 4, 5, 6)
    } else {
        listOf(1, 2, 3, 4, 5, 6, 7)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Year Navigator Header
        ElevatedCard(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.elevatedCardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 6.dp)
        ) {
            Column(modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onPrevYear, modifier = Modifier.size(36.dp)) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous Year")
                    }

                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "$year ዓመተ ምሕረት",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Text(
                            text = "ዘመነ ${evangelist.amharicName} • ${if (isLeap) "ዘመነ ሉቃስ (ጳጉሜን 6)" else "ጳጉሜን 5 ቀናት"}",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.85f)
                        )
                    }

                    IconButton(onClick = onNextYear, modifier = Modifier.size(36.dp)) {
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next Year")
                    }
                }
            }
        }

        // View Style Toggle: Mini Calendars vs Tiles
        Surface(
            shape = RoundedCornerShape(10.dp),
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(2.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (viewStyle == "MINI_CALENDARS") MaterialTheme.colorScheme.primary else Color.Transparent,
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { viewStyle = "MINI_CALENDARS" }
                ) {
                    Text(
                        text = "📅 ዓውደ ወራት (13 Mini Calendars)",
                        fontSize = 11.sp,
                        fontWeight = if (viewStyle == "MINI_CALENDARS") FontWeight.Bold else FontWeight.Medium,
                        color = if (viewStyle == "MINI_CALENDARS") MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(vertical = 5.dp)
                    )
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (viewStyle == "TILES") MaterialTheme.colorScheme.primary else Color.Transparent,
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { viewStyle = "TILES" }
                ) {
                    Text(
                        text = "🗂️ ዝርዝር ወራት (Month Cards)",
                        fontSize = 11.sp,
                        fontWeight = if (viewStyle == "TILES") FontWeight.Bold else FontWeight.Medium,
                        color = if (viewStyle == "TILES") MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(vertical = 5.dp)
                    )
                }
            }
        }

        if (viewStyle == "MINI_CALENDARS") {
            // 2-Column Year-at-a-Glance with 13 Complete Mini Monthly Calendars
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 80.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items((1..13).toList()) { m ->
                    val monthDays = EthiopianDate.daysInMonth(year, m)
                    val firstDow = EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(year, m, 1))
                    val isCurrentMonth = todayDate.year == year && todayDate.month == m
                    val gSpan = gregorianRangeList[m - 1]
                    val mName = LocaleStrings.getMonthName(m, currentLang)

                    val offset = if (isSundayStart) {
                        if (firstDow == 7) 0 else firstDow
                    } else {
                        firstDow - 1
                    }
                    val totalCells = offset + monthDays
                    val totalRows = (totalCells + 6) / 7

                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = when {
                                isCurrentMonth -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)
                                m == 13 -> MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.35f)
                                else -> MaterialTheme.colorScheme.surface
                            }
                        ),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp,
                            if (isCurrentMonth) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                        ),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(8.dp)
                        ) {
                            // Month Header
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(6.dp))
                                    .clickable { onSelectMonth(m) }
                                    .padding(vertical = 2.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = "$m. $mName",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isCurrentMonth) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                                    )
                                }
                                Text(
                                    text = gSpan,
                                    fontSize = 9.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            Spacer(modifier = Modifier.height(4.dp))

                            // Mini Weekday Headers
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceAround
                            ) {
                                weekDaysOrder.forEach { dow ->
                                    val isSun = dow == 7
                                    val shortLabel = LocaleStrings.getWeekdayShort(dow, currentLang).take(1)
                                    Text(
                                        text = shortLabel,
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isSun) Color(0xFFDC2626) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                                        textAlign = TextAlign.Center,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(3.dp))

                            // Mini Days Grid
                            Column(modifier = Modifier.fillMaxWidth()) {
                                for (row in 0 until totalRows) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceAround
                                    ) {
                                        for (col in 0..6) {
                                            val cellIdx = row * 7 + col
                                            val dayNum = cellIdx - offset + 1
                                            if (dayNum in 1..monthDays) {
                                                val cellDate = EthiopianDate(year, m, dayNum)
                                                val isToday = cellDate == todayDate
                                                val isSelected = cellDate == selectedDate
                                                val cellDow = weekDaysOrder[col]
                                                val isSun = cellDow == 7

                                                Box(
                                                    modifier = Modifier
                                                        .weight(1f)
                                                        .aspectRatio(1f)
                                                        .padding(1.dp)
                                                        .clip(CircleShape)
                                                        .background(
                                                            when {
                                                                isToday -> MaterialTheme.colorScheme.primary
                                                                isSelected -> MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                                                                else -> Color.Transparent
                                                            }
                                                        )
                                                        .clickable { onSelectDate(cellDate) },
                                                    contentAlignment = Alignment.Center
                                                ) {
                                                    Text(
                                                        text = dayNum.toString(),
                                                        fontSize = 9.sp,
                                                        fontWeight = if (isToday || isSelected) FontWeight.Bold else FontWeight.Normal,
                                                        color = when {
                                                            isToday -> MaterialTheme.colorScheme.onPrimary
                                                            isSelected -> MaterialTheme.colorScheme.primary
                                                            isSun -> Color(0xFFDC2626)
                                                            else -> MaterialTheme.colorScheme.onSurface
                                                        },
                                                        textAlign = TextAlign.Center
                                                    )
                                                }
                                            } else {
                                                Spacer(modifier = Modifier.weight(1f).aspectRatio(1f))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // 3-Column Month Tiles
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 80.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items((1..13).toList()) { m ->
                    val monthDays = EthiopianDate.daysInMonth(year, m)
                    val isCurrentMonth = todayDate.year == year && todayDate.month == m
                    val gSpan = gregorianRangeList[m - 1]

                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = when {
                                isCurrentMonth -> MaterialTheme.colorScheme.primaryContainer
                                m == 13 -> MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.5f)
                                else -> MaterialTheme.colorScheme.surface
                            }
                        ),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp,
                            if (isCurrentMonth) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                        ),
                        modifier = Modifier
                            .aspectRatio(0.92f)
                            .clickable { onSelectMonth(m) }
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(8.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = "$m",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Text(
                                text = LocaleStrings.getMonthName(m, currentLang),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center
                            )
                            Text(
                                text = gSpan,
                                fontSize = 9.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = "$monthDays ቀናት",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f)
                            )
                            if (isCurrentMonth) {
                                Spacer(modifier = Modifier.height(3.dp))
                                Surface(
                                    shape = CircleShape,
                                    color = MaterialTheme.colorScheme.primary
                                ) {
                                    Text(
                                        text = "ዛሬ: ${todayDate.day}",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onPrimary,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Day View Content with rich hero card, fasting status, saint, Ken Qen wisdom,
 * and traditional 12-hour hourly schedule.
 */
@Composable
private fun DayViewContent(
    date: EthiopianDate,
    todayDate: EthiopianDate,
    currentLang: AppLanguage,
    calendarFormat: String = "ETHIOPIAN",
    events: List<EventEntity>,
    holidays: List<HolidayEngine.Holiday>,
    onAddEvent: () -> Unit,
    onEditEvent: (EventEntity) -> Unit,
    onToggleEvent: (EventEntity) -> Unit,
    onDeleteEvent: (EventEntity) -> Unit,
    onSelectDate: (EthiopianDate) -> Unit
) {
    val context = LocalContext.current
    val dow = EthiopianCalendarEngine.getDayOfWeek(date)
    val gDate = EthiopianCalendarEngine.toGregorian(date)
    val dayHolidays = holidays.filter { it.ethiopianDate == date }
    val dayEvents = events.filter {
        it.ethiopianYear == date.year && it.ethiopianMonth == date.month && it.ethiopianDay == date.day
    }
    val selSaint = HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == date.day }
    val selFasting = HolidayEngine.isFastingDay(date)
    val isToday = date == todayDate
    val daysDiff = EthiopianCalendarEngine.daysBetween(todayDate, date)
    val relativeLabel = when {
        daysDiff == 0L -> "⭐ ዛሬ (Today)"
        daysDiff == 1L -> "ነገ (Tomorrow)"
        daysDiff == -1L -> "ትናንት (Yesterday)"
        daysDiff > 1L -> "ከ $daysDiff ቀናት በኋላ (In $daysDiff days)"
        else -> "ከ ${-daysDiff} ቀናት በፊት (${-daysDiff} days ago)"
    }
    val geezDayNum = GeezNumeral.toGeez(date.day)
    val dailyHeritage = remember(date) { DailyHeritageEngine.getHeritageForDate(date) }

    // Traditional Ethiopian Hours (1:00 to 12:00 Daytime, 1:00 to 12:00 Nighttime)
    val traditionalHours = listOf(
        Triple(12, true, "ጥዋት 12:00 (6:00 AM) — ፀሐይ መውጫ"),
        Triple(1, true, "ጥዋት 1:00 (7:00 AM) — ንጋት"),
        Triple(2, true, "ጥዋት 2:00 (8:00 AM) — ጧት"),
        Triple(3, true, "ጥዋት 3:00 (9:00 AM) — ረፋድ"),
        Triple(4, true, "ጥዋት 4:00 (10:00 AM) — ጧት"),
        Triple(5, true, "ጥዋት 5:00 (11:00 AM) — ቀትር ዋዜማ"),
        Triple(6, true, "ቀትር 6:00 (12:00 PM) — እኩለ ቀን"),
        Triple(7, true, "ከሰዓት 7:00 (1:00 PM) — ከሰዓት"),
        Triple(8, true, "ከሰዓት 8:00 (2:00 PM) — ከሰዓት"),
        Triple(9, true, "ከሰዓት 9:00 (3:00 PM) — ድህረ ቀትር"),
        Triple(10, true, "ከሰዓት 10:00 (4:00 PM) — ከሰዓት"),
        Triple(11, true, "ከሰዓት 11:00 (5:00 PM) — ጀምበር ማዘቅዘቅ"),
        Triple(12, false, "ምሽት 12:00 (6:00 PM) — ፀሐይ መጥለቂያ"),
        Triple(1, false, "ምሽት 1:00 (7:00 PM) — ምሽት"),
        Triple(2, false, "ምሽት 2:00 (8:00 PM) — ምሽት"),
        Triple(3, false, "ምሽት 3:00 (9:00 PM) — ጀምበር ዝንባሌ"),
        Triple(4, false, "ሌሊት 4:00 (10:00 PM) — ሌሊት"),
        Triple(5, false, "ሌሊት 5:00 (11:00 PM) — ሌሊት"),
        Triple(6, false, "እኩለ ሌሊት 6:00 (12:00 AM) — እኩለ ሌሊት"),
        Triple(7, false, "ሌሊት 7:00 (1:00 AM) — ሌሊት"),
        Triple(8, false, "ሌሊት 8:00 (2:00 AM) — ሌሊት"),
        Triple(9, false, "ንጋት 9:00 (3:00 AM) — ወገግታ"),
        Triple(10, false, "ንጋት 10:00 (4:00 AM) — ጎህ"),
        Triple(11, false, "ንጋት 11:00 (5:00 AM) — ንጋት")
    )

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // 1. Day Hero Card
        item {
            ElevatedCard(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (isToday) MaterialTheme.colorScheme.primary
                                        else MaterialTheme.colorScheme.primaryContainer
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = date.day.toString(),
                                    fontSize = 20.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isToday) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.primary
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text(
                                    text = "${LocaleStrings.getMonthName(date.month, currentLang)} $geezDayNum፣ ${date.year} ዓ.ም",
                                    fontSize = 17.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Text(
                                    text = "${LocaleStrings.getWeekdayLong(dow, currentLang)} • ${gDate.day} ${getGregorianMonthAbbr(gDate.month)} ${gDate.year} G.C.",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (isToday) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f)
                        ) {
                            Text(
                                text = relativeLabel,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (isToday) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimaryContainer,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (selFasting.isFasting) Color(0xFF10B981).copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = if (selFasting.isFasting) "🐟 ጾም: ${selFasting.reason}" else "🍽️ ፍስክ ቀን",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (selFasting.isFasting) Color(0xFF047857) else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp)
                            )
                        }

                        if (selSaint != null) {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.5f),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = "✨ ${selSaint.nameAmharic}",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp)
                                )
                            }
                        }
                    }
                }
            }
        }

        // 2. Ken Qen (ቀን ቀን) Daily Wisdom & Proverb Card
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.25f)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "✨ ቀን ቀን • የዕለቱ ጥበብ",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = dailyHeritage.proverb.category,
                                fontSize = 9.5.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = "«${dailyHeritage.proverb.amharic}»",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = dailyHeritage.proverb.englishTranslation,
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "ወቅት: ${dailyHeritage.solarPhase}",
                            fontSize = 10.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                        )
                        TextButton(
                            onClick = {
                                val shareText = buildString {
                                    append("✨ የዕለቱ ጥበብ (${date.day}/${date.month}/${date.year} ዓ.ም)\n\n")
                                    append("«${dailyHeritage.proverb.amharic}»\n")
                                    append("${dailyHeritage.proverb.englishTranslation}\n\n")
                                    append("ትርጉም: ${dailyHeritage.proverb.meaning}\n\n")
                                    append("— ከኢትዮጵያ ካላንደር መተግበሪያ")
                                }
                                val sendIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, shareText)
                                }
                                context.startActivity(Intent.createChooser(sendIntent, "ጥበብ አጋራ"))
                            },
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Text("አጋራ ↗", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }
        }

        // 3. Holidays
        if (dayHolidays.isNotEmpty()) {
            item {
                Text("የዕለቱ በዓላት (Holidays on this day):", fontWeight = FontWeight.Bold, fontSize = 14.sp)
            }
            items(dayHolidays) { h ->
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = if (h.isPublicHoliday) Color(0xFFEF4444).copy(alpha = 0.1f) else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            text = "${if (h.isPublicHoliday) "🔴 " else "🟣 "}${h.titleAmharic} (${h.titleEnglish})",
                            fontWeight = FontWeight.Bold,
                            color = if (h.isPublicHoliday) Color(0xFFDC2626) else MaterialTheme.colorScheme.primary
                        )
                        if (h.description.isNotEmpty()) {
                            Text(
                                text = h.description,
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }

        // 4. Schedule and Events Header
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("የዕለቱ ማስታወሻዎች (Schedule):", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                IconButton(
                    onClick = onAddEvent,
                    modifier = Modifier
                        .size(36.dp)
                        .background(MaterialTheme.colorScheme.primaryContainer, CircleShape)
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Event", tint = MaterialTheme.colorScheme.onPrimaryContainer)
                }
            }
        }

        if (dayEvents.isEmpty()) {
            item {
                Text(
                    "ለዚህ ቀን የተያዘ ማስታወሻ የለም። ማስታወሻ ለማስቀመጥ የ + ምልክቱን ይጫኑ።",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            items(dayEvents, key = { it.id }) { ev ->
                EventListItem(
                    event = ev,
                    onToggle = { onToggleEvent(ev) },
                    onDelete = { onDeleteEvent(ev) },
                    onEdit = { onEditEvent(ev) }
                )
            }
        }

        // 5. Traditional Ethiopian 12-Hour Daily Timeline Card
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "🕒 ባህላዊ የቀን ሰዓታት (Traditional Hours)",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = "24 ሰዓት",
                            fontSize = 10.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    traditionalHours.take(12).forEach { (ethHour, isDay, label) ->
                        val matchedEvent = dayEvents.firstOrNull {
                            val eventEthHour = if (it.hour in 6..17) {
                                val h = (it.hour - 6)
                                if (h == 0) 12 else h
                            } else {
                                val h = (it.hour + 6) % 12
                                if (h == 0) 12 else h
                            }
                            eventEthHour == ethHour && ((it.hour in 6..17) == isDay)
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (matchedEvent != null) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f) else Color.Transparent,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 2.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 6.dp, vertical = 4.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = if (isDay) "☀️" else "🌙",
                                        fontSize = 12.sp
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = label,
                                        fontSize = 11.sp,
                                        fontWeight = if (matchedEvent != null) FontWeight.Bold else FontWeight.Medium,
                                        color = if (matchedEvent != null) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                                    )
                                }

                                if (matchedEvent != null) {
                                    Surface(
                                        shape = RoundedCornerShape(6.dp),
                                        color = MaterialTheme.colorScheme.primary
                                    ) {
                                        Text(
                                            text = matchedEvent.title,
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onPrimary,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Visual toggle component allowing users to quickly switch between viewing dates
 * in the Ethiopian format (🇪🇹 የኢትዮጵያ) and the Gregorian format (🌍 ጎርጎሪያን).
 */
@Composable
fun CalendarFormatToggle(
    currentFormat: String,
    onFormatSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val isEth = currentFormat == "ETHIOPIAN"
    val isGreg = currentFormat == "GREGORIAN"

    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
        ),
        modifier = modifier
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(3.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            // Ethiopian Format Button
            Surface(
                shape = RoundedCornerShape(11.dp),
                color = if (isEth) MaterialTheme.colorScheme.primary else Color.Transparent,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(11.dp))
                    .clickable { onFormatSelected("ETHIOPIAN") }
                    .testTag("calendar_format_toggle_ethiopian")
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
                            fontWeight = if (isEth) FontWeight.Bold else FontWeight.Medium,
                            color = if (isEth) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "Ethiopian Format",
                            fontSize = 8.5.sp,
                            color = if (isEth) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                        )
                    }
                }
            }

            // Gregorian Format Button
            Surface(
                shape = RoundedCornerShape(11.dp),
                color = if (isGreg) MaterialTheme.colorScheme.primary else Color.Transparent,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(11.dp))
                    .clickable { onFormatSelected("GREGORIAN") }
                    .testTag("calendar_format_toggle_gregorian")
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
                            fontWeight = if (isGreg) FontWeight.Bold else FontWeight.Medium,
                            color = if (isGreg) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "Gregorian Format",
                            fontSize = 8.5.sp,
                            color = if (isGreg) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                        )
                    }
                }
            }
        }
    }
}
