package com.example.calendar.ui.screens.events

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.NotificationsOff
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
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.core.graphics.toColorInt
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.notification.NotificationScheduler

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditEventDialog(
    initialDate: EthiopianDate,
    eventToEdit: EventEntity? = null,
    currentLanguage: AppLanguage,
    onDismiss: () -> Unit,
    onSave: (EventEntity) -> Unit
) {
    val context = LocalContext.current

    var title by remember { mutableStateOf(eventToEdit?.title ?: "") }
    var description by remember { mutableStateOf(eventToEdit?.description ?: "") }
    var category by remember { mutableStateOf(eventToEdit?.category ?: "TASK") }

    var ethYear by remember { mutableIntStateOf(eventToEdit?.ethiopianYear ?: initialDate.year) }
    var ethMonth by remember { mutableIntStateOf(eventToEdit?.ethiopianMonth ?: initialDate.month) }
    var ethDay by remember { mutableIntStateOf(eventToEdit?.ethiopianDay ?: initialDate.day) }
    var yearText by remember { mutableStateOf((eventToEdit?.ethiopianYear ?: initialDate.year).toString()) }

    var isAllDay by remember { mutableStateOf(eventToEdit?.isAllDay ?: true) }
    var hour by remember { mutableIntStateOf(eventToEdit?.hour ?: 9) }
    var minute by remember { mutableIntStateOf(eventToEdit?.minute ?: 0) }
    var showTimePickerDialog by remember { mutableStateOf(false) }

    var recurrence by remember { mutableStateOf(eventToEdit?.recurrence ?: "NONE") }
    val initialReminder = eventToEdit?.reminderMinutesBefore ?: 15
    var reminderMinutes by remember { mutableIntStateOf(initialReminder) }

    val presetReminderValues = remember { setOf(-1, 0, 5, 10, 15, 30, 60, 120, 1440) }
    var isCustomOffsetMode by remember {
        mutableStateOf(initialReminder > 0 && initialReminder !in presetReminderValues)
    }
    var customOffsetUnit by remember {
        mutableStateOf(
            when {
                initialReminder > 0 && initialReminder % 1440 == 0 -> "DAYS"
                initialReminder > 0 && initialReminder % 60 == 0 -> "HOURS"
                else -> "MINUTES"
            }
        )
    }
    var customOffsetValueText by remember {
        mutableStateOf(
            when {
                initialReminder <= 0 -> "45"
                initialReminder % 1440 == 0 -> (initialReminder / 1440).toString()
                initialReminder % 60 == 0 -> (initialReminder / 60).toString()
                else -> initialReminder.toString()
            }
        )
    }

    var selectedColor by remember { mutableStateOf(eventToEdit?.colorHex ?: "#F59E0B") }

    val categories = listOf(
        "TASK" to "✅ ተግባር (Task)",
        "MEETING" to "💼 ስብሰባ (Meeting)",
        "BIRTHDAY" to "🎂 የልደት ቀን (Birthday)",
        "EXAM" to "📚 ፈተና (Exam)",
        "ANNIVERSARY" to "💍 መታሰቢያ (Anniversary)",
        "RELIGIOUS" to "⛪ ሃይማኖታዊ (Religious)",
        "CULTURAL" to "🇪🇹 ባህላዊ (Cultural)",
        "OTHER" to "📌 ሌላ (Other)"
    )

    val recurrences = listOf(
        "NONE" to "አይደገምም (Once)",
        "DAILY" to "በየቀኑ (Daily)",
        "WEEKLY" to "በየሳምንቱ (Weekly)",
        "MONTHLY_ETHIOPIAN" to "በየወሩ በኢትዮጵያ ቀን (Monthly Eth)",
        "MONTHLY_GREGORIAN" to "በየወሩ በፈረንጅ ቀን (Monthly Greg)",
        "YEARLY_ETHIOPIAN" to "በየዓመቱ በኢትዮጵያ ቀን (Yearly Eth)",
        "YEARLY_GREGORIAN" to "በየዓመቱ በፈረንጅ ቀን (Yearly Greg)"
    )

    val reminderPresets = listOf(
        -1 to "ጠፍቷል (Off)",
        0 to "በሰዓቱ (At time)",
        5 to "5 ደቂቃ (5m)",
        10 to "10 ደቂቃ (10m)",
        15 to "15 ደቂቃ (15m)",
        30 to "30 ደቂቃ (30m)",
        60 to "1 ሰዓት (1h)",
        120 to "2 ሰዓት (2h)",
        1440 to "1 ቀን (1d)"
    )

    val quickClockPresets = listOf(
        Triple(6, 0, "6:00 AM"),
        Triple(7, 30, "7:30 AM"),
        Triple(8, 0, "8:00 AM"),
        Triple(9, 0, "9:00 AM"),
        Triple(12, 0, "12:00 PM"),
        Triple(15, 0, "3:00 PM"),
        Triple(18, 0, "6:00 PM"),
        Triple(20, 0, "8:00 PM")
    )

    val colors = listOf(
        "#F59E0B", "#10B981", "#E11D48", "#6366F1", "#0284C7", "#8B5CF6", "#EC4899"
    )

    // Sync corresponding Gregorian date
    val correspondingGregorian = remember(ethYear, ethMonth, ethDay) {
        val maxDays = EthiopianDate.daysInMonth(ethYear, ethMonth)
        val safeDay = ethDay.coerceIn(1, maxDays)
        EthiopianCalendarEngine.toGregorian(EthiopianDate(ethYear, ethMonth, safeDay))
    }

    val ethTime = remember(hour, minute) {
        EthiopianTimeConverter.gregorianToEthiopian(hour, minute)
    }

    val previewEvent = remember(
        title, category, ethYear, ethMonth, ethDay, correspondingGregorian,
        hour, minute, isAllDay, recurrence, reminderMinutes
    ) {
        EventEntity(
            id = eventToEdit?.id ?: 0L,
            title = title.ifBlank { "Event" },
            category = category,
            ethiopianYear = ethYear,
            ethiopianMonth = ethMonth,
            ethiopianDay = ethDay.coerceIn(1, EthiopianDate.daysInMonth(ethYear, ethMonth)),
            gregorianYear = correspondingGregorian.year,
            gregorianMonth = correspondingGregorian.month,
            gregorianDay = correspondingGregorian.day,
            hour = hour,
            minute = minute,
            isAllDay = isAllDay,
            recurrence = recurrence,
            reminderMinutesBefore = reminderMinutes,
            isCompleted = false
        )
    }

    val nextTriggerMillis = remember(previewEvent) {
        NotificationScheduler.calculateNextTriggerTime(previewEvent)
    }

    var pendingEventToSave by remember { mutableStateOf<EventEntity?>(null) }
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) {
        pendingEventToSave?.let { ev ->
            pendingEventToSave = null
            onSave(ev)
        }
    }

    fun applyCustomOffset(rawText: String, unit: String) {
        val num = rawText.toIntOrNull()?.coerceIn(1, 365 * 24 * 60) ?: return
        val multiplier = when (unit) {
            "DAYS" -> 1440
            "HOURS" -> 60
            else -> 1
        }
        reminderMinutes = (num * multiplier).coerceAtLeast(1)
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 8.dp,
            modifier = Modifier
                .fillMaxWidth(0.93f)
                .padding(vertical = 16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = if (eventToEdit == null) "አዲስ ማስታወሻ (New Event)" else "ማስታወሻ አርትዕ (Edit Event)",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = "ቀን፣ ሰዓት እና ብጁ የማሳሰቢያ ደወል ያዘጋጁ",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    IconButton(onClick = onDismiss, modifier = Modifier.size(36.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Title
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("ርዕስ (Title) *") },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("event_title_input")
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Description
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("ዝርዝር መግለጫ (Description)") },
                    maxLines = 3,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Ethiopian Date Selector
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.Event,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "የኢትዮጵያ ቀን (Ethiopian Date)",
                                style = MaterialTheme.typography.labelLarge,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            // Month Dropdown
                            var monthExpanded by remember { mutableStateOf(false) }
                            ExposedDropdownMenuBox(
                                expanded = monthExpanded,
                                onExpandedChange = { monthExpanded = !monthExpanded },
                                modifier = Modifier.weight(1.5f)
                            ) {
                                OutlinedTextField(
                                    value = LocaleStrings.getMonthName(ethMonth, currentLanguage),
                                    onValueChange = {},
                                    readOnly = true,
                                    label = { Text("ወር (Month)", fontSize = 11.sp) },
                                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = monthExpanded) },
                                    modifier = Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable)
                                )
                                ExposedDropdownMenu(
                                    expanded = monthExpanded,
                                    onDismissRequest = { monthExpanded = false }
                                ) {
                                    for (m in 1..13) {
                                        DropdownMenuItem(
                                            text = { Text("$m. ${LocaleStrings.getMonthName(m, currentLanguage)}") },
                                            onClick = {
                                                ethMonth = m
                                                val max = EthiopianDate.daysInMonth(ethYear, m)
                                                if (ethDay > max) ethDay = max
                                                monthExpanded = false
                                            }
                                        )
                                    }
                                }
                            }

                            // Day Dropdown
                            var dayExpanded by remember { mutableStateOf(false) }
                            val maxDays = EthiopianDate.daysInMonth(ethYear, ethMonth)
                            ExposedDropdownMenuBox(
                                expanded = dayExpanded,
                                onExpandedChange = { dayExpanded = !dayExpanded },
                                modifier = Modifier.weight(1f)
                            ) {
                                OutlinedTextField(
                                    value = ethDay.toString(),
                                    onValueChange = {},
                                    readOnly = true,
                                    label = { Text("ቀን (Day)", fontSize = 11.sp) },
                                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = dayExpanded) },
                                    modifier = Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable)
                                )
                                ExposedDropdownMenu(
                                    expanded = dayExpanded,
                                    onDismissRequest = { dayExpanded = false }
                                ) {
                                    for (d in 1..maxDays) {
                                        DropdownMenuItem(
                                            text = { Text(d.toString()) },
                                            onClick = {
                                                ethDay = d
                                                dayExpanded = false
                                            }
                                        )
                                    }
                                }
                            }

                            // Year
                            OutlinedTextField(
                                value = yearText,
                                onValueChange = { raw ->
                                    if (raw.length <= 4 && raw.all { it.isDigit() }) {
                                        yearText = raw
                                        raw.toIntOrNull()?.let { y ->
                                            if (y in 1900..2100) {
                                                ethYear = y
                                                val max = EthiopianDate.daysInMonth(y, ethMonth)
                                                if (ethDay > max) ethDay = max
                                            }
                                        }
                                    }
                                },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                                label = { Text("ዓመት (Year)", fontSize = 11.sp) },
                                modifier = Modifier.weight(1.2f)
                            )
                        }

                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "🗓️ Gregorian: ${correspondingGregorian.day} / ${correspondingGregorian.month} / ${correspondingGregorian.year} G.C.",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // All day toggle
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("ሙሉ ቀን (All Day)", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                        Text(
                            text = if (isAllDay) "ክስተቱ ቀኑን ሙሉ የሚዘልቅ ነው (ከታች የማሳሰቢያ ሰዓት ይምረጡ)" else "የተወሰነ ሰዓት ያለው ክስተት",
                            fontSize = 11.5.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = isAllDay,
                        onCheckedChange = { isAllDay = it }
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Custom Alert / Event Clock Time Picker Card
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.25f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = if (isAllDay) "⏰ የማሳሰቢያ ሰዓት (Alert Time)" else "⏰ የክስተቱ ሰዓት (Event Time)",
                                    fontSize = 12.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = "${NotificationScheduler.formatClock12h(hour, minute)} • ${ethTime.formatted()}",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }

                            Button(
                                onClick = { showTimePickerDialog = true },
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.testTag("pick_custom_time_button")
                            ) {
                                Icon(Icons.Default.Schedule, contentDescription = "Pick custom time", modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("ሰዓት ምረጥ", fontSize = 11.5.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Quick Clock Presets Row (horizontally scrollable)
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            quickClockPresets.forEach { (h, m, lbl) ->
                                val isSel = hour == h && minute == m
                                FilterChip(
                                    selected = isSel,
                                    onClick = {
                                        hour = h
                                        minute = m
                                    },
                                    label = { Text(lbl, fontSize = 11.sp) }
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Category Dropdown
                var catExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = catExpanded,
                    onExpandedChange = { catExpanded = !catExpanded },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = categories.firstOrNull { it.first == category }?.second ?: category,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("ምድብ (Category)") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = catExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                    )
                    ExposedDropdownMenu(
                        expanded = catExpanded,
                        onDismissRequest = { catExpanded = false }
                    ) {
                        for ((key, label) in categories) {
                            DropdownMenuItem(
                                text = { Text(label) },
                                onClick = {
                                    category = key
                                    catExpanded = false
                                }
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Recurrence
                var recExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = recExpanded,
                    onExpandedChange = { recExpanded = !recExpanded },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = recurrences.firstOrNull { it.first == recurrence }?.second ?: recurrence,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("ድግግሞሽ (Recurrence)") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = recExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                    )
                    ExposedDropdownMenu(
                        expanded = recExpanded,
                        onDismissRequest = { recExpanded = false }
                    ) {
                        for ((key, label) in recurrences) {
                            DropdownMenuItem(
                                text = { Text(label) },
                                onClick = {
                                    recurrence = key
                                    recExpanded = false
                                }
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Reminder Notification Section (Presets + Custom Alert Offset)
                Text(
                    text = "🔔 ማሳሰቢያ ደወል (Alert Timing)",
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    reminderPresets.forEach { (mins, label) ->
                        val isSelected = !isCustomOffsetMode && reminderMinutes == mins
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                isCustomOffsetMode = false
                                reminderMinutes = mins
                            },
                            label = { Text(label, fontSize = 11.sp) }
                        )
                    }
                    FilterChip(
                        selected = isCustomOffsetMode,
                        onClick = {
                            isCustomOffsetMode = true
                            applyCustomOffset(customOffsetValueText, customOffsetUnit)
                        },
                        label = { Text("⚙️ ብጁ (Custom)", fontSize = 11.sp, fontWeight = FontWeight.SemiBold) },
                        modifier = Modifier.testTag("custom_reminder_chip")
                    )
                }

                // Inline Custom Offset Controls
                AnimatedVisibility(visible = isCustomOffsetMode) {
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.35f)),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp)
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(
                                text = "ብጁ የቅድሚያ ማሳሰቢያ ጊዜ (Custom Time Before Event):",
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                OutlinedTextField(
                                    value = customOffsetValueText,
                                    onValueChange = { raw ->
                                        if (raw.length <= 4 && raw.all { it.isDigit() }) {
                                            customOffsetValueText = raw
                                            applyCustomOffset(raw, customOffsetUnit)
                                        }
                                    },
                                    label = { Text("ብዛት (Amount)", fontSize = 11.sp) },
                                    singleLine = true,
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                    modifier = Modifier
                                        .weight(1f)
                                        .testTag("custom_reminder_amount_input")
                                )

                                listOf(
                                    "MINUTES" to "ደቂቃ\nMins",
                                    "HOURS" to "ሰዓት\nHrs",
                                    "DAYS" to "ቀን\nDays"
                                ).forEach { (unit, label) ->
                                    val sel = customOffsetUnit == unit
                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = if (sel) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface,
                                        border = BorderStroke(1.dp, if (sel) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant),
                                        modifier = Modifier
                                            .clickable {
                                                customOffsetUnit = unit
                                                applyCustomOffset(customOffsetValueText, unit)
                                            }
                                    ) {
                                        Text(
                                            text = label,
                                            fontSize = 10.5.sp,
                                            fontWeight = if (sel) FontWeight.Bold else FontWeight.Normal,
                                            color = if (sel) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface,
                                            textAlign = TextAlign.Center,
                                            lineHeight = 13.sp,
                                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 7.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Live Alert Trigger Preview Banner
                val isReminderDisabled = reminderMinutes < 0
                val triggerSummary = nextTriggerMillis?.let {
                    NotificationScheduler.formatTimestampSummary(it, currentLanguage)
                }
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = when {
                        isReminderDisabled -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)
                        triggerSummary != null -> Color(0xFF0B1526)
                        else -> MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.55f)
                    },
                    border = BorderStroke(
                        1.dp,
                        when {
                            isReminderDisabled -> MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                            triggerSummary != null -> Color(0xFFF59E0B).copy(alpha = 0.45f)
                            else -> MaterialTheme.colorScheme.error.copy(alpha = 0.45f)
                        }
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("reminder_preview_banner")
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 9.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isReminderDisabled) Icons.Default.NotificationsOff else Icons.Default.NotificationsActive,
                            contentDescription = null,
                            tint = when {
                                isReminderDisabled -> MaterialTheme.colorScheme.onSurfaceVariant
                                triggerSummary != null -> Color(0xFFF59E0B)
                                else -> MaterialTheme.colorScheme.error
                            },
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(
                                text = when {
                                    isReminderDisabled -> "ማሳሰቢያ ጠፍቷል (No notification alert)"
                                    triggerSummary != null -> "ማሳሰቢያ የሚደውልበት (Scheduled Alert):"
                                    else -> "የተመረጠው ሰዓት አልፏል (Alert time is in the past)"
                                },
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = when {
                                    isReminderDisabled -> MaterialTheme.colorScheme.onSurfaceVariant
                                    triggerSummary != null -> Color(0xFFF59E0B)
                                    else -> MaterialTheme.colorScheme.error
                                }
                            )
                            if (triggerSummary != null && !isReminderDisabled) {
                                Text(
                                    text = triggerSummary,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color.White
                                )
                            } else if (!isReminderDisabled && triggerSummary == null) {
                                Text(
                                    text = "ማሳሰቢያው እንዲደርስ ወደፊት ያለ ቀን ወይም ሰዓት ይምረጡ።",
                                    fontSize = 10.5.sp,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Color picker
                Text("የቀለም መለያ (Color Tag)", style = MaterialTheme.typography.labelMedium)
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    colors.forEach { hex ->
                        val color = Color(hex.toColorInt())
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(CircleShape)
                                .background(color)
                                .clickable { selectedColor = hex }
                                .padding(2.dp)
                        ) {
                            if (selectedColor == hex) {
                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .clip(CircleShape)
                                        .background(Color.White)
                                        .align(Alignment.Center)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("ሰርዝ (Cancel)")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = {
                            if (title.isNotBlank()) {
                                val safeMaxDays = EthiopianDate.daysInMonth(ethYear, ethMonth)
                                val safeDay = ethDay.coerceIn(1, safeMaxDays)
                                val gDate = EthiopianCalendarEngine.toGregorian(
                                    EthiopianDate(ethYear, ethMonth, safeDay)
                                )
                                val event = EventEntity(
                                    id = eventToEdit?.id ?: 0L,
                                    title = title.trim(),
                                    description = description.trim(),
                                    category = category,
                                    ethiopianYear = ethYear,
                                    ethiopianMonth = ethMonth,
                                    ethiopianDay = safeDay,
                                    gregorianYear = gDate.year,
                                    gregorianMonth = gDate.month,
                                    gregorianDay = gDate.day,
                                    hour = hour,
                                    minute = minute,
                                    isAllDay = isAllDay,
                                    recurrence = recurrence,
                                    reminderMinutesBefore = reminderMinutes,
                                    colorHex = selectedColor,
                                    isCompleted = eventToEdit?.isCompleted ?: false
                                )

                                val needsNotifPerm = reminderMinutes >= 0 &&
                                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                                    ContextCompat.checkSelfPermission(
                                        context,
                                        Manifest.permission.POST_NOTIFICATIONS
                                    ) != PackageManager.PERMISSION_GRANTED

                                if (needsNotifPerm) {
                                    pendingEventToSave = event
                                    notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                } else {
                                    onSave(event)
                                }
                            }
                        },
                        enabled = title.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        modifier = Modifier.testTag("save_event_button")
                    ) {
                        Icon(Icons.Default.Alarm, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("አስቀምጥ (Save)")
                    }
                }
            }
        }
    }

    // Material 3 TimePicker Dialog for exact custom Hour & Minute selection
    if (showTimePickerDialog) {
        val timePickerState = rememberTimePickerState(
            initialHour = hour,
            initialMinute = minute,
            is24Hour = false
        )
        AlertDialog(
            onDismissRequest = { showTimePickerDialog = false },
            title = {
                Column {
                    Text(
                        text = "ብጁ ሰዓት ይምረጡ (Pick Custom Time)",
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
                        hour = timePickerState.hour
                        minute = timePickerState.minute
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
