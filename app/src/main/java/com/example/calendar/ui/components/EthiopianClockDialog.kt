package com.example.calendar.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Brightness5
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.GeezNumeral
import com.example.calendar.engine.EthiopianTimeConverter
import kotlinx.coroutines.delay
import java.util.Calendar
import java.util.Locale
import kotlin.math.cos
import kotlin.math.sin

/**
 * Rich, authentic Ethiopian 12-Hour Clock visualizer modal.
 * Shows analog 12-hour clock face (with Geez numerals), day/night solar indicator,
 * and live conversion with Western/Gregorian time.
 */
@Composable
fun EthiopianClockDialog(
    onDismissRequest: () -> Unit
) {
    var isLiveClock by remember { mutableStateOf(true) }
    var useGeezNumerals by remember { mutableStateOf(true) }
    var interactiveHour24 by remember { mutableFloatStateOf(12f) }

    // Live clock ticker
    var currentTimeMillis by remember { mutableStateOf(System.currentTimeMillis()) }
    LaunchedEffect(isLiveClock) {
        while (isLiveClock) {
            delay(1000)
            currentTimeMillis = System.currentTimeMillis()
        }
    }

    val cal = remember(currentTimeMillis) { Calendar.getInstance() }
    val currentGHour = if (isLiveClock) cal.get(Calendar.HOUR_OF_DAY) else interactiveHour24.toInt()
    val currentGMin = if (isLiveClock) cal.get(Calendar.MINUTE) else 0
    val currentGSec = if (isLiveClock) cal.get(Calendar.SECOND) else 0

    val ethTime = remember(currentGHour, currentGMin) {
        EthiopianTimeConverter.gregorianToEthiopian(currentGHour, currentGMin)
    }

    val geezNumeralsList = listOf("፩", "፪", "፫", "፬", "፭", "፮", "፯", "፰", "፱", "፲", "፲፩", "፲፪")

    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = {
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
                            .background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.AccessTime,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = "የኢትዮጵያ ባህላዊ ሰዓት",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Traditional 12-Hour Ethiopian Time",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                IconButton(onClick = onDismissRequest) {
                    Icon(Icons.Default.Close, contentDescription = "Close")
                }
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Toggles Row: Live vs Interactive, Geez vs Arabic numerals
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    FilterChip(
                        selected = isLiveClock,
                        onClick = { isLiveClock = !isLiveClock },
                        label = {
                            Text(if (isLiveClock) "🔴 የቀጥታ ሰዓት (Live)" else "የሙከራ ሰዓት (Slider)", fontSize = 11.sp)
                        },
                        colors = FilterChipDefaults.filterChipColors()
                    )

                    FilterChip(
                        selected = useGeezNumerals,
                        onClick = { useGeezNumerals = !useGeezNumerals },
                        label = {
                            Text(if (useGeezNumerals) "ግዕዝ (፩, ፪)" else "አረብኛ (1, 2)", fontSize = 11.sp)
                        },
                        colors = FilterChipDefaults.filterChipColors()
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Analog Clock Canvas
                Box(
                    modifier = Modifier
                        .size(210.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                        .border(2.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.6f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    val primaryColor = MaterialTheme.colorScheme.primary
                    val onSurfaceColor = MaterialTheme.colorScheme.onSurface
                    val accentColor = if (ethTime.isDaytime) Color(0xFFF59E0B) else Color(0xFF8B5CF6)

                    Canvas(modifier = Modifier.size(190.dp)) {
                        val center = Offset(size.width / 2, size.height / 2)
                        val radius = size.width / 2

                        // Outer rim circle
                        drawCircle(
                            color = primaryColor.copy(alpha = 0.15f),
                            radius = radius,
                            center = center,
                            style = Stroke(width = 2.dp.toPx())
                        )

                        // Draw 12 hour tick marks & numbers
                        for (i in 1..12) {
                            // In Ethiopian clock: 12 is at the top (6:00 AM/PM)
                            val angleRad = Math.toRadians((i * 30 - 90).toDouble())
                            val tickInner = Offset(
                                (center.x + (radius - 12.dp.toPx()) * cos(angleRad)).toFloat(),
                                (center.y + (radius - 12.dp.toPx()) * sin(angleRad)).toFloat()
                            )
                            val tickOuter = Offset(
                                (center.x + (radius - 4.dp.toPx()) * cos(angleRad)).toFloat(),
                                (center.y + (radius - 4.dp.toPx()) * sin(angleRad)).toFloat()
                            )

                            drawLine(
                                color = if (i % 3 == 0) primaryColor else onSurfaceColor.copy(alpha = 0.4f),
                                start = tickInner,
                                end = tickOuter,
                                strokeWidth = if (i % 3 == 0) 3.dp.toPx() else 1.5.dp.toPx(),
                                cap = StrokeCap.Round
                            )

                            // Draw numeral text
                            val label = if (useGeezNumerals) geezNumeralsList[i - 1] else i.toString()
                            val textRadius = radius - 26.dp.toPx()
                            val textX = (center.x + textRadius * cos(angleRad)).toFloat()
                            val textY = (center.y + textRadius * sin(angleRad)).toFloat() + 4.dp.toPx()

                            drawContext.canvas.nativeCanvas.apply {
                                val paint = android.graphics.Paint().apply {
                                    color = if (i == ethTime.hour) android.graphics.Color.rgb(245, 158, 11) else android.graphics.Color.WHITE
                                    textSize = if (useGeezNumerals) 28f else 30f
                                    textAlign = android.graphics.Paint.Align.CENTER
                                    isFakeBoldText = i == ethTime.hour || i % 3 == 0
                                }
                                drawText(label, textX, textY, paint)
                            }
                        }

                        // Hour hand
                        val ethHourFraction = ethTime.hour + (ethTime.minute / 60f)
                        val hourAngleRad = Math.toRadians((ethHourFraction * 30 - 90).toDouble())
                        val hourHandLength = radius * 0.52f
                        val hourEnd = Offset(
                            (center.x + hourHandLength * cos(hourAngleRad)).toFloat(),
                            (center.y + hourHandLength * sin(hourAngleRad)).toFloat()
                        )
                        drawLine(
                            color = primaryColor,
                            start = center,
                            end = hourEnd,
                            strokeWidth = 4.5.dp.toPx(),
                            cap = StrokeCap.Round
                        )

                        // Minute hand
                        val minuteAngleRad = Math.toRadians((ethTime.minute * 6 - 90).toDouble())
                        val minuteHandLength = radius * 0.72f
                        val minuteEnd = Offset(
                            (center.x + minuteHandLength * cos(minuteAngleRad)).toFloat(),
                            (center.y + minuteHandLength * sin(minuteAngleRad)).toFloat()
                        )
                        drawLine(
                            color = accentColor,
                            start = center,
                            end = minuteEnd,
                            strokeWidth = 2.5.dp.toPx(),
                            cap = StrokeCap.Round
                        )

                        // Center hub pin
                        drawCircle(color = primaryColor, radius = 5.dp.toPx(), center = center)
                        drawCircle(color = Color.White, radius = 2.dp.toPx(), center = center)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Time Display & Phase Pill
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(14.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                if (ethTime.isDaytime) Icons.Default.Brightness5 else Icons.Default.DarkMode,
                                contentDescription = null,
                                tint = if (ethTime.isDaytime) Color(0xFFF59E0B) else Color(0xFF8B5CF6),
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "${ethTime.period.amharic} ${if (useGeezNumerals) GeezNumeral.toGeez(ethTime.hour) else ethTime.hour.toString()}:${String.format(Locale.US, "%02d", ethTime.minute)}",
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Black,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (ethTime.isDaytime) Color(0xFFF59E0B).copy(alpha = 0.2f) else Color(0xFF8B5CF6).copy(alpha = 0.2f)
                            ) {
                                Text(
                                    text = if (ethTime.isDaytime) "ቀን (Day)" else "ሌሊት (Night)",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (ethTime.isDaytime) Color(0xFFF59E0B) else Color(0xFF8B5CF6),
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(6.dp))

                        Text(
                            text = "ግሪጎሪያን አቻ (Gregorian Equivalent): ${String.format(Locale.US, "%02d:%02d", currentGHour, currentGMin)} (${if (currentGHour >= 12) "PM" else "AM"})",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Interactive Hour Slider if not live clock
                if (!isLiveClock) {
                    Spacer(modifier = Modifier.height(10.dp))
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            text = "የሰዓት መቀየሪያ መሞከሪያ (Adjust Gregorian Hour: ${currentGHour}:00):",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Slider(
                            value = interactiveHour24,
                            onValueChange = { interactiveHour24 = it },
                            valueRange = 0f..23f,
                            steps = 22,
                            colors = SliderDefaults.colors(
                                thumbColor = MaterialTheme.colorScheme.primary,
                                activeTrackColor = MaterialTheme.colorScheme.primary
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Educational Explainer: How Ethiopian Time Works
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.Info,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "የኢትዮጵያ ሰዓት አቆጣጠር መመሪያ",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "በኢትዮጵያ አቆጣጠር የ12 ሰዓት ዑደት የሚጀምረው በፀሐይ መውጣት (ጥዋት 12:00 = 6:00 AM) ሲሆን፣ የሌሊት ዑደት በፀሐይ መጥለቅ (ምሽት 12:00 = 6:00 PM) ይጀምራል። ስለዚህ ጥዋት 1:00 ማለት የምዕራቡ 7:00 AM ነው።",
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 16.sp
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = onDismissRequest,
                modifier = Modifier.testTag("ethiopian_clock_close_button")
            ) {
                Text("ተረዳሁ (Close)", fontWeight = FontWeight.Bold)
            }
        }
    )
}
