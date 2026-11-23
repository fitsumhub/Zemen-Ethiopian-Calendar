package com.example.calendar.ui.screens.holidays

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BookmarkAdd
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.RestaurantMenu
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
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
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

@Composable
fun FastingGuideTab(
    viewModel: MainViewModel,
    selectedYear: Int,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    val todayFastingInfo = remember(todayEth) {
        HolidayEngine.getDetailedFastingInfo(todayEth)
    }

    val canonicalFasts = remember(selectedYear) {
        HolidayEngine.getCanonicalFastsForYear(selectedYear)
    }

    var expandedFastId by remember { mutableStateOf<String?>(null) }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 10.dp, bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // 1. TODAY'S FASTING STATUS HERO BANNER
        item {
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (todayFastingInfo.isFasting) Color(0xFF064E3B) else Color(0xFF0F1B2C)
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.2.dp,
                    if (todayFastingInfo.isFasting) Color(0xFF10B981) else Color(0xFF38BDF8).copy(alpha = 0.5f)
                ),
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
                            Text(
                                text = if (todayFastingInfo.isFasting) "🌿" else "☀️",
                                fontSize = 18.sp
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "TODAY'S FASTING STATUS (የዕለቱ የጾም ሁኔታ)",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (todayFastingInfo.isFasting) Color(0xFF6EE7B7) else Color(0xFF7DD3FC)
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (todayFastingInfo.isFasting) Color(0xFF10B981) else Color(0xFF0284C7)
                        ) {
                            Text(
                                text = if (todayFastingInfo.isFasting) "ጾም ነው (FASTING)" else "ጾም የለም (REGULAR)",
                                fontSize = 10.5.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color.White,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = todayFastingInfo.seasonNameAmharic,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White
                    )
                    Text(
                        text = todayFastingInfo.seasonNameEnglish,
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (todayFastingInfo.isFasting) Color(0xFFA7F3D0) else Color(0xFFBAE6FD)
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = Color.Black.copy(alpha = 0.25f),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(10.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.RestaurantMenu,
                                    contentDescription = null,
                                    tint = if (todayFastingInfo.isFasting) Color(0xFF34D399) else Color(0xFF38BDF8),
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "Dietary Rule: ${todayFastingInfo.fastingLevel}",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = todayFastingInfo.description,
                                fontSize = 11.5.sp,
                                color = Color(0xFFE2E8F0),
                                lineHeight = 16.sp
                            )
                        }
                    }
                }
            }
        }

        // 2. CANONICAL FASTS HEADER
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "The 7 Canonical Fasts of the Ethiopian Orthodox Church",
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "ሰባቱ አጽዋማት ለዓመተ $selectedYear ዓ.ም (Dates & Liturgical Guidelines)",
                        fontSize = 11.5.sp,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }

        // 3. THE 7 CANONICAL FASTS CARDS
        items(canonicalFasts, key = { it.id }) { fast ->
            val isExpanded = expandedFastId == fast.id
            val gStart = EthiopianCalendarEngine.toGregorian(fast.startDate)
            val gEnd = EthiopianCalendarEngine.toGregorian(fast.endDate)

            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    if (isExpanded) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expandedFastId = if (isExpanded) null else fast.id }
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = fast.nameAmharic,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            Text(
                                text = fast.nameEnglish,
                                fontSize = 12.5.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = Color(0xFF10B981).copy(alpha = 0.15f),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF10B981).copy(alpha = 0.4f))
                        ) {
                            Text(
                                text = "${fast.durationDays} Days (ቀናት)",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF059669),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }

                        IconButton(
                            onClick = { expandedFastId = if (isExpanded) null else fast.id },
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(
                                if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                                contentDescription = "Expand",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Date range pill
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "📅 ${LocaleStrings.getMonthName(fast.startDate.month, currentLang)} ${fast.startDate.day} ➔ ${LocaleStrings.getMonthName(fast.endDate.month, currentLang)} ${fast.endDate.day} ($selectedYear)",
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "${gStart.day}/${gStart.month} - ${gEnd.day}/${gEnd.month}",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }

                    // Expanded details
                    AnimatedVisibility(visible = isExpanded) {
                        Column(modifier = Modifier.padding(top = 12.dp)) {
                            // Significance
                            Text(
                                text = "Spiritual Significance (መንፈሳዊ ትርጉም):",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = fast.significance,
                                fontSize = 12.5.sp,
                                lineHeight = 17.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            // Dietary rules
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = Color(0xFF10B981).copy(alpha = 0.08f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF10B981).copy(alpha = 0.25f)),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("🥗", fontSize = 15.sp)
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = fast.dietaryRules,
                                        fontSize = 11.5.sp,
                                        color = Color(0xFF065F46)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            // Biblical Foundation
                            Text(
                                text = "📖 Biblical Script: ${fast.biblicalFoundation}",
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.secondary
                            )

                            Spacer(modifier = Modifier.height(12.dp))

                            // Add Fast to My Calendar action
                            Button(
                                onClick = {
                                    val eventStart = EventEntity(
                                        title = "Start of ${fast.nameAmharic} (${fast.nameEnglish})",
                                        description = "${fast.significance}\nRules: ${fast.dietaryRules}",
                                        category = "RELIGIOUS",
                                        ethiopianYear = fast.startDate.year,
                                        ethiopianMonth = fast.startDate.month,
                                        ethiopianDay = fast.startDate.day,
                                        gregorianYear = gStart.year,
                                        gregorianMonth = gStart.month,
                                        gregorianDay = gStart.day,
                                        hour = 7,
                                        minute = 0,
                                        isAllDay = true,
                                        reminderMinutesBefore = 1440,
                                        colorHex = "#10B981"
                                    )
                                    viewModel.saveEvent(eventStart)
                                    Toast.makeText(context, "Added start of ${fast.nameEnglish} to My Events!", Toast.LENGTH_SHORT).show()
                                },
                                shape = RoundedCornerShape(10.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Icon(Icons.Default.NotificationsActive, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Add Fast Start Reminder to Calendar", fontSize = 11.5.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }

        // 4. GENERAL FASTING RULES & SPIRITUAL GUIDE
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = "Orthodox Fasting Fundamentals (የጾም ሥርዓት)",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "• Abstinence (ምግብ መከልከል): Complete abstinence from meat, poultry, dairy, eggs, and animal fats.\n" +
                                "• Fasting Hours (የሰዓት ጾም): Abstaining from all food and liquid from midnight until the 9th hour (3:00 PM), or until the Holy Mass concludes.\n" +
                                "• Fifty Days of Joy (የሃምሳ ፌስሐ): Between Easter and Pentecost, fasting is strictly prohibited in honor of the Resurrection.\n" +
                                "• Compassion (ምጽዋት): Fasting must always be accompanied by prayer, charity, forgiveness, and reconciling with others.",
                        fontSize = 12.sp,
                        lineHeight = 17.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}
