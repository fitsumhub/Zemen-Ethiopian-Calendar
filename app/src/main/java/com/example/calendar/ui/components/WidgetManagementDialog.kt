package com.example.calendar.ui.components

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.Toast
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.GeezNumberFormatter
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.widget.EthioCalCompactWidgetProvider
import com.example.calendar.widget.EthioCalWidgetProvider
import java.util.Calendar
import java.util.Locale

/**
 * Interactive Widget Management & Live Preview Dialog:
 * - Live interactive visual preview of both Full (3x2) and Compact (2x1) widgets
 * - 1-Tap native "Pin to Home Screen" via AppWidgetManager (Android 8.0+)
 * - Instant widget broadcast refresh button
 * - Step-by-step guidance for manual widget setup on all launchers
 */
@Composable
fun WidgetManagementDialog(
    currentLanguage: AppLanguage,
    onDismissRequest: () -> Unit
) {
    val context = LocalContext.current
    var selectedWidgetIndex by remember { mutableIntStateOf(0) } // 0: Full, 1: Compact

    val ethDate = remember { EthiopianCalendarEngine.todayEthiopian() }
    val gregDate = remember { EthiopianCalendarEngine.todayGregorian() }
    val dow = remember(ethDate) { EthiopianCalendarEngine.getDayOfWeek(ethDate) }
    val monthName = remember(ethDate, currentLanguage) { LocaleStrings.getMonthName(ethDate.month, currentLanguage) }
    val weekdayName = remember(dow, currentLanguage) { LocaleStrings.getWeekdayLong(dow, currentLanguage) }
    val geezDay = remember(ethDate.day) { GeezNumberFormatter.toGeez(ethDate.day) }

    val isGeezScript = currentLanguage == AppLanguage.AMHARIC || currentLanguage == AppLanguage.TIGRINYA
    val eraSuffix = if (isGeezScript) "ዓ.ም" else "E.C."
    val gregMonthShort = remember(gregDate.month) { EthioCalWidgetProvider.gregorianMonthShort(gregDate.month) }
    val gregDowShort = remember(dow) { LocaleStrings.getWeekdayShort(dow, AppLanguage.ENGLISH) }

    val nowCal = Calendar.getInstance()
    val gHour = nowCal.get(Calendar.HOUR_OF_DAY)
    val gMin = nowCal.get(Calendar.MINUTE)
    val ethTime = remember(gHour, gMin) { EthiopianTimeConverter.gregorianToEthiopian(gHour, gMin) }
    val fastingStatus = remember(ethDate) { HolidayEngine.isFastingDay(ethDate) }
    val dailySaint = remember(ethDate.day) { HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == ethDate.day } }

    Dialog(onDismissRequest = onDismissRequest) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 8.dp,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFF59E0B).copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.Widgets,
                                contentDescription = null,
                                tint = Color(0xFFF59E0B),
                                modifier = Modifier.size(20.dp)
                            )
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "Dual-Date Home Widgets",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = "Ethiopian & Gregorian Sync",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    IconButton(onClick = onDismissRequest) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Widget Selector Chips
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    FilterChip(
                        selected = selectedWidgetIndex == 0,
                        onClick = { selectedWidgetIndex = 0 },
                        label = { Text("Full Dual (3x2)", fontSize = 12.sp) },
                        modifier = Modifier.weight(1f)
                    )
                    FilterChip(
                        selected = selectedWidgetIndex == 1,
                        onClick = { selectedWidgetIndex = 1 },
                        label = { Text("Compact Dual (2x1)", fontSize = 12.sp) },
                        modifier = Modifier.weight(1f)
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // LIVE WIDGET PREVIEW CARD
                Text(
                    text = "Live Preview:",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(6.dp))

                if (selectedWidgetIndex == 0) {
                    // Full Widget (3x2) Dual-Date Preview
                    Card(
                        shape = RoundedCornerShape(20.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
                        border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFF2A3A4D)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            // Top row
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "🇪🇹 EthioCal Pro",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFFFBBF24)
                                )
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = weekdayName,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFFE2E8F0)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = Color(0xFF1E293B)
                                    ) {
                                        Text(
                                            text = if (isGeezScript) "+ አዲስ" else "+ Add",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF10B981),
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp)
                                    .height(1.dp)
                                    .background(Color(0xFF243447))
                            )

                            // Middle row: Ethiopian Date + Clock on left, Gregorian Companion Badge on right
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier.padding(end = 10.dp)
                                ) {
                                    Text(
                                        text = ethDate.day.toString(),
                                        fontSize = 32.sp,
                                        fontWeight = FontWeight.Black,
                                        color = Color(0xFFFDE047)
                                    )
                                    Text(
                                        text = geezDay,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFFF59E0B)
                                    )
                                }

                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = "$monthName ${ethDate.year} $eraSuffix",
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        maxLines = 1
                                    )
                                    Text(
                                        text = if (isGeezScript) {
                                            "⏰ ${ethTime.hour}:${String.format(Locale.US, "%02d", ethTime.minute)} ${if (ethTime.isDaytime) "ቀን" else "ሌሊት"}"
                                        } else {
                                            "⏰ ${ethTime.hour}:${String.format(Locale.US, "%02d", ethTime.minute)} ${if (ethTime.isDaytime) "Day" else "Night"}"
                                        },
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFFFBBF24)
                                    )
                                }

                                Spacer(modifier = Modifier.width(6.dp))

                                // Gregorian Companion Badge
                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = Color(0xFF162235),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF38BDF8))
                                ) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                                    ) {
                                        Text(
                                            text = "🌍 G.C.",
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF38BDF8)
                                        )
                                        Text(
                                            text = "$gregMonthShort ${gregDate.day}",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color.White
                                        )
                                        Text(
                                            text = "$gregDowShort, ${gregDate.year}",
                                            fontSize = 10.sp,
                                            color = Color(0xFF94A3B8)
                                        )
                                    }
                                }
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp)
                                    .height(1.dp)
                                    .background(Color(0xFF243447))
                            )

                            // Bottom row
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = if (fastingStatus.isFasting) Color(0xFF133827) else Color(0xFF1E293B),
                                    border = androidx.compose.foundation.BorderStroke(
                                        1.dp,
                                        if (fastingStatus.isFasting) Color(0xFF10B981) else Color(0xFF475569)
                                    )
                                ) {
                                    Text(
                                        text = if (isGeezScript) {
                                            if (fastingStatus.isFasting) "🌿 ጾም" else "🥩 ፍስክ"
                                        } else {
                                            if (fastingStatus.isFasting) "🌿 Fasting" else "🍽️ Non-Fast"
                                        },
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (fastingStatus.isFasting) Color(0xFF34D399) else Color(0xFFCBD5E1),
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }

                                Text(
                                    text = if (dailySaint != null) {
                                        val sName = if (isGeezScript) dailySaint.nameAmharic else dailySaint.nameEnglish
                                        if (isGeezScript) "✨ ጽላት: $sName" else "✨ Saint: $sName"
                                    } else {
                                        "🇪🇹 EthioCal Pro"
                                    },
                                    fontSize = 11.sp,
                                    color = Color(0xFFCBD5E1),
                                    maxLines = 1
                                )
                            }
                        }
                    }
                } else {
                    // Compact Widget (2x1) Dual-Date Preview
                    Card(
                        shape = RoundedCornerShape(20.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
                        border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFF2A3A4D)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(14.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = "🇪🇹 $monthName",
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFFFBBF24)
                                )
                                Text(
                                    text = weekdayName,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFFE2E8F0)
                                )
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Text(
                                    text = ethDate.day.toString(),
                                    fontSize = 32.sp,
                                    fontWeight = FontWeight.Black,
                                    color = Color(0xFFFDE047)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Column {
                                    Text(
                                        text = geezDay,
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFFF59E0B)
                                    )
                                    Text(
                                        text = "${ethDate.year} $eraSuffix",
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFFCBD5E1)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "🌍 $gregMonthShort ${gregDate.day}, ${gregDate.year}",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF38BDF8)
                                )
                                Text(
                                    text = if (isGeezScript) {
                                        if (fastingStatus.isFasting) "🌿 ጾም" else "🥩 ፍስክ"
                                    } else {
                                        if (fastingStatus.isFasting) "🌿 Fast" else "🍽️ Reg"
                                    },
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF34D399)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Actions: Pin to Home Screen & Force Refresh
                val appWidgetManager = remember { AppWidgetManager.getInstance(context) }
                val isPinSupported = remember {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        appWidgetManager.isRequestPinAppWidgetSupported
                    } else {
                        false
                    }
                }

                if (isPinSupported) {
                    Button(
                        onClick = {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val providerClass = if (selectedWidgetIndex == 0) {
                                    EthioCalWidgetProvider::class.java
                                } else {
                                    EthioCalCompactWidgetProvider::class.java
                                }
                                val myProvider = ComponentName(context, providerClass)
                                val success = appWidgetManager.requestPinAppWidget(myProvider, null, null)
                                if (success) {
                                    Toast.makeText(context, "ዊጄት ወደ መነሻ ስክሪን እየተጨመረ ነው...", Toast.LENGTH_SHORT).show()
                                } else {
                                    Toast.makeText(context, "የመነሻ ስክሪን ፈቃድ አልተገኘም", Toast.LENGTH_SHORT).show()
                                }
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.AddCircle, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("➕ ወደ መነሻ ስክሪን አክል (Pin Widget)", fontWeight = FontWeight.Bold)
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                }

                // Force refresh button
                OutlinedButton(
                    onClick = {
                        EthioCalWidgetProvider.updateAllWidgets(context)
                        Toast.makeText(context, "🔄 ዊጄቱ ታድሷል (Widgets Refreshed)", Toast.LENGTH_SHORT).show()
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("ዊጄቱን አድስ (Sync & Refresh)", fontSize = 12.sp)
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Manual Setup Steps Accordion / Card
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text(
                            text = "💡 በእጅ ለመጨመር (Manual Setup):",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "1. ወደ ስልክዎ መነሻ ስክሪን ይሂዱና ባዶ ቦታ ላይ ተጭነው ይቆዩ (Long Press)\n" +
                                    "2. 'Widgets' የሚለውን ይምረጡ\n" +
                                    "3. 'EthioCal Pro' ፈልገው ወደ ስክሪኑ ይጎትቱ።",
                            fontSize = 10.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 14.sp
                        )
                    }
                }
            }
        }
    }
}
