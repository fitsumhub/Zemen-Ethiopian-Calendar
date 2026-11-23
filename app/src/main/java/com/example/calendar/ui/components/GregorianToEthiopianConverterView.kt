package com.example.calendar.ui.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.EthiopianDate
import com.example.calendar.core.GregorianDate
import com.example.calendar.core.GregorianToEthiopianConverter
import com.example.calendar.core.GregorianToEthiopianResult
import com.example.calendar.core.LeapYearCalculator
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Modern, production-grade Material 3 UI component allowing users to input a
 * Gregorian calendar date and instantly see its accurate Ethiopian date conversion
 * along with Ge'ez numerals, season, evangelist, day-of-week, and holiday details.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GregorianToEthiopianConverterView(
    initialYear: Int = 2024,
    initialMonth: Int = 9,
    initialDay: Int = 11,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val converter = remember { GregorianToEthiopianConverter.INSTANCE }

    // Gregorian Date Input State
    var gregYear by remember { mutableIntStateOf(initialYear) }
    var gregMonth by remember { mutableIntStateOf(initialMonth) }
    var gregDay by remember { mutableIntStateOf(initialDay) }

    // Dialog state for Material 3 Calendar Picker
    var showMaterialDatePicker by remember { mutableStateOf(false) }

    // Text parsing mode state
    var showManualInput by remember { mutableStateOf(false) }
    var manualDateText by remember { mutableStateOf("$gregYear-${gregMonth.toString().padStart(2, '0')}-${gregDay.toString().padStart(2, '0')}") }
    var manualInputError by remember { mutableStateOf<String?>(null) }

    // Max days in current Gregorian month
    val maxDays = remember(gregYear, gregMonth) {
        converter.getDaysInMonth(gregYear, gregMonth)
    }

    val isGregLeap = remember(gregYear) {
        converter.isLeapYear(gregYear)
    }

    // Live converted result
    val conversionResult = remember(gregYear, gregMonth, gregDay) {
        val safeDay = gregDay.coerceIn(1, maxDays)
        converter.convert(gregYear, gregMonth, safeDay)
    }

    val gregorianMonthNames = listOf(
        "1. January (ጥር)", "2. February (የካቲት)", "3. March (መጋቢት)",
        "4. April (ሚያዝያ)", "5. May (ግንቦት)", "6. June (ሰኔ)",
        "7. July (ሐምሌ)", "8. August (ነሐሴ)", "9. September (መስከረም)",
        "10. October (ጥቅምት)", "11. November (ኅዳር)", "12. December (ታኅሣሥ)"
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // 1. INPUT CARD
        ElevatedCard(
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.elevatedCardColors(
                containerColor = MaterialTheme.colorScheme.surface
            ),
            elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                // Header with title and Calendar picker button
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "🌍 የፈረንጅ ቀን (Gregorian Input)",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        Text(
                            text = "ቀን ያስገቡና ወደ ኢትዮጵያ ዘመን አቆጣጠር ይቀይሩ",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // Native Calendar Picker Modal Trigger
                    OutlinedButton(
                        onClick = { showMaterialDatePicker = true },
                        shape = RoundedCornerShape(12.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                        modifier = Modifier.testTag("gregorian_open_calendar_picker_btn")
                    ) {
                        Icon(
                            Icons.Default.DateRange,
                            contentDescription = "Open Date Picker",
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("ቀን መምረጫ", fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Interactive Selectors: Month Dropdown & Day Input
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    var monthExpanded by remember { mutableStateOf(false) }

                    // Month Dropdown
                    ExposedDropdownMenuBox(
                        expanded = monthExpanded,
                        onExpandedChange = { monthExpanded = !monthExpanded },
                        modifier = Modifier.weight(1.5f)
                    ) {
                        OutlinedTextField(
                            value = gregorianMonthNames.getOrElse(gregMonth - 1) { "Month $gregMonth" },
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("ወር (Month)", fontSize = 12.sp) },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = monthExpanded) },
                            modifier = Modifier
                                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                                .testTag("gregorian_month_selector")
                        )
                        ExposedDropdownMenu(
                            expanded = monthExpanded,
                            onDismissRequest = { monthExpanded = false }
                        ) {
                            gregorianMonthNames.forEachIndexed { idx, name ->
                                val m = idx + 1
                                DropdownMenuItem(
                                    text = {
                                        Text(
                                            text = name,
                                            fontWeight = if (m == gregMonth) FontWeight.Bold else FontWeight.Normal,
                                            color = if (m == gregMonth) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
                                            fontSize = 13.sp
                                        )
                                    },
                                    onClick = {
                                        gregMonth = m
                                        val newMax = converter.getDaysInMonth(gregYear, m)
                                        if (gregDay > newMax) gregDay = newMax
                                        monthExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    // Day Input Field
                    OutlinedTextField(
                        value = gregDay.toString(),
                        onValueChange = { input ->
                            input.toIntOrNull()?.let { d ->
                                if (d in 1..maxDays) {
                                    gregDay = d
                                }
                            }
                        },
                        label = { Text("ቀን (1-$maxDays)", fontSize = 12.sp) },
                        modifier = Modifier
                            .weight(1f)
                            .testTag("gregorian_input_day")
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Quick Day Steppers
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "ቀን ቆጣሪ:",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    FilledTonalButton(
                        onClick = { if (gregDay > 1) gregDay -= 1 },
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                        modifier = Modifier.height(30.dp)
                    ) {
                        Text("-1", fontSize = 11.sp)
                    }
                    FilledTonalButton(
                        onClick = { if (gregDay < maxDays) gregDay += 1 },
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                        modifier = Modifier.height(30.dp)
                    ) {
                        Text("+1", fontSize = 11.sp)
                    }
                    FilledTonalButton(
                        onClick = { gregDay = (gregDay - 5).coerceAtLeast(1) },
                        contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                        modifier = Modifier.height(30.dp)
                    ) {
                        Text("-5", fontSize = 11.sp)
                    }
                    FilledTonalButton(
                        onClick = { gregDay = (gregDay + 5).coerceAtMost(maxDays) },
                        contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                        modifier = Modifier.height(30.dp)
                    ) {
                        Text("+5", fontSize = 11.sp)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Year Input Field & Year Steppers
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = gregYear.toString(),
                        onValueChange = { input ->
                            input.toIntOrNull()?.let { y ->
                                if (y in 1..9999) {
                                    gregYear = y
                                    val newMax = converter.getDaysInMonth(y, gregMonth)
                                    if (gregDay > newMax) gregDay = newMax
                                }
                            }
                        },
                        label = { Text("ዓመት (Year G.C.)", fontSize = 12.sp) },
                        modifier = Modifier
                            .weight(1.2f)
                            .testTag("gregorian_input_year")
                    )

                    FilledTonalButton(
                        onClick = {
                            if (gregYear > 1) {
                                gregYear -= 1
                                val newMax = converter.getDaysInMonth(gregYear, gregMonth)
                                if (gregDay > newMax) gregDay = newMax
                            }
                        },
                        modifier = Modifier.height(52.dp)
                    ) {
                        Text("-1 ዓመት", fontSize = 11.sp)
                    }

                    FilledTonalButton(
                        onClick = {
                            if (gregYear < 9999) {
                                gregYear += 1
                                val newMax = converter.getDaysInMonth(gregYear, gregMonth)
                                if (gregDay > newMax) gregDay = newMax
                            }
                        },
                        modifier = Modifier.height(52.dp)
                    ) {
                        Text("+1 ዓመት", fontSize = 11.sp)
                    }
                }

                // February Leap Year Banner
                if (gregMonth == 2) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = if (isGregLeap) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                        ) {
                            Icon(
                                Icons.Default.Info,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = if (isGregLeap) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (isGregLeap) {
                                    "⭐ የካቲት/February $gregYear የተጋነነ (Leap Year) ስለሆነ 29 ቀናት አሉት!"
                                } else {
                                    "ℹ️ February $gregYear መደበኛ ዓመት ሲሆን 28 ቀናት ብቻ አሉት።"
                                },
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium,
                                color = if (isGregLeap) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Quick Presets Row
                Text(
                    text = "ፈጣን ቀናት (Quick Presets):",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    // Today Chip
                    FilterChip(
                        selected = false,
                        onClick = {
                            val cal = Calendar.getInstance()
                            gregYear = cal.get(Calendar.YEAR)
                            gregMonth = cal.get(Calendar.MONTH) + 1
                            gregDay = cal.get(Calendar.DAY_OF_MONTH)
                        },
                        label = { Text("ዛሬ (Today)", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                        leadingIcon = {
                            Icon(Icons.Default.CalendarToday, contentDescription = null, modifier = Modifier.size(14.dp))
                        },
                        modifier = Modifier.testTag("gregorian_converter_today_chip")
                    )

                    // Notable Dates Presets
                    listOf(
                        "ገና / Christmas (Jan 7)" to Triple(gregYear, 1, 7),
                        "ጥምቀት / Epiphany (Jan 19)" to Triple(gregYear, 1, 19),
                        "እንቁጣጣሽ / New Year (Sep 11)" to Triple(gregYear, 9, 11),
                        "መስቀል / Meskel (Sep 27)" to Triple(gregYear, 9, 27),
                        "ፈረንጅ አዲስ ዓመት (Jan 1)" to Triple(gregYear, 1, 1),
                        "የፍቅረኞች ቀን (Feb 14)" to Triple(gregYear, 2, 14),
                        "ዘመን 2000 (Jan 1, 2000)" to Triple(2000, 1, 1)
                    ).forEach { (label, date) ->
                        FilterChip(
                            selected = gregYear == date.first && gregMonth == date.second && gregDay == date.third,
                            onClick = {
                                gregYear = date.first
                                gregMonth = date.second
                                val max = converter.getDaysInMonth(date.first, date.second)
                                gregDay = date.third.coerceIn(1, max)
                            },
                            label = { Text(label, fontSize = 11.sp) }
                        )
                    }
                }
            }
        }

        // 2. CONVERTED RESULT HERO CARD
        ElevatedCard(
            shape = RoundedCornerShape(22.dp),
            colors = CardDefaults.elevatedCardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.85f)
            ),
            elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
            modifier = Modifier
                .fillMaxWidth()
                .testTag("gregorian_converter_result_card")
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                // Header badge
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(bottom = 6.dp)
                    ) {
                        Text(
                            text = "🇪🇹 የተቀየረው የኢትዮጵያ ቀን",
                            color = MaterialTheme.colorScheme.onPrimary,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                        )
                    }

                    // Julian Day Number
                    Text(
                        text = "JDN: ${conversionResult.julianDayNumber}",
                        fontSize = 10.sp,
                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f),
                        fontWeight = FontWeight.Medium
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Prominent Ethiopian Date Headline
                Text(
                    text = conversionResult.formattedAmharic,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Black,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    lineHeight = 28.sp
                )

                Text(
                    text = "${conversionResult.formattedEnglish} (${conversionResult.dayOfWeekEnglish})",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )

                // Input Gregorian mirror reference
                Text(
                    text = "ከጎርጎሪያን፡ ${conversionResult.formattedGregorian}",
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.75f)
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Ge'ez Numerals Card
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "በግዕዝ ቁጥር (Ge'ez Numerals):",
                                fontSize = 10.5.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = conversionResult.geezFullDate,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primaryContainer,
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = conversionResult.geezDay,
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Black,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Cultural & Liturgical Metadata Badges
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    // Day of Week
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                    ) {
                        Text(
                            text = "📅 ${conversionResult.dayOfWeekAmharic} (${conversionResult.dayOfWeekEnglish})",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }

                    // Evangelist Cycle
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                    ) {
                        Text(
                            text = "📖 ${conversionResult.evangelistAmharic} (${conversionResult.evangelistEnglish})",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }

                    // Season Badge
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                    ) {
                        Text(
                            text = "🌾 ${conversionResult.seasonAmharic} (${conversionResult.seasonEnglish})",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }

                // Major Holiday Banner (if date coincides with a major feast/holiday)
                conversionResult.majorHolidayAmharic?.let { holidayAm ->
                    Spacer(modifier = Modifier.height(10.dp))
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                        ) {
                            Icon(
                                Icons.Default.Star,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Column {
                                Text(
                                    text = "በዓል / ክብረ በዓል: $holidayAm",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimary
                                )
                                conversionResult.majorHolidayEnglish?.let { holidayEn ->
                                    Text(
                                        text = holidayEn,
                                        fontSize = 10.5.sp,
                                        color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f)
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Action Buttons: Copy, Share, View in Calendar
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Copy Result Button
                    Button(
                        onClick = {
                            val copyText = "${conversionResult.formattedAmharic} (${conversionResult.formattedEnglish}) | ጎርጎሪያን: ${conversionResult.formattedGregorian} | በግዕዝ: ${conversionResult.geezFullDate}"
                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            clipboard.setPrimaryClip(ClipData.newPlainText("Ethiopian Date", copyText))
                            Toast.makeText(context, "ቀኑ ወደ ቅንጥብ ሰሌዳ ተቀድቷል (Copied)!", Toast.LENGTH_SHORT).show()
                        },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        ),
                        modifier = Modifier
                            .weight(1f)
                            .testTag("copy_converted_ethiopian_date_btn")
                    ) {
                        Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("ቅዳ (Copy)", fontSize = 11.5.sp, fontWeight = FontWeight.Bold)
                    }

                    // Share Button
                    OutlinedButton(
                        onClick = {
                            val shareBody = "የተቀየረ የቀን ውጤት:\n• የኢትዮጵያ ቀን: ${conversionResult.formattedAmharic}\n• በግዕዝ: ${conversionResult.geezFullDate}\n• ጎርጎሪያን: ${conversionResult.formattedGregorian}\n• ዘመን: ${conversionResult.evangelistAmharic}\n• ወቅት: ${conversionResult.seasonAmharic}"
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, shareBody)
                            }
                            context.startActivity(Intent.createChooser(intent, "የቀን መረጃ አጋራ"))
                        },
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .weight(1f)
                            .testTag("share_converted_ethiopian_date_btn")
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("አጋራ (Share)", fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold)
                    }

                    // Optional: View on Calendar
                    onNavigateToCalendar?.let { navigateAction ->
                        FilledTonalButton(
                            onClick = { navigateAction(conversionResult.ethiopianDate) },
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(15.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("ቀን መቁጠሪያ", fontSize = 11.5.sp)
                        }
                    }
                }
            }
        }
    }

    // Material 3 Native DatePickerDialog
    if (showMaterialDatePicker) {
        val initialUtcMillis = remember(gregYear, gregMonth, gregDay) {
            val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
            cal.set(Calendar.YEAR, gregYear)
            cal.set(Calendar.MONTH, gregMonth - 1)
            cal.set(Calendar.DAY_OF_MONTH, gregDay)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            cal.timeInMillis
        }

        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = initialUtcMillis
        )

        DatePickerDialog(
            onDismissRequest = { showMaterialDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let { utcMillis ->
                            val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
                            cal.timeInMillis = utcMillis
                            gregYear = cal.get(Calendar.YEAR)
                            gregMonth = cal.get(Calendar.MONTH) + 1
                            gregDay = cal.get(Calendar.DAY_OF_MONTH)
                        }
                        showMaterialDatePicker = false
                    }
                ) {
                    Text("ቀይር (Select)", fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showMaterialDatePicker = false }) {
                    Text("ሰርዝ (Cancel)")
                }
            }
        ) {
            DatePicker(
                state = datePickerState,
                title = {
                    Text(
                        text = "የፈረንጅ ቀን ይምረጡ (Select Gregorian Date)",
                        modifier = Modifier.padding(start = 24.dp, top = 16.dp),
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
            )
        }
    }
}
