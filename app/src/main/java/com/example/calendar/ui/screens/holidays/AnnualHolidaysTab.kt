package com.example.calendar.ui.screens.holidays

import android.content.Intent
import android.widget.Toast
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.HourglassBottom
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.runtime.collectAsState
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

@Composable
fun AnnualHolidaysTab(
    viewModel: MainViewModel,
    selectedYear: Int,
    onYearChange: (Int) -> Unit,
    onSelectHolidayForDetail: (HolidayEngine.Holiday) -> Unit,
    onOpenCardShare: (HolidayEngine.Holiday) -> Unit,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    val allEvents by viewModel.allEvents.collectAsState()
    var selectedCategory by remember { mutableStateOf("ALL") }
    var searchQuery by remember { mutableStateOf("") }
    var showYearPickerDialog by remember { mutableStateOf(false) }
    var reminderHolidayDialogTarget by remember { mutableStateOf<HolidayEngine.Holiday?>(null) }
    var showBulkScheduleDialog by remember { mutableStateOf(false) }

    val allHolidays = remember(selectedYear) {
        HolidayEngine.getHolidaysForYear(selectedYear)
    }

    val upcomingHoliday = remember(todayEth) {
        val currentYearList = HolidayEngine.getHolidaysForYear(todayEth.year)
        currentYearList.firstOrNull { it.ethiopianDate >= todayEth }
            ?: HolidayEngine.getHolidaysForYear(todayEth.year + 1).firstOrNull()
    }

    val filteredHolidays = remember(allHolidays, selectedCategory, searchQuery) {
        allHolidays.filter { h ->
            val matchesCategory = when (selectedCategory) {
                "ALL" -> true
                "PUBLIC" -> h.isPublicHoliday
                "ORTHODOX" -> h.type == HolidayEngine.HolidayType.ORTHODOX_MAJOR || h.type == HolidayEngine.HolidayType.ORTHODOX_MOVABLE
                "FASTING" -> h.isFasting
                "ISLAMIC" -> h.type == HolidayEngine.HolidayType.ISLAMIC
                "CULTURAL" -> h.type == HolidayEngine.HolidayType.CULTURAL_REGIONAL
                else -> true
            }
            val matchesQuery = searchQuery.isEmpty() ||
                    h.titleAmharic.contains(searchQuery, ignoreCase = true) ||
                    h.titleEnglish.contains(searchQuery, ignoreCase = true) ||
                    h.titleOromo.contains(searchQuery, ignoreCase = true) ||
                    h.titleTigrinya.contains(searchQuery, ignoreCase = true) ||
                    h.description.contains(searchQuery, ignoreCase = true)
            matchesCategory && matchesQuery
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 10.dp, bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. HERO BANNER: NEXT UPCOMING CELEBRATION
        if (upcomingHoliday != null && selectedYear == todayEth.year && searchQuery.isEmpty()) {
            item {
                val gUpcoming = EthiopianCalendarEngine.toGregorian(upcomingHoliday.ethiopianDate)
                val dowUpcoming = EthiopianCalendarEngine.getDayOfWeek(upcomingHoliday.ethiopianDate)
                val daysUntilUpcoming = EthiopianCalendarEngine.daysBetween(todayEth, upcomingHoliday.ethiopianDate)

                Card(
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF0F1B2C)),
                    border = androidx.compose.foundation.BorderStroke(1.2.dp, Color(0xFFF59E0B).copy(alpha = 0.5f)),
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("✨", fontSize = 16.sp)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "NEXT UPCOMING CELEBRATION (ቀጣዩ በዓል)",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = Color(0xFFF59E0B),
                                    letterSpacing = 0.5.sp
                                )
                            }

                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (daysUntilUpcoming == 0L) Color(0xFF10B981) else Color(0xFFF59E0B).copy(alpha = 0.2f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF59E0B).copy(alpha = 0.5f))
                            ) {
                                Text(
                                    text = if (daysUntilUpcoming == 0L) "🎉 TODAY (ዛሬ ነው)!" else "⏳ $daysUntilUpcoming DAYS LEFT (ቀሩ)",
                                    fontSize = 10.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (daysUntilUpcoming == 0L) Color.White else Color(0xFFF59E0B),
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        Text(
                            text = upcomingHoliday.titleAmharic,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color.White
                        )
                        Text(
                            text = upcomingHoliday.titleEnglish,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color(0xFFFBBF24)
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        // Date badge row
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = Color(0xFF1E293B)
                            ) {
                                Text(
                                    text = "📅 ${LocaleStrings.getMonthName(upcomingHoliday.ethiopianDate.month, currentLang)} ${upcomingHoliday.ethiopianDate.day}፣ ${upcomingHoliday.ethiopianDate.year} ዓ.ም",
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = Color.White,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = Color(0xFF1E293B)
                            ) {
                                Text(
                                    text = "🌍 ${gUpcoming.day}/${gUpcoming.month}/${gUpcoming.year} G.C. (${LocaleStrings.getWeekdayShort(dowUpcoming, AppLanguage.ENGLISH)})",
                                    fontSize = 11.5.sp,
                                    color = Color(0xFF94A3B8),
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Quick buttons on hero card
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            val upcomingExisting = viewModel.getEventForHoliday(upcomingHoliday)
                            Button(
                                onClick = {
                                    reminderHolidayDialogTarget = upcomingHoliday
                                },
                                shape = RoundedCornerShape(10.dp),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (upcomingExisting != null) Color(0xFF10B981) else Color(0xFFF59E0B)
                                ),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                                modifier = Modifier.weight(1.2f)
                            ) {
                                Icon(
                                    if (upcomingExisting != null) Icons.Default.NotificationsActive else Icons.Default.Alarm,
                                    contentDescription = null,
                                    tint = if (upcomingExisting != null) Color.White else Color.Black,
                                    modifier = Modifier.size(15.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = if (upcomingExisting != null) "Reminder Set" else "Set Reminder",
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (upcomingExisting != null) Color.White else Color.Black
                                )
                            }

                            OutlinedButton(
                                onClick = { onOpenCardShare(upcomingHoliday) },
                                shape = RoundedCornerShape(10.dp),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.Share, contentDescription = null, tint = Color(0xFFF59E0B), modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Share Card", fontSize = 11.5.sp, color = Color(0xFFF59E0B))
                            }

                            OutlinedButton(
                                onClick = { onSelectHolidayForDetail(upcomingHoliday) },
                                shape = RoundedCornerShape(10.dp),
                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp),
                                modifier = Modifier.weight(0.9f)
                            ) {
                                Icon(Icons.Default.Info, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Details", fontSize = 11.5.sp, color = Color.White)
                            }
                        }
                    }
                }
            }
        }

        // 2. YEAR CONTROLLER & STEPPERS
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(
                            onClick = { if (selectedYear > 1) onYearChange(selectedYear - 1) },
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous Year", modifier = Modifier.size(18.dp))
                        }

                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = MaterialTheme.colorScheme.primaryContainer,
                            modifier = Modifier.clickable { showYearPickerDialog = true }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "$selectedYear ዓ.ም (${selectedYear + 7}/${selectedYear + 8} G.C.) ▾",
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 13.5.sp,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }

                        IconButton(
                            onClick = { onYearChange(selectedYear + 1) },
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next Year", modifier = Modifier.size(18.dp))
                        }
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    // Quick Jump Pills
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        listOf(
                            "Current (ዛሬ)" to todayEth.year,
                            "+10" to todayEth.year + 10,
                            "+25" to todayEth.year + 25,
                            "+50" to todayEth.year + 50,
                            "+100" to todayEth.year + 100
                        ).forEach { (lbl, targetY) ->
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (selectedYear == targetY) MaterialTheme.colorScheme.primary else Color(0xFF1E293B),
                                border = androidx.compose.foundation.BorderStroke(1.dp, if (selectedYear == targetY) MaterialTheme.colorScheme.primary else Color(0xFFF59E0B).copy(alpha = 0.35f)),
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { onYearChange(targetY) }
                            ) {
                                Box(contentAlignment = Alignment.Center, modifier = Modifier.padding(vertical = 5.dp)) {
                                    Text(
                                        text = lbl,
                                        fontSize = 10.5.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (selectedYear == targetY) MaterialTheme.colorScheme.onPrimary else Color(0xFFF59E0B)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. SEARCH BAR WITH CLEAR BUTTON
        item {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search holidays, fasts & feasts (በዓላት ፈልግ)...", fontSize = 12.5.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp)) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }, modifier = Modifier.size(24.dp)) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear", modifier = Modifier.size(16.dp))
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )
        }

        // 4. CATEGORY FILTER CHIPS
        item {
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                listOf(
                    "ALL" to "All (ሁሉም)",
                    "PUBLIC" to "Public (ቀይ ቀን)",
                    "ORTHODOX" to "Orthodox (ተዋሕዶ)",
                    "FASTING" to "Fasting (አጽዋማት)",
                    "ISLAMIC" to "Islamic (እስልምና)",
                    "CULTURAL" to "Cultural (ባህላዊ)"
                ).forEach { (cat, label) ->
                    item {
                        FilterChip(
                            selected = selectedCategory == cat,
                            onClick = { selectedCategory = cat },
                            label = { Text(label, fontSize = 11.sp, fontWeight = FontWeight.SemiBold) }
                        )
                    }
                }
            }
        }

        // 5. HOLIDAY ITEMS COUNT HEADER
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "$selectedYear ዓ.ም (${filteredHolidays.size} በዓላት):",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.primaryContainer,
                    modifier = Modifier.clickable { showBulkScheduleDialog = true }
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.NotificationsActive,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(13.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "Auto-Schedule All",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
            }
        }

        // 6. HOLIDAY CARDS LIST
        if (filteredHolidays.isEmpty()) {
            item {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("🔍", fontSize = 28.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "No holidays found matching \"$searchQuery\"",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Try clearing search filters or changing the category.",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        } else {
            items(filteredHolidays, key = { it.id }) { holiday ->
                val gDate = EthiopianCalendarEngine.toGregorian(holiday.ethiopianDate)
                val dow = EthiopianCalendarEngine.getDayOfWeek(holiday.ethiopianDate)
                val daysUntil = if (holiday.ethiopianDate >= todayEth) {
                    EthiopianCalendarEngine.daysBetween(todayEth, holiday.ethiopianDate)
                } else null

                val isPastThisYear = selectedYear == todayEth.year && holiday.ethiopianDate < todayEth

                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        if (holiday.isPublicHoliday) Color(0xFFEF4444).copy(alpha = 0.45f)
                        else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onSelectHolidayForDetail(holiday) }
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.Top
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    if (holiday.isPublicHoliday) {
                                        Surface(
                                            shape = RoundedCornerShape(6.dp),
                                            color = Color(0xFFEF4444)
                                        ) {
                                            Text(
                                                text = "ቀይ ቀን / Public Holiday",
                                                fontSize = 9.5.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                    }

                                    if (holiday.isFasting) {
                                        Surface(
                                            shape = RoundedCornerShape(6.dp),
                                            color = Color(0xFF10B981)
                                        ) {
                                            Text(
                                                text = "ጾም / Fast",
                                                fontSize = 9.5.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(4.dp))

                                Text(
                                    text = holiday.titleAmharic,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 16.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = holiday.titleEnglish,
                                    fontSize = 12.5.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }

                            // Days countdown badge
                            if (daysUntil != null && selectedYear == todayEth.year) {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = if (daysUntil == 0L) Color(0xFF10B981) else Color(0xFF3B82F6).copy(alpha = 0.15f),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, if (daysUntil == 0L) Color(0xFF10B981) else Color(0xFF3B82F6).copy(alpha = 0.4f))
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 7.dp, vertical = 3.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.HourglassBottom,
                                            contentDescription = null,
                                            tint = if (daysUntil == 0L) Color.White else Color(0xFF2563EB),
                                            modifier = Modifier.size(12.dp)
                                        )
                                        Spacer(modifier = Modifier.width(3.dp))
                                        Text(
                                            text = if (daysUntil == 0L) "ዛሬ ነው!" else "$daysUntil ቀናት",
                                            fontSize = 10.5.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (daysUntil == 0L) Color.White else Color(0xFF2563EB)
                                        )
                                    }
                                }
                            } else if (isPastThisYear) {
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = MaterialTheme.colorScheme.surfaceVariant
                                ) {
                                    Text(
                                        text = "Passed",
                                        fontSize = 10.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(6.dp))

                        Text(
                            text = holiday.description,
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 16.sp,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )

                        Spacer(modifier = Modifier.height(10.dp))

                        // Footer row: Dates & Quick Action Buttons
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
                            ) {
                                Text(
                                    text = "📅 ${LocaleStrings.getMonthName(holiday.ethiopianDate.month, currentLang)} ${holiday.ethiopianDate.day} • ${gDate.day}/${gDate.month} G.C. (${LocaleStrings.getWeekdayShort(dow, currentLang)})",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }

                            Row(
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                val existingReminder = viewModel.getEventForHoliday(holiday)
                                if (existingReminder != null) {
                                    Surface(
                                        shape = RoundedCornerShape(6.dp),
                                        color = Color(0xFFF59E0B).copy(alpha = 0.2f),
                                        modifier = Modifier.clickable { reminderHolidayDialogTarget = holiday }
                                    ) {
                                        Text(
                                            text = "🔔 %02d:%02d".format(existingReminder.hour, existingReminder.minute),
                                            fontSize = 10.5.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFFF59E0B),
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }

                                // Set / Edit Reminder
                                IconButton(
                                    onClick = {
                                        reminderHolidayDialogTarget = holiday
                                    },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        if (existingReminder != null) Icons.Default.NotificationsActive else Icons.Default.Alarm,
                                        contentDescription = "Set Reminder",
                                        tint = if (existingReminder != null) Color(0xFFF59E0B) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                                        modifier = Modifier.size(18.dp)
                                    )
                                }

                                // Share Greeting Card
                                IconButton(
                                    onClick = { onOpenCardShare(holiday) },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Share,
                                        contentDescription = "Share",
                                        tint = Color(0xFFF59E0B),
                                        modifier = Modifier.size(18.dp)
                                    )
                                }

                                // Info Details
                                IconButton(
                                    onClick = { onSelectHolidayForDetail(holiday) },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Info,
                                        contentDescription = "Details",
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Direct Year Jump Dialog
    if (showYearPickerDialog) {
        var tempYearText by remember { mutableStateOf(selectedYear.toString()) }
        AlertDialog(
            onDismissRequest = { showYearPickerDialog = false },
            title = { Text("ዓመት ይምረጡ (Select Ethiopian Year)") },
            text = {
                Column {
                    Text(
                        "የሚፈልጉትን የኢትዮጵያ ዓመት ያስገቡ ወይም ፈጣን መዝለያዎችን ይጠቀሙ:",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = tempYearText,
                        onValueChange = { tempYearText = it },
                        label = { Text("Year E.C. (1-9999)") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text("ፈጣን መዝለያዎች (Centuries & Milestones):", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        listOf(
                            todayEth.year,
                            todayEth.year + 10,
                            todayEth.year + 25,
                            todayEth.year + 50,
                            todayEth.year + 100
                        ).forEach { y ->
                            FilterChip(
                                selected = tempYearText == y.toString(),
                                onClick = { tempYearText = y.toString() },
                                label = { Text("$y", fontSize = 10.sp) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        tempYearText.toIntOrNull()?.let { y ->
                            if (y in 1..9999) onYearChange(y)
                        }
                        showYearPickerDialog = false
                    }
                ) {
                    Text("አረጋግጥ (OK)")
                }
            },
            dismissButton = {
                TextButton(onClick = { showYearPickerDialog = false }) {
                    Text("ይቅር (Cancel)")
                }
            }
        )
    }

    // Set Holiday Reminder Dialog
    if (reminderHolidayDialogTarget != null) {
        val targetH = reminderHolidayDialogTarget!!
        val existingEvent = viewModel.getEventForHoliday(targetH)
        SetHolidayReminderDialog(
            holiday = targetH,
            existingEvent = existingEvent,
            currentLang = currentLang,
            onDismiss = { reminderHolidayDialogTarget = null },
            onSaveReminder = { hour, minute, onEve, offset ->
                viewModel.scheduleHolidayReminder(targetH, hour, minute, onEve, offset) {
                    Toast.makeText(
                        context,
                        "🔔 ማሳሰቢያ ተይዟል! (Reminder set for %02d:%02d)".format(hour, minute),
                        Toast.LENGTH_SHORT
                    ).show()
                }
            },
            onDeleteReminder = {
                viewModel.cancelHolidayReminder(targetH) {
                    Toast.makeText(context, "የበዓል ማሳሰቢያው ተሰርዟል (Reminder removed)", Toast.LENGTH_SHORT).show()
                }
            }
        )
    }

    // Auto-Schedule All Annual Holidays Dialog
    if (showBulkScheduleDialog) {
        var bulkHour by remember { mutableIntStateOf(8) }
        var bulkMinute by remember { mutableIntStateOf(0) }

        AlertDialog(
            onDismissRequest = { showBulkScheduleDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.NotificationsActive, contentDescription = null, tint = Color(0xFFF59E0B), modifier = Modifier.size(22.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("ሁሉንም በዓላት ማሳሰቢያ ያድርጉ", fontSize = 15.sp, fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column {
                    Text(
                        text = "ለ $selectedYear ዓ.ም ሁሉም ብሔራዊ እና ዋና ዋና የሃይማኖት በዓላት የማሳሰቢያ ደወል በራስ-ሰር ይዘጋጃል።",
                        fontSize = 12.5.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(14.dp))
                    Text("የማሳሰቢያ ሰዓት (Default Alert Time):", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
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
                        ).forEach { (h, label) ->
                            val isSel = bulkHour == h && bulkMinute == 0
                            FilterChip(
                                selected = isSel,
                                onClick = {
                                    bulkHour = h
                                    bulkMinute = 0
                                },
                                label = { Text(label, fontSize = 10.5.sp) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.scheduleAllAnnualHolidays(selectedYear, bulkHour, bulkMinute, reminderMinutesBefore = 0) { count ->
                            Toast.makeText(
                                context,
                                "🔔 ለ $count በዓላት ማሳሰቢያ ተይዟል! (Scheduled reminders for $count holidays)",
                                Toast.LENGTH_LONG
                            ).show()
                        }
                        showBulkScheduleDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Text("ሁሉንም አስቀምጥ (Schedule All)")
                }
            },
            dismissButton = {
                TextButton(onClick = { showBulkScheduleDialog = false }) {
                    Text("ይቅር (Cancel)")
                }
            }
        )
    }
}
