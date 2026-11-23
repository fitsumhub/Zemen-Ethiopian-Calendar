package com.example.calendar.ui.screens.converter

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
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
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import kotlin.math.abs

/**
 * Modern Age & Date Difference Calculator with tactile steppers, calendar pickers,
 * synced Ethiopian/Gregorian birthdate switching, life milestones, birthday countdown,
 * and 1-tap Start/End swap in Date Difference mode.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AgeAndDifferenceTab(viewModel: MainViewModel, currentLang: AppLanguage) {
    val context = LocalContext.current
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA
    var isAgeCalculatorMode by remember { mutableStateOf(true) }

    val todayEth = viewModel.todayEthiopian

    // Age Calculator birthdate state
    var birthIsEth by remember { mutableStateOf(true) }
    var birthYear by remember { mutableIntStateOf((todayEth.year - 25).coerceAtLeast(1)) }
    var birthMonth by remember { mutableIntStateOf(1) }
    var birthDay by remember { mutableIntStateOf(1) }

    // Date Difference states
    var fromYear by remember { mutableIntStateOf((todayEth.year - 1).coerceAtLeast(1)) }
    var fromMonth by remember { mutableIntStateOf(1) }
    var fromDay by remember { mutableIntStateOf(1) }

    var toYear by remember { mutableIntStateOf(todayEth.year) }
    var toMonth by remember { mutableIntStateOf(todayEth.month) }
    var toDay by remember { mutableIntStateOf(todayEth.day) }

    // Dialog states
    var yearEditTarget by remember { mutableStateOf<String?>(null) } // "birth" | "from" | "to"
    var yearEditText by remember { mutableStateOf("") }
    var ethGridPickerTarget by remember { mutableStateOf<String?>(null) } // "birth" | "from" | "to"
    var showGregBirthPicker by remember { mutableStateOf(false) }

    var swapDiffRotation by remember { mutableFloatStateOf(0f) }
    val animatedSwapRotation by animateFloatAsState(
        targetValue = swapDiffRotation,
        animationSpec = spring(stiffness = Spring.StiffnessMediumLow),
        label = "swap_diff_dates"
    )

    val ethMonthsShort = remember {
        listOf(
            1 to "Meskerem", 2 to "Tikimt", 3 to "Hidar", 4 to "Tahsas",
            5 to "Tir", 6 to "Yakatit", 7 to "Magabit", 8 to "Miyazya",
            9 to "Ginbot", 10 to "Sene", 11 to "Hamle", 12 to "Nehase", 13 to "Pagume"
        )
    }

    val gregMonthsShort = remember {
        listOf(
            1 to "Jan", 2 to "Feb", 3 to "Mar", 4 to "Apr", 5 to "May", 6 to "Jun",
            7 to "Jul", 8 to "Aug", 9 to "Sep", 10 to "Oct", 11 to "Nov", 12 to "Dec"
        )
    }

    val maxBirthDay = if (birthIsEth) {
        EthiopianDate.daysInMonth(birthYear, birthMonth)
    } else {
        GregorianDate.daysInMonth(birthYear, birthMonth)
    }
    val safeBirthDay = birthDay.coerceIn(1, maxBirthDay)

    val birthEthDate = remember(birthIsEth, birthYear, birthMonth, safeBirthDay) {
        if (birthIsEth) {
            EthiopianDate(birthYear, birthMonth, safeBirthDay)
        } else {
            EthiopianCalendarEngine.toEthiopian(GregorianDate(birthYear, birthMonth, safeBirthDay))
        }
    }
    val birthGregDate = remember(birthEthDate) {
        EthiopianCalendarEngine.toGregorian(birthEthDate)
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 84.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. CLEAN 2-SEGMENT MODE SWITCHER
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
                        Triple(true, if (isGeezScript) "ዕድሜ (Age)" else "Age Calculator", Icons.Default.Cake),
                        Triple(false, if (isGeezScript) "የቀናት ልዩነት" else "Date Difference", Icons.Default.CalendarMonth)
                    ).forEach { (isAge, label, icon) ->
                        val active = isAgeCalculatorMode == isAge
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (active) MaterialTheme.colorScheme.primary else Color.Transparent,
                            modifier = Modifier
                                .weight(1f)
                                .minimumInteractiveComponentSize()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable { isAgeCalculatorMode = isAge }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Icon(
                                    imageVector = icon,
                                    contentDescription = null,
                                    tint = if (active) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = label,
                                    fontWeight = if (active) FontWeight.Bold else FontWeight.Medium,
                                    color = if (active) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                                    fontSize = 12.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }
                }
            }
        }

        if (isAgeCalculatorMode) {
            // ==================== AGE CALCULATOR ====================
            item {
                Card(
                    shape = RoundedCornerShape(22.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "DATE OF BIRTH",
                                    fontSize = 10.5.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = MaterialTheme.colorScheme.primary,
                                    letterSpacing = 0.8.sp
                                )
                                Text(
                                    text = if (isGeezScript) "የልደት ቀንዎን ይምረጡ" else "Select Your Birthdate",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }

                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                AssistChip(
                                    onClick = {
                                        if (birthIsEth) ethGridPickerTarget = "birth"
                                        else showGregBirthPicker = true
                                    },
                                    label = { Text(if (isGeezScript) "ካላንደር" else "Pick", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                                    leadingIcon = {
                                        Icon(
                                            Icons.Default.DateRange,
                                            contentDescription = "Open Calendar Picker",
                                            modifier = Modifier.size(15.dp),
                                            tint = MaterialTheme.colorScheme.primary
                                        )
                                    },
                                    colors = AssistChipDefaults.assistChipColors(
                                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.65f),
                                        labelColor = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                )

                                // Synced calendar switch (preserves exact represented date!)
                                AssistChip(
                                    onClick = {
                                        if (birthIsEth) {
                                            birthYear = birthGregDate.year
                                            birthMonth = birthGregDate.month
                                            birthDay = birthGregDate.day
                                            birthIsEth = false
                                        } else {
                                            birthYear = birthEthDate.year
                                            birthMonth = birthEthDate.month
                                            birthDay = birthEthDate.day
                                            birthIsEth = true
                                        }
                                    },
                                    label = {
                                        Text(
                                            text = if (birthIsEth) "🇪🇹 E.C." else "🌍 G.C.",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                    }
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Live Birthdate Preview Pill (with cross-calendar hint)
                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.45f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 12.dp, vertical = 10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = if (birthIsEth) {
                                            "🇪🇹 ${LocaleStrings.getMonthName(birthEthDate.month, currentLang)} ${birthEthDate.day}, ${birthEthDate.year} E.C."
                                        } else {
                                            "🌍 ${gregMonthsShort.first { it.first == birthGregDate.month }.second} ${birthGregDate.day}, ${birthGregDate.year} G.C."
                                        },
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.ExtraBold,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Text(
                                        text = if (birthIsEth) {
                                            "Gregorian: ${gregMonthsShort.first { it.first == birthGregDate.month }.second} ${birthGregDate.day}, ${birthGregDate.year} G.C."
                                        } else {
                                            "Ethiopian: ${LocaleStrings.getMonthName(birthEthDate.month, currentLang)} ${birthEthDate.day}, ${birthEthDate.year} E.C."
                                        },
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Tactile Year Stepper
                        AgeYearStepperRow(
                            label = if (birthIsEth) "Birth Year (E.C.)" else "Birth Year (G.C.)",
                            year = birthYear,
                            suffix = if (birthIsEth) "ዓ.ም" else "G.C.",
                            onStep = { delta -> birthYear = (birthYear + delta).coerceIn(1, 9999) },
                            onEditClick = {
                                yearEditText = birthYear.toString()
                                yearEditTarget = "birth"
                            }
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        // Month Carousel
                        Text(
                            text = if (isGeezScript) "ወር (Month)" else "Birth Month",
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
                            if (birthIsEth) {
                                ethMonthsShort.forEach { (m, nameEn) ->
                                    val active = birthMonth == m
                                    val nameLocal = LocaleStrings.getMonthName(m, currentLang)
                                    AgeMonthChip(
                                        number = m,
                                        title = if (isGeezScript) nameLocal else nameEn,
                                        selected = active,
                                        onClick = {
                                            birthMonth = m
                                            birthDay = birthDay.coerceIn(1, EthiopianDate.daysInMonth(birthYear, m))
                                        }
                                    )
                                }
                            } else {
                                gregMonthsShort.forEach { (m, nameEn) ->
                                    val active = birthMonth == m
                                    AgeMonthChip(
                                        number = m,
                                        title = nameEn,
                                        selected = active,
                                        onClick = {
                                            birthMonth = m
                                            birthDay = birthDay.coerceIn(1, GregorianDate.daysInMonth(birthYear, m))
                                        }
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Day Stepper
                        AgeDayStepperRow(
                            day = safeBirthDay,
                            maxDays = maxBirthDay,
                            onStep = { delta -> birthDay = (safeBirthDay + delta).coerceIn(1, maxBirthDay) },
                            onBadgeClick = {
                                if (birthIsEth) ethGridPickerTarget = "birth"
                                else showGregBirthPicker = true
                            }
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        // Unclipped Horizontal Scrollable Quick Age/Year Presets
                        Text(
                            text = if (isGeezScript) "ፈጣን ምርጫ (Quick Presets)" else "Quick Presets",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))

                        val baseYear = if (birthIsEth) todayEth.year else viewModel.todayGregorian.year
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            listOf(
                                "18 yrs (${baseYear - 18})" to (baseYear - 18),
                                "25 yrs (${baseYear - 25})" to (baseYear - 25),
                                "30 yrs (${baseYear - 30})" to (baseYear - 30),
                                "40 yrs (${baseYear - 40})" to (baseYear - 40),
                                "Year 1990" to 1990,
                                "Year 2000" to 2000
                            ).forEach { (label, y) ->
                                val targetY = y.coerceAtLeast(1)
                                FilterChip(
                                    selected = birthYear == targetY,
                                    onClick = { birthYear = targetY },
                                    label = { Text(label, fontSize = 11.sp) }
                                )
                            }
                        }
                    }
                }
            }

            // Age Calculation Result Hero Card
            item {
                val birthDow = EthiopianCalendarEngine.getDayOfWeek(birthEthDate)
                val isFutureBirth = EthiopianCalendarEngine.daysBetween(birthEthDate, todayEth) < 0L
                val totalDaysLived = EthiopianCalendarEngine.daysBetween(birthEthDate, todayEth).coerceAtLeast(0L)
                val diff = EthiopianCalendarEngine.calculateDifference(birthEthDate, todayEth)
                val birthEvangelist = LeapYearCalculator.getEvangelist(birthEthDate.year)

                val nextBdayYear = if (todayEth.month > birthEthDate.month || (todayEth.month == birthEthDate.month && todayEth.day > birthEthDate.day)) {
                    todayEth.year + 1
                } else {
                    todayEth.year
                }
                val nextBdayEth = EthiopianDate(
                    nextBdayYear,
                    birthEthDate.month,
                    birthEthDate.day.coerceIn(1, EthiopianDate.daysInMonth(nextBdayYear, birthEthDate.month))
                )
                val nextBdayGreg = EthiopianCalendarEngine.toGregorian(nextBdayEth)
                val daysToNextBday = EthiopianCalendarEngine.daysBetween(todayEth, nextBdayEth).coerceAtLeast(0L)
                val birthdayProgress = ((365f - daysToNextBday.toFloat()) / 365f).coerceIn(0f, 1f)

                val estimatedHours = totalDaysLived * 24
                val estimatedHeartbeats = totalDaysLived * 24 * 60 * 72L

                ElevatedCard(
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
                    modifier = Modifier.fillMaxWidth()
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
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "AGE BREAKDOWN",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = MaterialTheme.colorScheme.primary,
                                    letterSpacing = 0.8.sp
                                )

                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = MaterialTheme.colorScheme.surface
                                ) {
                                    Text(
                                        text = "Born ${LocaleStrings.getWeekdayLong(birthDow, AppLanguage.ENGLISH)}",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.padding(horizontal = 9.dp, vertical = 4.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            // Large Age Hero Surface
                            Surface(
                                shape = RoundedCornerShape(18.dp),
                                color = MaterialTheme.colorScheme.surface,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Text(
                                        text = if (isFutureBirth) "Selected birthdate is in the future" else "Exact Current Age",
                                        fontSize = 11.5.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = if (isFutureBirth) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.height(6.dp))

                                    if (!isFutureBirth) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            AgeUnitTile(value = diff.ethiopianYears.toString(), unit = "Years", modifier = Modifier.weight(1f))
                                            AgeUnitTile(value = diff.ethiopianMonths.toString(), unit = "Months", modifier = Modifier.weight(1f))
                                            AgeUnitTile(value = diff.ethiopianDays.toString(), unit = "Days", modifier = Modifier.weight(1f))
                                        }
                                        Spacer(modifier = Modifier.height(10.dp))
                                    }

                                    Text(
                                        text = "በኢትዮጵያ አቆጣጠር፡ ${diff.ethiopianYears} ዓመት ከ ${diff.ethiopianMonths} ወር ከ ${diff.ethiopianDays} ቀን",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = "Evangelist Year: ${birthEvangelist.englishName} (${birthEvangelist.amharicName})",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.secondary,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            // Life Milestones 2x2 Grid
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                MilestoneTile(
                                    label = "Total Days",
                                    value = String.format(Locale.US, "%,d", totalDaysLived),
                                    subtext = "Days lived so far",
                                    accent = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.weight(1f)
                                )
                                MilestoneTile(
                                    label = "Total Weeks",
                                    value = String.format(Locale.US, "%,d", diff.totalWeeks),
                                    subtext = "+ ${diff.remainingDays} days",
                                    accent = MaterialTheme.colorScheme.secondary,
                                    modifier = Modifier.weight(1f)
                                )
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                MilestoneTile(
                                    label = "Estimated Hours",
                                    value = "~${String.format(Locale.US, "%,d", estimatedHours)}",
                                    subtext = "Hours lived",
                                    accent = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.weight(1f)
                                )
                                MilestoneTile(
                                    label = "Heartbeats",
                                    value = "~${estimatedHeartbeats / 1_000_000}M",
                                    subtext = "Approx. @ 72 bpm",
                                    accent = MaterialTheme.colorScheme.tertiary,
                                    modifier = Modifier.weight(1f)
                                )
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            // Next Birthday Countdown Card
                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = MaterialTheme.colorScheme.primaryContainer,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(modifier = Modifier.padding(14.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.Cake,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.primary,
                                            modifier = Modifier.size(22.dp)
                                        )
                                        Spacer(modifier = Modifier.width(10.dp))
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = if (daysToNextBday == 0L) "Happy Birthday Today!" else "Next Birthday in $daysToNextBday days",
                                                fontSize = 14.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = MaterialTheme.colorScheme.onPrimaryContainer
                                            )
                                            Text(
                                                text = "${LocaleStrings.getMonthName(nextBdayEth.month, AppLanguage.ENGLISH)} ${nextBdayEth.day}, ${nextBdayEth.year} E.C. • ${gregMonthsShort.first { it.first == nextBdayGreg.month }.second} ${nextBdayGreg.day}, ${nextBdayGreg.year}",
                                                fontSize = 11.sp,
                                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.85f)
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(10.dp))

                                    LinearProgressIndicator(
                                        progress = { birthdayProgress },
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(7.dp)
                                            .clip(RoundedCornerShape(4.dp)),
                                        color = MaterialTheme.colorScheme.primary,
                                        trackColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.55f)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(14.dp))

                            // Share & Copy Age Details
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                OutlinedButton(
                                    onClick = {
                                        val text = "Exact Age: ${diff.ethiopianYears} Years, ${diff.ethiopianMonths} Months, ${diff.ethiopianDays} Days\nTotal Days: $totalDaysLived days (~$estimatedHours hours)\nDay of birth: ${LocaleStrings.getWeekdayLong(birthDow, AppLanguage.ENGLISH)}\nNext Birthday: In $daysToNextBday days"
                                        val clip = ClipData.newPlainText("Age Report", text)
                                        (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                        Toast.makeText(context, "Age report copied!", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier
                                        .weight(1f)
                                        .minimumInteractiveComponentSize()
                                ) {
                                    Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Copy", fontSize = 12.sp)
                                }

                                Button(
                                    onClick = {
                                        val text = "🎂 Age Report:\n• Exact Age: ${diff.ethiopianYears} Years, ${diff.ethiopianMonths} Months, ${diff.ethiopianDays} Days\n• Total Days Lived: $totalDaysLived days\n• Next Birthday in $daysToNextBday days\n• Born on ${LocaleStrings.getWeekdayLong(birthDow, AppLanguage.ENGLISH)}"
                                        val intent = Intent().apply {
                                            action = Intent.ACTION_SEND
                                            putExtra(Intent.EXTRA_TEXT, text)
                                            type = "text/plain"
                                        }
                                        context.startActivity(Intent.createChooser(intent, "Share Age Report"))
                                    },
                                    modifier = Modifier
                                        .weight(1f)
                                        .minimumInteractiveComponentSize()
                                ) {
                                    Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(15.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Share", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // ==================== DATE DIFFERENCE ====================
            item {
                EthiopianDateSelectorCard(
                    eyebrow = "START DATE • መነሻ ቀን",
                    year = fromYear,
                    month = fromMonth,
                    day = fromDay,
                    currentLang = currentLang,
                    ethMonthsShort = ethMonthsShort,
                    onYearChange = { fromYear = it },
                    onMonthChange = { m ->
                        fromMonth = m
                        fromDay = fromDay.coerceIn(1, EthiopianDate.daysInMonth(fromYear, m))
                    },
                    onDayChange = { fromDay = it },
                    onPickClick = { ethGridPickerTarget = "from" },
                    onTodayClick = {
                        fromYear = todayEth.year
                        fromMonth = todayEth.month
                        fromDay = todayEth.day
                    },
                    onEditYearClick = {
                        yearEditText = fromYear.toString()
                        yearEditTarget = "from"
                    }
                )
            }

            // Floating Swap Start <-> End Dates Bridge
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
                        shadowElevation = 3.dp,
                        modifier = Modifier
                            .minimumInteractiveComponentSize()
                            .clip(RoundedCornerShape(24.dp))
                            .clickable {
                                swapDiffRotation += 180f
                                val sy = fromYear
                                val sm = fromMonth
                                val sd = fromDay
                                fromYear = toYear
                                fromMonth = toMonth
                                fromDay = toDay
                                toYear = sy
                                toMonth = sm
                                toDay = sd
                            }
                            .testTag("swap_diff_dates_button")
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.SwapVert,
                                contentDescription = "Swap Start and End Dates",
                                tint = MaterialTheme.colorScheme.onPrimary,
                                modifier = Modifier
                                    .size(18.dp)
                                    .rotate(animatedSwapRotation)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (isGeezScript) "ቀናትን አቀያይር" else "Swap Dates",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                }
            }

            item {
                EthiopianDateSelectorCard(
                    eyebrow = "END DATE • መድረሻ ቀን",
                    year = toYear,
                    month = toMonth,
                    day = toDay,
                    currentLang = currentLang,
                    ethMonthsShort = ethMonthsShort,
                    onYearChange = { toYear = it },
                    onMonthChange = { m ->
                        toMonth = m
                        toDay = toDay.coerceIn(1, EthiopianDate.daysInMonth(toYear, m))
                    },
                    onDayChange = { toDay = it },
                    onPickClick = { ethGridPickerTarget = "to" },
                    onTodayClick = {
                        toYear = todayEth.year
                        toMonth = todayEth.month
                        toDay = todayEth.day
                    },
                    onEditYearClick = {
                        yearEditText = toYear.toString()
                        yearEditTarget = "to"
                    }
                )
            }

            // Difference Result Hero Card
            item {
                val fDate = remember(fromYear, fromMonth, fromDay) {
                    val max = EthiopianDate.daysInMonth(fromYear, fromMonth)
                    EthiopianDate(fromYear, fromMonth, fromDay.coerceIn(1, max))
                }
                val tDate = remember(toYear, toMonth, toDay) {
                    val max = EthiopianDate.daysInMonth(toYear, toMonth)
                    EthiopianDate(toYear, toMonth, toDay.coerceIn(1, max))
                }

                val difference = remember(fDate, tDate) {
                    EthiopianCalendarEngine.calculateDifference(fDate, tDate)
                }

                val totalDays = abs(difference.totalDays)
                val workingDays = (totalDays * 5) / 7
                val totalHours = totalDays * 24

                ElevatedCard(
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
                    modifier = Modifier.fillMaxWidth()
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
                            Text(
                                text = "DATE DIFFERENCE SUMMARY",
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.primary,
                                letterSpacing = 0.8.sp
                            )

                            Spacer(modifier = Modifier.height(10.dp))

                            // Start -> End Bridge Pill
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
                                        text = "${LocaleStrings.getMonthName(fDate.month, currentLang)} ${fDate.day}, ${fDate.year}",
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
                                        text = "${LocaleStrings.getMonthName(tDate.month, currentLang)} ${tDate.day}, ${tDate.year}",
                                        fontSize = 11.5.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Surface(
                                shape = RoundedCornerShape(18.dp),
                                color = MaterialTheme.colorScheme.surface,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Text(
                                        text = "${String.format(Locale.US, "%,d", totalDays)} Total Days",
                                        fontSize = 24.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = "${difference.totalWeeks} weeks + ${difference.remainingDays} days • ~${String.format(Locale.US, "%,d", totalHours)} hours",
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = "Approx. Business Days: ~${String.format(Locale.US, "%,d", workingDays)} days (Mon–Fri)",
                                        fontSize = 11.5.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Surface(
                                    shape = RoundedCornerShape(14.dp),
                                    color = MaterialTheme.colorScheme.surface,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Column(modifier = Modifier.padding(12.dp)) {
                                        Text("Ethiopian Span", fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = "${difference.ethiopianYears}y, ${difference.ethiopianMonths}m, ${difference.ethiopianDays}d",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                }

                                Surface(
                                    shape = RoundedCornerShape(14.dp),
                                    color = MaterialTheme.colorScheme.surface,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Column(modifier = Modifier.padding(12.dp)) {
                                        Text("Gregorian Span", fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = "${difference.gregorianYears}y, ${difference.gregorianMonths}m, ${difference.gregorianDays}d",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.ExtraBold,
                                            color = MaterialTheme.colorScheme.secondary
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(14.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                OutlinedButton(
                                    onClick = {
                                        val text = "Date Difference: $totalDays Days (${difference.totalWeeks} weeks + ${difference.remainingDays} days) • Ethiopian Span: ${difference.ethiopianYears}y, ${difference.ethiopianMonths}m, ${difference.ethiopianDays}d"
                                        val clip = ClipData.newPlainText("Date Difference", text)
                                        (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                        Toast.makeText(context, "Difference copied to clipboard!", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier
                                        .weight(1f)
                                        .minimumInteractiveComponentSize()
                                ) {
                                    Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Copy Result", fontSize = 12.sp)
                                }

                                Button(
                                    onClick = {
                                        val text = "📅 Date Difference\nFrom: ${fDate.day}/${fDate.month}/${fDate.year} E.C.\nTo: ${tDate.day}/${tDate.month}/${tDate.year} E.C.\n• Total: $totalDays Days (${difference.totalWeeks}w ${difference.remainingDays}d)\n• Ethiopian Span: ${difference.ethiopianYears}y ${difference.ethiopianMonths}m ${difference.ethiopianDays}d"
                                        val intent = Intent().apply {
                                            action = Intent.ACTION_SEND
                                            putExtra(Intent.EXTRA_TEXT, text)
                                            type = "text/plain"
                                        }
                                        context.startActivity(Intent.createChooser(intent, "Share Date Difference"))
                                    },
                                    modifier = Modifier
                                        .weight(1f)
                                        .minimumInteractiveComponentSize()
                                ) {
                                    Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(15.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Share", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // YEAR INPUT DIALOG
    yearEditTarget?.let { target ->
        AlertDialog(
            onDismissRequest = { yearEditTarget = null },
            title = {
                Text(
                    text = "Enter Year",
                    fontSize = 16.sp,
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
                        value = yearEditText,
                        onValueChange = { yearEditText = it },
                        singleLine = true,
                        label = { Text("Year") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    yearEditText.toIntOrNull()?.let { y ->
                        if (y in 1..9999) {
                            when (target) {
                                "birth" -> birthYear = y
                                "from" -> fromYear = y
                                "to" -> toYear = y
                            }
                        }
                    }
                    yearEditTarget = null
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { yearEditTarget = null }) {
                    Text("Cancel")
                }
            }
        )
    }

    // ETHIOPIAN DAY GRID PICKER DIALOG
    ethGridPickerTarget?.let { target ->
        val (curYear, curMonth, curDay) = when (target) {
            "birth" -> Triple(birthYear, birthMonth, birthDay)
            "from" -> Triple(fromYear, fromMonth, fromDay)
            else -> Triple(toYear, toMonth, toDay)
        }
        val maxDays = EthiopianDate.daysInMonth(curYear, curMonth)
        AlertDialog(
            onDismissRequest = { ethGridPickerTarget = null },
            title = {
                Text(
                    text = "${LocaleStrings.getMonthName(curMonth, currentLang)} $curYear ዓ.ም",
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
                        items((1..maxDays).toList()) { d ->
                            val isSelected = d == curDay
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .clickable {
                                        when (target) {
                                            "birth" -> birthDay = d
                                            "from" -> fromDay = d
                                            "to" -> toDay = d
                                        }
                                        ethGridPickerTarget = null
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
                TextButton(onClick = { ethGridPickerTarget = null }) {
                    Text("Close")
                }
            }
        )
    }

    // MATERIAL GREGORIAN DATE PICKER FOR BIRTHDATE
    if (showGregBirthPicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                val safeMonth = birthMonth.coerceIn(1, 12)
                val safeDay = birthDay.coerceIn(1, GregorianDate.daysInMonth(birthYear, safeMonth))
                set(birthYear, safeMonth - 1, safeDay, 12, 0, 0)
            }.timeInMillis
        )
        DatePickerDialog(
            onDismissRequest = { showGregBirthPicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                            timeInMillis = millis
                        }
                        birthYear = cal.get(Calendar.YEAR)
                        birthMonth = cal.get(Calendar.MONTH) + 1
                        birthDay = cal.get(Calendar.DAY_OF_MONTH)
                    }
                    showGregBirthPicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showGregBirthPicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }
}

@Composable
private fun EthiopianDateSelectorCard(
    eyebrow: String,
    year: Int,
    month: Int,
    day: Int,
    currentLang: AppLanguage,
    ethMonthsShort: List<Pair<Int, String>>,
    onYearChange: (Int) -> Unit,
    onMonthChange: (Int) -> Unit,
    onDayChange: (Int) -> Unit,
    onPickClick: () -> Unit,
    onTodayClick: () -> Unit,
    onEditYearClick: () -> Unit
) {
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA
    val maxDays = EthiopianDate.daysInMonth(year, month)
    val safeDay = day.coerceIn(1, maxDays)

    Card(
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = eyebrow,
                        fontSize = 10.5.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = MaterialTheme.colorScheme.primary,
                        letterSpacing = 0.8.sp
                    )
                    Text(
                        text = "${LocaleStrings.getMonthName(month, currentLang)} $safeDay, $year ዓ.ም",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    AssistChip(
                        onClick = onPickClick,
                        label = { Text(if (isGeezScript) "ካላንደር" else "Pick", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                        leadingIcon = {
                            Icon(Icons.Default.DateRange, contentDescription = null, modifier = Modifier.size(14.dp), tint = MaterialTheme.colorScheme.primary)
                        },
                        colors = AssistChipDefaults.assistChipColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.65f),
                            labelColor = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    )
                    AssistChip(
                        onClick = onTodayClick,
                        label = { Text(if (isGeezScript) "ዛሬ" else "Today", fontSize = 11.sp) },
                        leadingIcon = {
                            Icon(Icons.Default.Today, contentDescription = null, modifier = Modifier.size(14.dp))
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            AgeYearStepperRow(
                label = "Year (E.C.)",
                year = year,
                suffix = "ዓ.ም",
                onStep = { delta -> onYearChange((year + delta).coerceIn(1, 9999)) },
                onEditClick = onEditYearClick
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                ethMonthsShort.forEach { (m, nameEn) ->
                    val nameLocal = LocaleStrings.getMonthName(m, currentLang)
                    AgeMonthChip(
                        number = m,
                        title = if (isGeezScript) nameLocal else nameEn,
                        selected = month == m,
                        onClick = { onMonthChange(m) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            AgeDayStepperRow(
                day = safeDay,
                maxDays = maxDays,
                onStep = { delta -> onDayChange((safeDay + delta).coerceIn(1, maxDays)) },
                onBadgeClick = onPickClick
            )
        }
    }
}

@Composable
private fun AgeYearStepperRow(
    label: String,
    year: Int,
    suffix: String,
    onStep: (Int) -> Unit,
    onEditClick: () -> Unit
) {
    Column {
        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))
        Surface(
            shape = RoundedCornerShape(14.dp),
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
                    AgeStepPill("-5") { onStep(-5) }
                    AgeStepPill("-1") { onStep(-1) }
                }

                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.primaryContainer,
                    modifier = Modifier
                        .minimumInteractiveComponentSize()
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onEditClick() }
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                    ) {
                        Text(
                            text = "$year $suffix",
                            fontSize = 15.5.sp,
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(
                            Icons.Default.Edit,
                            contentDescription = "Edit Year",
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(13.dp)
                        )
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    AgeStepPill("+1") { onStep(1) }
                    AgeStepPill("+5") { onStep(5) }
                }
            }
        }
    }
}

@Composable
private fun AgeDayStepperRow(
    day: Int,
    maxDays: Int,
    onStep: (Int) -> Unit,
    onBadgeClick: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = "Day",
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
            AgeStepPill("-7") { onStep(-7) }
            AgeStepPill("-1") { onStep(-1) }

            Surface(
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .clickable { onBadgeClick() }
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = day.toString(),
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Black,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }

            AgeStepPill("+1") { onStep(1) }
            AgeStepPill("+7") { onStep(7) }
        }
    }
}

@Composable
private fun AgeStepPill(label: String, onClick: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
        modifier = Modifier
            .size(width = 38.dp, height = 38.dp)
            .clip(RoundedCornerShape(10.dp))
            .clickable { onClick() }
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = label,
                fontSize = 11.5.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun AgeMonthChip(
    number: Int,
    title: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f),
        border = BorderStroke(
            1.dp,
            if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
        ),
        modifier = Modifier
            .minimumInteractiveComponentSize()
            .clip(RoundedCornerShape(12.dp))
            .clickable { onClick() }
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 9.dp)
        ) {
            Text(
                text = "$number. $title",
                fontSize = 12.sp,
                fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun AgeUnitTile(
    value: String,
    unit: String,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.45f),
        modifier = modifier
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(vertical = 10.dp, horizontal = 6.dp)
        ) {
            Text(
                text = value,
                fontSize = 22.sp,
                fontWeight = FontWeight.Black,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = unit,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun MilestoneTile(
    label: String,
    value: String,
    subtext: String,
    accent: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(label, fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(2.dp))
            Text(value, fontSize = 16.sp, fontWeight = FontWeight.ExtraBold, color = accent, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(subtext, fontSize = 9.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.85f))
        }
    }
}
