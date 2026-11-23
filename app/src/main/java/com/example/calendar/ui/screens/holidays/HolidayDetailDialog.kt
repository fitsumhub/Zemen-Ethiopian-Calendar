package com.example.calendar.ui.screens.holidays

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.HourglassBottom
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings

@Composable
fun HolidayDetailDialog(
    holiday: HolidayEngine.Holiday,
    currentLang: AppLanguage,
    todayEth: EthiopianDate,
    onDismiss: () -> Unit,
    onAddToEvents: (HolidayEngine.Holiday) -> Unit,
    onExportIcs: (HolidayEngine.Holiday) -> Unit,
    onShareCard: (HolidayEngine.Holiday) -> Unit,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null
) {
    val context = LocalContext.current
    val dow = EthiopianCalendarEngine.getDayOfWeek(holiday.ethiopianDate)
    val gDate = EthiopianCalendarEngine.toGregorian(holiday.ethiopianDate)
    val daysUntil = if (holiday.ethiopianDate >= todayEth) {
        EthiopianCalendarEngine.daysBetween(todayEth, holiday.ethiopianDate)
    } else {
        -EthiopianCalendarEngine.daysBetween(holiday.ethiopianDate, todayEth)
    }

    val typeColor = when (holiday.type) {
        HolidayEngine.HolidayType.NATIONAL_PUBLIC -> Color(0xFFEF4444)
        HolidayEngine.HolidayType.ORTHODOX_MAJOR, HolidayEngine.HolidayType.ORTHODOX_MOVABLE -> Color(0xFFF59E0B)
        HolidayEngine.HolidayType.ORTHODOX_FASTING -> Color(0xFF10B981)
        HolidayEngine.HolidayType.ISLAMIC -> Color(0xFF059669)
        HolidayEngine.HolidayType.CULTURAL_REGIONAL -> Color(0xFF8B5CF6)
        HolidayEngine.HolidayType.MONTHLY_SAINT -> Color(0xFF3B82F6)
    }

    val typeLabel = when (holiday.type) {
        HolidayEngine.HolidayType.NATIONAL_PUBLIC -> "National Public Holiday (የሕዝብ በዓል)"
        HolidayEngine.HolidayType.ORTHODOX_MAJOR -> "Orthodox Major Feast (የተዋሕዶ በዓል)"
        HolidayEngine.HolidayType.ORTHODOX_MOVABLE -> "Movable Orthodox Feast (ተንቀሳቃሽ በዓል)"
        HolidayEngine.HolidayType.ORTHODOX_FASTING -> "Orthodox Canonical Fast (የጾም ወቅት)"
        HolidayEngine.HolidayType.ISLAMIC -> "Islamic Observance (የእስልምና በዓል)"
        HolidayEngine.HolidayType.CULTURAL_REGIONAL -> "Cultural Heritage Festival (ባህላዊ በዓል)"
        HolidayEngine.HolidayType.MONTHLY_SAINT -> "Monthly Saint Commemoration (የወር ጽላት)"
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 6.dp,
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
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = typeColor.copy(alpha = 0.15f),
                        border = androidx.compose.foundation.BorderStroke(1.dp, typeColor.copy(alpha = 0.4f))
                    ) {
                        Text(
                            text = typeLabel,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = typeColor,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }

                    IconButton(onClick = onDismiss, modifier = Modifier.size(32.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Holiday Title in Amharic & English
                Text(
                    text = holiday.titleAmharic,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = holiday.titleEnglish,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )

                // Multilingual Names
                if (holiday.titleOromo.isNotEmpty() || holiday.titleTigrinya.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(6.dp))
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(10.dp)) {
                            if (holiday.titleOromo.isNotEmpty()) {
                                Text(
                                    text = "Afaan Oromoo: ${holiday.titleOromo}",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (holiday.titleTigrinya.isNotEmpty()) {
                                Text(
                                    text = "ትግርኛ: ${holiday.titleTigrinya}",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Dual Date Presentation Card
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = Color(0xFF0F1B2C),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF59E0B).copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "🇪🇹 Ethiopian Date (የኢትዮጵያ ቀን)",
                                fontSize = 11.5.sp,
                                color = Color(0xFFF59E0B),
                                fontWeight = FontWeight.Bold
                            )
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = if (daysUntil == 0L) Color(0xFF10B981) else if (daysUntil > 0) Color(0xFF3B82F6).copy(alpha = 0.25f) else Color.Gray.copy(alpha = 0.25f)
                            ) {
                                Text(
                                    text = when {
                                        daysUntil == 0L -> "🎉 TODAY (ዛሬ ነው)!"
                                        daysUntil > 0 -> "⏳ In $daysUntil days"
                                        else -> "✓ Passed (${-daysUntil}d ago)"
                                    },
                                    fontSize = 10.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (daysUntil == 0L) Color.White else if (daysUntil > 0) Color(0xFF93C5FD) else Color.LightGray,
                                    modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${LocaleStrings.getMonthName(holiday.ethiopianDate.month, currentLang)} ${holiday.ethiopianDate.day}፣ ${holiday.ethiopianDate.year} ዓ.ም",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "${LocaleStrings.getWeekdayLong(dow, currentLang)} (${LocaleStrings.getWeekdayLong(dow, AppLanguage.ENGLISH)})",
                            fontSize = 12.5.sp,
                            color = Color(0xFF94A3B8)
                        )

                        Spacer(modifier = Modifier.height(8.dp))
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(1.dp)
                                .background(Color(0xFF334155))
                        )
                        Spacer(modifier = Modifier.height(8.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "🌍 Gregorian Equivalent (ፈረንጅ)",
                                fontSize = 11.5.sp,
                                color = Color(0xFF38BDF8),
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = "${gDate.day}/${gDate.month}/${gDate.year} G.C.",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Description & Historical Traditions
                Text(
                    text = "Significance & Cultural Customs:",
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = holiday.description,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // Public holiday status notice
                if (holiday.isPublicHoliday) {
                    Spacer(modifier = Modifier.height(10.dp))
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = Color(0xFFEF4444).copy(alpha = 0.12f),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFEF4444).copy(alpha = 0.35f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("🏛️", fontSize = 16.sp)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Official National Public Holiday: Government offices, banks, and schools are closed.",
                                fontSize = 11.5.sp,
                                color = Color(0xFFB91C1C),
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Actions Grid
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    // Primary Action: Add to Events & Reminders
                    Button(
                        onClick = {
                            onAddToEvents(holiday)
                            onDismiss()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.NotificationsActive, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Add to My Events & Set Reminder", fontWeight = FontWeight.Bold)
                    }

                    // Share Greeting Card
                    Button(
                        onClick = {
                            onShareCard(holiday)
                            onDismiss()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF59E0B)),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, tint = Color.Black, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Generate & Share Holiday Card", fontWeight = FontWeight.Bold, color = Color.Black)
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Export .ICS
                        OutlinedButton(
                            onClick = { onExportIcs(holiday) },
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.Event, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Export .ICS", fontSize = 11.5.sp)
                        }

                        // Jump to Calendar
                        if (onNavigateToCalendar != null) {
                            OutlinedButton(
                                onClick = {
                                    onNavigateToCalendar(holiday.ethiopianDate)
                                    onDismiss()
                                },
                                shape = RoundedCornerShape(12.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("In Calendar", fontSize = 11.5.sp)
                            }
                        }
                    }
                }
            }
        }
    }
}
