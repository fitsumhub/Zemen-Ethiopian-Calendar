package com.example.calendar.ui.screens.events

import android.Manifest
import android.content.Intent
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
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
import androidx.compose.material.icons.automirrored.filled.EventNote
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.FileDownload
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Search
import androidx.core.graphics.toColorInt
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.data.EventEntity
import com.example.calendar.data.IcsExporter
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

@Composable
fun EventsScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    val filteredEvents by viewModel.filteredEvents.collectAsState()
    val allEvents by viewModel.allEvents.collectAsState()
    val userSettings by viewModel.userSettings.collectAsState()
    val searchQuery by viewModel.eventSearchQuery.collectAsState()
    val categoryFilter by viewModel.eventCategoryFilter.collectAsState()

    var showAddEventDialog by remember { mutableStateOf(false) }
    var eventToEdit by remember { mutableStateOf<EventEntity?>(null) }

    Box(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp)
        ) {
            // Search field
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text(LocaleStrings.get("search_events", currentLang)) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Category filter chips + ICS export
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                LazyRow(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    listOf(
                        "ALL" to "ሁሉም (All)",
                        "TASK" to "ተግባር (Tasks)",
                        "MEETING" to "ስብሰባ (Meetings)",
                        "BIRTHDAY" to "ልደት (Birthdays)",
                        "EXAM" to "ፈተና (Exams)",
                        "ANNIVERSARY" to "መታሰቢያ (Anniversaries)",
                        "RELIGIOUS" to "ሃይማኖት (Religious)"
                    ).forEach { (cat, label) ->
                        item {
                            FilterChip(
                                selected = categoryFilter == cat,
                                onClick = { viewModel.setCategoryFilter(cat) },
                                label = { Text(label, fontSize = 11.sp) }
                            )
                        }
                    }
                }

                val calendarPermissionLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.RequestMultiplePermissions()
                ) { perms ->
                    val allGranted = perms.values.all { it }
                    if (allGranted) {
                        viewModel.syncEventsToDeviceCalendar(context) { msg ->
                            Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                        }
                    } else {
                        Toast.makeText(context, "የካላንደር ፈቃድ አልተሰጠም (Permission denied)", Toast.LENGTH_SHORT).show()
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = {
                            if (com.example.calendar.data.AndroidCalendarSyncManager.hasCalendarPermissions(context)) {
                                viewModel.syncEventsToDeviceCalendar(context) { msg ->
                                    Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                                }
                            } else {
                                calendarPermissionLauncher.launch(
                                    arrayOf(
                                        Manifest.permission.READ_CALENDAR,
                                        Manifest.permission.WRITE_CALENDAR
                                    )
                                )
                            }
                        },
                        modifier = Modifier.testTag("sync_device_cal_btn")
                    ) {
                        Icon(
                            Icons.Default.CalendarToday,
                            contentDescription = "Sync to Android Calendar",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    IconButton(
                        onClick = {
                            val icsData = IcsExporter.exportToIcs(allEvents)
                            val sendIntent = Intent().apply {
                                action = Intent.ACTION_SEND
                                putExtra(Intent.EXTRA_TEXT, icsData)
                                putExtra(Intent.EXTRA_TITLE, "ethiopian_calendar_events.ics")
                                type = "text/calendar"
                            }
                            context.startActivity(Intent.createChooser(sendIntent, "Export Calendar ICS"))
                        },
                        modifier = Modifier.testTag("export_ics_button")
                    ) {
                        Icon(
                            Icons.Default.FileDownload,
                            contentDescription = "Export ICS",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            if (!userSettings.notificationsEnabled) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.5f),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 10.dp)
                        .clickable { viewModel.setNotificationsEnabled(true) }
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "🔕 ማሳሰቢያዎች ጠፍተዋል (Notifications paused) — ለማብራት ይንኩ",
                            fontSize = 11.5.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }

            // Events List
            if (filteredEvents.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.AutoMirrored.Filled.EventNote,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.outline,
                            modifier = Modifier.size(56.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "ምንም የተመዘገበ ማስታወሻ የለም (No events found)",
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedButton(onClick = { showAddEventDialog = true }) {
                            Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("አዲስ ማስታወሻ መዝግብ")
                        }
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 100.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filteredEvents, key = { it.id }) { event ->
                        val monthName = LocaleStrings.getMonthName(event.ethiopianMonth, currentLang)
                        val eventColor = try {
                            Color(event.colorHex.toColorInt())
                        } catch (_: Exception) {
                            MaterialTheme.colorScheme.primary
                        }

                        Card(
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            border = androidx.compose.foundation.BorderStroke(
                                1.dp,
                                MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    eventToEdit = event
                                    showAddEventDialog = true
                                }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Color Tag & Complete check
                                IconButton(onClick = { viewModel.toggleEventCompletion(event) }) {
                                    Icon(
                                        imageVector = if (event.isCompleted) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                                        contentDescription = "Toggle completion",
                                        tint = if (event.isCompleted) Color(0xFF10B981) else eventColor
                                    )
                                }

                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = event.title,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (event.isCompleted) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
                                        style = if (event.isCompleted) androidx.compose.ui.text.TextStyle(
                                            textDecoration = androidx.compose.ui.text.style.TextDecoration.LineThrough
                                        ) else androidx.compose.ui.text.TextStyle()
                                    )

                                    if (event.description.isNotEmpty()) {
                                        Text(
                                            text = event.description,
                                            fontSize = 12.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }

                                    Spacer(modifier = Modifier.height(4.dp))

                                    Row(
                                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Surface(
                                            shape = RoundedCornerShape(6.dp),
                                            color = MaterialTheme.colorScheme.surfaceVariant
                                        ) {
                                            Text(
                                                text = "📅 $monthName ${event.ethiopianDay}፣ ${event.ethiopianYear}",
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Medium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }

                                        Text(
                                            text = if (event.isAllDay) "ሙሉ ቀን" else com.example.calendar.notification.NotificationScheduler.formatClock12h(event.hour, event.minute),
                                            fontSize = 11.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )

                                        if (event.reminderMinutesBefore >= 0) {
                                            val alertClock = com.example.calendar.notification.NotificationScheduler.formatClock12h(event.hour, event.minute)
                                            val reminderLabel = com.example.calendar.notification.NotificationScheduler.formatReminderOffsetShort(event.reminderMinutesBefore)
                                            Surface(
                                                shape = RoundedCornerShape(6.dp),
                                                color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.7f)
                                            ) {
                                                Text(
                                                    text = if (event.reminderMinutesBefore == 0) "🔔 $alertClock" else "🔔 $alertClock (-$reminderLabel)",
                                                    fontSize = 10.sp,
                                                    fontWeight = FontWeight.SemiBold,
                                                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                                                    modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                                )
                                            }
                                        }

                                        if (event.recurrence != "NONE") {
                                            val recLabel = when (event.recurrence) {
                                                "DAILY" -> "በየቀኑ"
                                                "WEEKLY" -> "በየሳምንቱ"
                                                "MONTHLY_ETHIOPIAN", "MONTHLY_GREGORIAN" -> "በየወሩ"
                                                "YEARLY_ETHIOPIAN", "YEARLY_GREGORIAN" -> "በየዓመቱ"
                                                else -> event.recurrence
                                            }
                                            Surface(
                                                shape = RoundedCornerShape(6.dp),
                                                color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.7f)
                                            ) {
                                                Text(
                                                    text = "🔁 $recLabel",
                                                    fontSize = 10.sp,
                                                    fontWeight = FontWeight.SemiBold,
                                                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                                                    modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                                )
                                            }
                                        }
                                    }
                                }

                                Row {
                                    IconButton(
                                        onClick = {
                                            eventToEdit = event
                                            showAddEventDialog = true
                                        }
                                    ) {
                                        Icon(
                                            Icons.Default.Edit,
                                            contentDescription = "Edit Event",
                                            tint = MaterialTheme.colorScheme.primary,
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }

                                    IconButton(
                                        onClick = { viewModel.deleteEvent(event) }
                                    ) {
                                        Icon(
                                            Icons.Default.Delete,
                                            contentDescription = "Delete Event",
                                            tint = MaterialTheme.colorScheme.error,
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Floating Action Button
        FloatingActionButton(
            onClick = {
                eventToEdit = null
                showAddEventDialog = true
            },
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(bottom = 80.dp, end = 20.dp)
                .testTag("fab_add_event")
        ) {
            Icon(Icons.Default.Add, contentDescription = "Add Event")
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
}
