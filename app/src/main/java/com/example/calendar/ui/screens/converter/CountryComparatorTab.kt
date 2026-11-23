package com.example.calendar.ui.screens.converter

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.CurrencyExchange
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.EthiopianSeason
import com.example.calendar.core.EthiopianTimeConverter
import com.example.calendar.engine.WorldCountryEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.ui.MainViewModel
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import kotlin.math.abs

/**
 * Executive Country & World Comparator Tab.
 * Side-by-side live dual clock & business-hours comparison between Ethiopia
 * and selected European/World destinations with theme-aware surfaces.
 */
@Composable
fun CountryComparatorTab(
    viewModel: MainViewModel,
    currentLang: AppLanguage,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA
    var selectedCountryId by remember { mutableStateOf("de") }

    val profile = remember(selectedCountryId) {
        WorldCountryEngine.COUNTRY_PROFILES.firstOrNull { it.id == selectedCountryId }
            ?: WorldCountryEngine.COUNTRY_PROFILES[0]
    }

    val todayEth = viewModel.todayEthiopian
    val ethSeason = EthiopianSeason.fromEthiopianDate(todayEth)

    // Current time in Addis Ababa (UTC+3)
    val addisTz = TimeZone.getTimeZone("Africa/Addis_Ababa")
    val addisCal = Calendar.getInstance(addisTz)
    val addisHour = addisCal.get(Calendar.HOUR_OF_DAY)
    val addisMinute = addisCal.get(Calendar.MINUTE)
    val ethTime = EthiopianTimeConverter.gregorianToEthiopian(addisHour, addisMinute)

    // Target Country Time
    val targetTz = TimeZone.getTimeZone(profile.timeZoneId)
    val targetCal = Calendar.getInstance(targetTz)
    val targetHour24 = targetCal.get(Calendar.HOUR_OF_DAY)
    val targetMinute = targetCal.get(Calendar.MINUTE)
    val targetHour12 = when (val h = targetHour24 % 12) {
        0 -> 12
        else -> h
    }
    val targetIsPm = targetHour24 >= 12
    val targetFormatted12 = String.format(Locale.US, "%d:%02d %s", targetHour12, targetMinute, if (targetIsPm) "PM" else "AM")
    val targetFormatted24 = String.format(Locale.US, "%02d:%02d", targetHour24, targetMinute)

    val targetDay = targetCal.get(Calendar.DAY_OF_MONTH)
    val targetMonth = targetCal.get(Calendar.MONTH) + 1
    val targetYear = targetCal.get(Calendar.YEAR)
    val targetDateStr = String.format(Locale.US, "%02d.%02d.%04d", targetDay, targetMonth, targetYear)

    // Offset difference from Addis Ababa
    val addisOffsetHours = addisTz.getOffset(System.currentTimeMillis()) / 3600000.0
    val targetOffsetHours = targetTz.getOffset(System.currentTimeMillis()) / 3600000.0
    val hourDiff = targetOffsetHours - addisOffsetHours
    val timeDiffText = when {
        abs(hourDiff) < 0.01 -> "Same time zone (0 hrs)"
        hourDiff > 0 -> {
            val formatted = if (hourDiff % 1.0 == 0.0) "${hourDiff.toInt()}" else String.format(Locale.US, "%.1f", hourDiff)
            "+$formatted hrs ahead"
        }
        else -> {
            val formatted = if (hourDiff % 1.0 == 0.0) "${hourDiff.toInt()}" else String.format(Locale.US, "%.1f", hourDiff)
            "$formatted hrs behind"
        }
    }

    fun statusBadgeForHour(hour24: Int): Pair<String, Boolean> {
        return when (hour24) {
            in 8..17 -> "☀️ Business Hours" to true
            in 6..7 -> "🌅 Morning" to false
            in 18..21 -> "🌆 Evening" to false
            else -> "🌙 Nighttime" to false
        }
    }

    val (ethStatusLabel, ethInBusiness) = statusBadgeForHour(addisHour)
    val (targetStatusLabel, targetInBusiness) = statusBadgeForHour(targetHour24)
    val bothOpenNow = ethInBusiness && targetInBusiness

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 84.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. COUNTRY SELECTOR STRIP
        item {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = if (isGeezScript) "ከኢትዮጵያ ጋር የሚነጻጸር ሀገር ይምረጡ" else "Compare Ethiopia with:",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    WorldCountryEngine.COUNTRY_PROFILES.forEach { cp ->
                        val isSelected = cp.id == selectedCountryId
                        FilterChip(
                            selected = isSelected,
                            onClick = { selectedCountryId = cp.id },
                            label = {
                                Text(
                                    text = "${cp.flag} ${cp.capitalEn}",
                                    fontSize = 11.5.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                )
                            },
                            modifier = Modifier.testTag("country_chip_${cp.id}")
                        )
                    }
                }
            }
        }

        // 2. LIVE COUNTRY COMPARATOR HERO CARD (Theme-aware Gradient Surface)
        item {
            ElevatedCard(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
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
                        .padding(16.dp)
                ) {
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "LIVE COUNTRY COMPARATOR",
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.primary,
                                letterSpacing = 0.8.sp
                            )
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = MaterialTheme.colorScheme.primaryContainer
                            ) {
                                Text(
                                    text = timeDiffText,
                                    fontSize = 10.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                                    modifier = Modifier.padding(horizontal = 9.dp, vertical = 3.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Dual side-by-side live cards
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            // Ethiopia Card
                            Surface(
                                shape = RoundedCornerShape(18.dp),
                                color = MaterialTheme.colorScheme.surface,
                                border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.25f)),
                                modifier = Modifier.weight(1f)
                            ) {
                                Column(modifier = Modifier.padding(13.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text("🇪🇹", fontSize = 20.sp)
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Column {
                                            Text("Ethiopia", fontWeight = FontWeight.Bold, fontSize = 13.5.sp, color = MaterialTheme.colorScheme.onSurface)
                                            Text("Addis Ababa", fontSize = 10.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(10.dp))

                                    Text(
                                        text = "${ethTime.period.english} ${ethTime.hour}:${String.format(Locale.US, "%02d", ethTime.minute)}",
                                        fontSize = 18.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = "24h: ${String.format(Locale.US, "%02d:%02d", addisHour, addisMinute)} EAT",
                                        fontSize = 10.5.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )

                                    Spacer(modifier = Modifier.height(6.dp))

                                    Text(
                                        text = "${todayEth.day}/${todayEth.month}/${todayEth.year} E.C.",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.secondary
                                    )

                                    Spacer(modifier = Modifier.height(6.dp))

                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = if (ethInBusiness) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.7f) else MaterialTheme.colorScheme.surfaceVariant
                                    ) {
                                        Text(
                                            text = ethStatusLabel,
                                            fontSize = 9.5.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = if (ethInBusiness) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
                                            maxLines = 1,
                                            overflow = TextOverflow.Ellipsis
                                        )
                                    }
                                }
                            }

                            // Target Country Card
                            Surface(
                                shape = RoundedCornerShape(18.dp),
                                color = MaterialTheme.colorScheme.surface,
                                border = BorderStroke(1.dp, MaterialTheme.colorScheme.secondary.copy(alpha = 0.25f)),
                                modifier = Modifier.weight(1f)
                            ) {
                                Column(modifier = Modifier.padding(13.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(profile.flag, fontSize = 20.sp)
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Column {
                                            Text(
                                                text = profile.nameEn.substringBefore(" ("),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 13.5.sp,
                                                color = MaterialTheme.colorScheme.onSurface,
                                                maxLines = 1,
                                                overflow = TextOverflow.Ellipsis
                                            )
                                            Text(
                                                text = profile.capitalEn,
                                                fontSize = 10.5.sp,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                maxLines = 1,
                                                overflow = TextOverflow.Ellipsis
                                            )
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(10.dp))

                                    Text(
                                        text = targetFormatted12,
                                        fontSize = 18.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.secondary
                                    )
                                    Text(
                                        text = "24h: $targetFormatted24",
                                        fontSize = 10.5.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )

                                    Spacer(modifier = Modifier.height(6.dp))

                                    Text(
                                        text = "$targetDateStr G.C.",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )

                                    Spacer(modifier = Modifier.height(6.dp))

                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = if (targetInBusiness) MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.75f) else MaterialTheme.colorScheme.surfaceVariant
                                    ) {
                                        Text(
                                            text = targetStatusLabel,
                                            fontSize = 9.5.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = if (targetInBusiness) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
                                            maxLines = 1,
                                            overflow = TextOverflow.Ellipsis
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. OPTIMAL CALLING & BUSINESS WINDOW CARD
        item {
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (bothOpenNow) {
                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.45f)
                    } else {
                        MaterialTheme.colorScheme.surface
                    }
                ),
                border = BorderStroke(
                    1.dp,
                    if (bothOpenNow) MaterialTheme.colorScheme.primary.copy(alpha = 0.45f) else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                            Icon(
                                Icons.Default.Call,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Calling & Business Window",
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.5.sp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (bothOpenNow) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant
                        ) {
                            Text(
                                text = if (bothOpenNow) "Good Overlap Now" else "Check Window",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (bothOpenNow) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = profile.callingRecommendationFromAddis,
                        fontSize = 12.5.sp,
                        color = MaterialTheme.colorScheme.onSurface,
                        lineHeight = 18.sp
                    )
                }
            }
        }

        // 4. DETAILED SPECIFICATION COMPARISON CARDS
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = "Operational & Cultural Breakdown",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                ComparisonDetailCard(
                    icon = Icons.Default.Business,
                    title = "Workweek & Business Hours",
                    ethiopiaInfo = "Monday – Saturday (Half day Sat, civil offices Mon–Fri). Business 08:30 – 17:30 EAT.",
                    targetInfo = "${profile.workweek} Typical business hours: ${profile.businessHours}.",
                    targetName = profile.nameEn.substringBefore(" ("),
                    targetFlag = profile.flag
                )

                ComparisonDetailCard(
                    icon = Icons.Default.CalendarMonth,
                    title = "Calendar System & Date Format",
                    ethiopiaInfo = "13 Months (12 × 30 days + Pagume 5/6 days). Format: DD/MM/YYYY ዓ.ም.",
                    targetInfo = "Gregorian Calendar (12 months). Standard format: ${profile.dateFormatExample}.",
                    targetName = profile.nameEn.substringBefore(" ("),
                    targetFlag = profile.flag
                )

                ComparisonDetailCard(
                    icon = Icons.Default.WbSunny,
                    title = "Seasons & Climate Contrast",
                    ethiopiaInfo = "Current Season: ${ethSeason.englishName} (${ethSeason.amharicName}) ${ethSeason.emoji}.",
                    targetInfo = profile.seasonDifference,
                    targetName = profile.nameEn.substringBefore(" ("),
                    targetFlag = profile.flag
                )

                ComparisonDetailCard(
                    icon = Icons.Default.CurrencyExchange,
                    title = "Currency & International Dialing",
                    ethiopiaInfo = "Ethiopian Birr (ETB). Dialing Code: +251.",
                    targetInfo = "${profile.currencyName} (${profile.currencySymbol}). Dialing Code: ${profile.dialCode}.",
                    targetName = profile.nameEn.substringBefore(" ("),
                    targetFlag = profile.flag
                )

                ComparisonDetailCard(
                    icon = Icons.Default.Celebration,
                    title = "Holidays & Cultural Observances",
                    ethiopiaInfo = "Genna (Jan 7), Timket (Jan 19), Adwa Victory (Mar 2), Enkutatash (Sep 11).",
                    targetInfo = profile.holidayDifferences,
                    targetName = profile.nameEn.substringBefore(" ("),
                    targetFlag = profile.flag
                )
            }
        }

        // 5. ACTION BUTTONS: COPY & SHARE COMPARISON
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = {
                        val report = """
                            🌍 Country Comparison: Ethiopia 🇪🇹 vs ${profile.nameEn} ${profile.flag}
                            • Addis Ababa Time: ${ethTime.period.english} ${ethTime.hour}:${String.format(Locale.US, "%02d", ethTime.minute)} (${String.format(Locale.US, "%02d:%02d", addisHour, addisMinute)} EAT)
                            • ${profile.capitalEn} Time: $targetFormatted12 ($targetFormatted24)
                            • Time Difference: $timeDiffText
                            • Calling Window: ${profile.callingRecommendationFromAddis}
                            • Workweek: Ethiopia (Mon-Sat) vs ${profile.nameEn} (${profile.workweek})
                            • Currency: ETB vs ${profile.currencySymbol}
                            • Dialing Code: +251 vs ${profile.dialCode}
                        """.trimIndent()
                        val clip = ClipData.newPlainText("Country Comparison", report)
                        (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                        Toast.makeText(context, "Comparison report copied!", Toast.LENGTH_SHORT).show()
                    },
                    modifier = Modifier
                        .weight(1f)
                        .minimumInteractiveComponentSize()
                ) {
                    Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Copy Report", fontSize = 12.sp)
                }

                Button(
                    onClick = {
                        val report = "🌍 Ethiopia 🇪🇹 vs ${profile.nameEn} ${profile.flag}\nAddis Ababa: ${String.format(Locale.US, "%02d:%02d", addisHour, addisMinute)} EAT\n${profile.capitalEn}: $targetFormatted24 ($timeDiffText)\nCalling Window: ${profile.callingRecommendationFromAddis}"
                        val intent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_TEXT, report)
                            type = "text/plain"
                        }
                        context.startActivity(Intent.createChooser(intent, "Share Country Comparison"))
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

@Composable
private fun ComparisonDetailCard(
    icon: ImageVector,
    title: String,
    ethiopiaInfo: String,
    targetInfo: String,
    targetName: String,
    targetFlag: String
) {
    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f)
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier
                            .padding(6.dp)
                            .size(16.dp)
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            Spacer(modifier = Modifier.height(10.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
                    modifier = Modifier.weight(1f)
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text("🇪🇹 Ethiopia", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.height(3.dp))
                        Text(ethiopiaInfo, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface, lineHeight = 15.5.sp)
                    }
                }

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
                    modifier = Modifier.weight(1f)
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Text("$targetFlag $targetName", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.secondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Spacer(modifier = Modifier.height(3.dp))
                        Text(targetInfo, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface, lineHeight = 15.5.sp)
                    }
                }
            }
        }
    }
}
