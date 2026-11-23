package com.example.calendar.ui.screens.holidays

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SetHolidayReminderDialog(
    holiday: HolidayEngine.Holiday,
    existingEvent: EventEntity?,
    currentLang: AppLanguage,
    onDismiss: () -> Unit,
    onSaveReminder: (alertHour: Int, alertMinute: Int, remindOnEve: Boolean, reminderMinutesBefore: Int) -> Unit,
    onDeleteReminder: () -> Unit
) {
    val isEveInitial = existingEvent?.title?.contains("[ዋዜማ", ignoreCase = true) == true
    var remindOnEve by remember { mutableStateOf(isEveInitial) }
    var selectedHour by remember { mutableIntStateOf(existingEvent?.hour ?: 8) }
    var selectedMinute by remember { mutableIntStateOf(existingEvent?.minute ?: 0) }
    var showTimePickerDialog by remember { mutableStateOf(false) }
    var reminderOffsetMinutes by remember { mutableIntStateOf(existingEvent?.reminderMinutesBefore ?: 0) }

    val dow = EthiopianCalendarEngine.getDayOfWeek(holiday.ethiopianDate)
    val gDate = EthiopianCalendarEngine.toGregorian(holiday.ethiopianDate)

    // Calculate target date based on Eve selection
    val effectiveDate = remember(remindOnEve, holiday.ethiopianDate) {
        if (remindOnEve) {
            if (holiday.ethiopianDate.day > 1) {
                EthiopianDate(holiday.ethiopianDate.year, holiday.ethiopianDate.month, holiday.ethiopianDate.day - 1)
            } else {
                val prevMonth = if (holiday.ethiopianDate.month > 1) holiday.ethiopianDate.month - 1 else 13
                val prevYear = if (holiday.ethiopianDate.month > 1) holiday.ethiopianDate.year else holiday.ethiopianDate.year - 1
                val prevMonthDays = EthiopianDate.daysInMonth(prevYear, prevMonth)
                EthiopianDate(prevYear, prevMonth, prevMonthDays)
            }
        } else {
            holiday.ethiopianDate
        }
    }
    val effectiveGDate = remember(effectiveDate) {
        EthiopianCalendarEngine.toGregorian(effectiveDate)
    }

    val ethTime = remember(selectedHour, selectedMinute) {
        EthiopianTimeConverter.gregorianToEthiopian(selectedHour, selectedMinute)
    }

    val quickTimePresets = listOf(
        Triple(6, 0, "6:00 AM (12:00 ንጋት)"),
        Triple(7, 0, "7:00 AM (1:00 ጧት)"),
        Triple(8, 0, "8:00 AM (2:00 ጧት)"),
        Triple(9, 0, "9:00 AM (3:00 ጧት)"),
        Triple(12, 0, "12:00 PM (6:00 ቀትር)"),
        Triple(18, 0, "6:00 PM (12:00 ምሽት)"),
        Triple(20, 0, "8:00 PM (2:00 ምሽት)")
    )

    val reminderOffsets = listOf(
        0 to "በተመረጠው ሰዓት (At exact alert time)",
        15 to "ከ15 ደቂቃ በፊት (15 mins before)",
        30 to "ከ30 ደቂቃ በፊት (30 mins before)",
        60 to "ከ1 ሰዓት በፊት (1 hour before)",
        120 to "ከ2 ሰዓት በፊት (2 hours before)",
        1440 to "ከ1 ቀን በፊት (1 day before)"
    )

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 8.dp,
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .padding(vertical = 20.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                // Top Header Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = Color(0xFFF59E0B).copy(alpha = 0.2f),
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Default.NotificationsActive,
                                    contentDescription = null,
                                    tint = Color(0xFFF59E0B),
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                        Column {
                            Text(
                                text = "የበዓል ማሳሰቢያ ደወል",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = "Set Holiday Reminder Alert",
                                fontSize = 11.5.sp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }

                    IconButton(onClick = onDismiss, modifier = Modifier.size(32.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Holiday Summary Banner
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)),
                    border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            text = holiday.titleAmharic,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = holiday.titleEnglish,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "📅 ${LocaleStrings.getMonthName(holiday.ethiopianDate.month, currentLang)} ${holiday.ethiopianDate.day}, ${holiday.ethiopianDate.year} ዓ.ም • ${gDate.day}/${gDate.month}/${gDate.year} G.C. (${LocaleStrings.getWeekdayLong(dow, currentLang)})",
                            fontSize = 11.5.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Existing reminder badge if active
                if (existingEvent != null) {
                    Spacer(modifier = Modifier.height(10.dp))
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = Color(0xFF10B981).copy(alpha = 0.15f),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF10B981).copy(alpha = 0.4f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Alarm, contentDescription = null, tint = Color(0xFF10B981), modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Column {
                                Text(
                                    text = "ይህ በዓል ቀደም ሲል ማሳሰቢያ ተይዞለታል (Reminder Active)",
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF047857)
                                )
                                Text(
                                    text = "ሰዓት: %02d:%02d".format(existingEvent.hour, existingEvent.minute) +
                                            if (existingEvent.reminderMinutesBefore > 0) " (${existingEvent.reminderMinutesBefore} mins prior)" else "",
                                    fontSize = 11.sp,
                                    color = Color(0xFF065F46)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // 1. DATE OF ALERT SELECTION (Holiday Day vs Eve)
                Text(
                    text = "1. የማሳሰቢያ ቀን ይምረጡ (Alert Date):",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    FilterChip(
                        selected = !remindOnEve,
                        onClick = { remindOnEve = false },
                        label = { Text("በበዓሉ ቀን (On Day)", fontSize = 11.5.sp) },
                        leadingIcon = if (!remindOnEve) { { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp)) } } else null,
                        modifier = Modifier.weight(1f)
                    )
                    FilterChip(
                        selected = remindOnEve,
                        onClick = { remindOnEve = true },
                        label = { Text("ዋዜማ (On Eve)", fontSize = 11.5.sp) },
                        leadingIcon = if (remindOnEve) { { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp)) } } else null,
                        modifier = Modifier.weight(1f)
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = if (remindOnEve) "🔔 ማሳሰቢያው በበዓሉ ዋዜማ ቀን (${LocaleStrings.getMonthName(effectiveDate.month, currentLang)} ${effectiveDate.day} • ${effectiveGDate.day}/${effectiveGDate.month}) ይደውላል።"
                           else "🔔 ማሳሰቢያው በራሱ በበዓሉ ቀን (${LocaleStrings.getMonthName(effectiveDate.month, currentLang)} ${effectiveDate.day} • ${effectiveGDate.day}/${effectiveGDate.month}) ይደውላል።",
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(16.dp))

                // 2. ALERT TIME SELECTION (Quick Presets)
                Text(
                    text = "2. የማሳሰቢያ ሰዓት (Alert Time):",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(8.dp))

                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    quickTimePresets.chunked(2).forEach { rowPresets ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            rowPresets.forEach { (h, m, label) ->
                                val isSelected = selectedHour == h && selectedMinute == m
                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                                    border = androidx.compose.foundation.BorderStroke(
                                        1.dp,
                                        if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent
                                    ),
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable {
                                            selectedHour = h
                                            selectedMinute = m
                                        }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.AccessTime,
                                            contentDescription = null,
                                            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(14.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = label,
                                            fontSize = 11.sp,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                            color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                            if (rowPresets.size == 1) {
                                Spacer(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Exact Custom Clock Time Picker Button
                OutlinedButton(
                    onClick = { showTimePickerDialog = true },
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("holiday_pick_custom_time_button")
                ) {
                    Icon(Icons.Default.Schedule, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "ብጁ ሰዓትና ደቂቃ ይምረጡ (Custom Time: %02d:%02d)".format(selectedHour, selectedMinute),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Ethiopian Clock Equivalent Card
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = Color(0xFF0F1B2C),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF59E0B).copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("🇪🇹", fontSize = 16.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(
                                text = "የኢትዮጵያ ሰዓት አቆጣጠር:",
                                fontSize = 10.5.sp,
                                color = Color(0xFFF59E0B),
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "${ethTime.formatted()} (Gregorian: %02d:%02d)".format(selectedHour, selectedMinute),
                                fontSize = 12.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color.White
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // 3. ADVANCE REMINDER OFFSET
                Text(
                    text = "3. ቀድሞ የማስታወቂያ ጊዜ (Advance Alert):",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(6.dp))

                var offsetExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = offsetExpanded,
                    onExpandedChange = { offsetExpanded = !offsetExpanded },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = reminderOffsets.firstOrNull { it.first == reminderOffsetMinutes }?.second ?: "$reminderOffsetMinutes mins prior",
                        onValueChange = {},
                        readOnly = true,
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = offsetExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                    )
                    ExposedDropdownMenu(
                        expanded = offsetExpanded,
                        onDismissRequest = { offsetExpanded = false }
                    ) {
                        for ((mins, label) in reminderOffsets) {
                            DropdownMenuItem(
                                text = { Text(label, fontSize = 12.5.sp) },
                                onClick = {
                                    reminderOffsetMinutes = mins
                                    offsetExpanded = false
                                }
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (existingEvent != null) {
                        OutlinedButton(
                            onClick = {
                                onDeleteReminder()
                                onDismiss()
                            },
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFEF4444)),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.testTag("delete_holiday_reminder_button")
                        ) {
                            Icon(Icons.Default.Delete, contentDescription = "Delete", modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("አስወግድ (Remove)", fontSize = 11.5.sp)
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    TextButton(onClick = onDismiss) {
                        Text("ይቅር (Cancel)")
                    }

                    Button(
                        onClick = {
                            onSaveReminder(selectedHour, selectedMinute, remindOnEve, reminderOffsetMinutes)
                            onDismiss()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("save_holiday_reminder_button")
                    ) {
                        Icon(Icons.Default.Alarm, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (existingEvent != null) "አዘምን (Update)" else "አዘጋጅ (Set Reminder)",
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }

    if (showTimePickerDialog) {
        val timePickerState = rememberTimePickerState(
            initialHour = selectedHour,
            initialMinute = selectedMinute,
            is24Hour = false
        )
        AlertDialog(
            onDismissRequest = { showTimePickerDialog = false },
            title = {
                Column {
                    Text(
                        text = "ብጁ የበዓል ማሳሰቢያ ሰዓት",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                    val previewEth = EthiopianTimeConverter.gregorianToEthiopian(
                        timePickerState.hour,
                        timePickerState.minute
                    )
                    Text(
                        text = "🇪🇹 የኢትዮጵያ ሰዓት: ${previewEth.formatted()}",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            },
            text = {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    TimePicker(state = timePickerState)
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        selectedHour = timePickerState.hour
                        selectedMinute = timePickerState.minute
                        showTimePickerDialog = false
                    }
                ) {
                    Text("አረጋግጥ (Confirm)")
                }
            },
            dismissButton = {
                TextButton(onClick = { showTimePickerDialog = false }) {
                    Text("ይቅር (Cancel)")
                }
            }
        )
    }
}
