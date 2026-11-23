package com.example.calendar.ui.screens.converter

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Nightlight
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.EthiopianTimeConverter
import com.example.calendar.core.GeezNumeral
import com.example.calendar.engine.WorldCountryEngine
import com.example.calendar.localization.AppLanguage
import java.util.Calendar
import java.util.Locale

/**
 * Ethiopian ⇄ World Time Converter.
 * Features a 3-segment mode switcher, tactile hour/minute steppers,
 * interactive 24-hour dial, dual-clock comparison hero card, and searchable world cities list.
 */
@Composable
fun TimeConverterTab(currentLang: AppLanguage) {
    val context = LocalContext.current
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA

    // 0: Addis 24h -> Eth & World, 1: Eth 12h -> Standard & World, 2: World City -> Eth & Addis
    var conversionMode by remember { mutableIntStateOf(0) }

    val initialCal = Calendar.getInstance()
    var gHour by remember { mutableIntStateOf(initialCal.get(Calendar.HOUR_OF_DAY)) }
    var gMinute by remember { mutableIntStateOf(initialCal.get(Calendar.MINUTE)) }

    val initialEth = EthiopianTimeConverter.gregorianToEthiopian(gHour, gMinute)
    var ethHour by remember { mutableIntStateOf(initialEth.hour) }
    var ethMinute by remember { mutableIntStateOf(initialEth.minute) }
    var ethIsDaytime by remember { mutableStateOf(initialEth.isDaytime) }

    var selectedSourceCityId by remember { mutableStateOf("ber") }
    var sourceCityHour by remember { mutableIntStateOf(12) }
    var sourceCityMinute by remember { mutableIntStateOf(0) }

    var selectedRegion by remember { mutableStateOf(WorldCountryEngine.WorldRegion.ALL) }
    var searchQuery by remember { mutableStateOf("") }
    var showExplanation by remember { mutableStateOf(false) }

    val (effectiveAddisHour, effectiveAddisMinute) = when (conversionMode) {
        0 -> Pair(gHour, gMinute)
        1 -> {
            val greg = EthiopianTimeConverter.ethiopianToGregorian(
                ethHour.coerceIn(1, 12),
                ethMinute.coerceIn(0, 59),
                ethIsDaytime
            )
            Pair(greg.hour24, greg.minute)
        }
        else -> {
            WorldCountryEngine.convertWorldCityTimeToAddisAbaba(
                cityId = selectedSourceCityId,
                hour24 = sourceCityHour,
                minute = sourceCityMinute
            )
        }
    }

    val resultEthTime = EthiopianTimeConverter.gregorianToEthiopian(effectiveAddisHour, effectiveAddisMinute)
    val resultGregTime = EthiopianTimeConverter.GregorianTime(effectiveAddisHour, effectiveAddisMinute)
    val geezHour = GeezNumeral.toGeez(resultEthTime.hour)
    val geezTimeFormatted = "$geezHour:${String.format(Locale.US, "%02d", resultEthTime.minute)} ሰዓት"

    val worldCityResults = remember(effectiveAddisHour, effectiveAddisMinute) {
        WorldCountryEngine.convertAddisAbabaTimeToWorldCities(effectiveAddisHour, effectiveAddisMinute)
    }

    val filteredCities = remember(worldCityResults, selectedRegion, searchQuery) {
        worldCityResults.filter { item ->
            val matchesRegion = selectedRegion == WorldCountryEngine.WorldRegion.ALL || item.city.region == selectedRegion
            val matchesSearch = searchQuery.isBlank() ||
                item.city.cityEn.contains(searchQuery, ignoreCase = true) ||
                item.city.countryEn.contains(searchQuery, ignoreCase = true) ||
                item.city.cityAm.contains(searchQuery)
            matchesRegion && matchesSearch
        }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 84.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. SINGLE 3-WAY SEGMENTED MODE SELECTOR
        item {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("cycle_time_converter_mode")
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    listOf(
                        Triple(0, "Addis 24h", "አዲስ 24ሰ"),
                        Triple(1, "Eth 12h", "የኢትዮጵያ 12ሰ"),
                        Triple(2, "World City", "የውጭ ከተማ")
                    ).forEach { (modeIdx, labelEn, labelAm) ->
                        val active = conversionMode == modeIdx
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (active) MaterialTheme.colorScheme.primary else Color.Transparent,
                            modifier = Modifier
                                .weight(1f)
                                .minimumInteractiveComponentSize()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable { conversionMode = modeIdx }
                        ) {
                            Box(
                                contentAlignment = Alignment.Center,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 10.dp)
                            ) {
                                Text(
                                    text = if (isGeezScript) labelAm else labelEn,
                                    fontSize = 12.sp,
                                    fontWeight = if (active) FontWeight.Bold else FontWeight.Medium,
                                    color = if (active) {
                                        MaterialTheme.colorScheme.onPrimary
                                    } else {
                                        MaterialTheme.colorScheme.onSurfaceVariant
                                    },
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }
                }
            }
        }

        // 2. TACTILE TIME INPUT CARD
        item {
            Card(
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = when (conversionMode) {
                                    0 -> "ADDIS ABABA (UTC+3)"
                                    1 -> "ETHIOPIAN 12-HOUR CLOCK"
                                    else -> "ORIGIN WORLD CITY"
                                },
                                fontSize = 10.5.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = MaterialTheme.colorScheme.primary,
                                letterSpacing = 0.8.sp
                            )
                            Text(
                                text = when (conversionMode) {
                                    0 -> "Standard 24-Hour Input"
                                    1 -> "Traditional Dawn-to-Dusk Input"
                                    else -> "Local City Time Input"
                                },
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.5.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }

                        AssistChip(
                            onClick = {
                                val now = Calendar.getInstance()
                                gHour = now.get(Calendar.HOUR_OF_DAY)
                                gMinute = now.get(Calendar.MINUTE)
                                val converted = EthiopianTimeConverter.gregorianToEthiopian(gHour, gMinute)
                                ethHour = converted.hour
                                ethMinute = converted.minute
                                ethIsDaytime = converted.isDaytime
                                sourceCityHour = gHour
                                sourceCityMinute = gMinute
                                Toast.makeText(context, "Synced to current time", Toast.LENGTH_SHORT).show()
                            },
                            label = { Text("Live Now", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                            leadingIcon = {
                                Icon(Icons.Default.AccessTime, contentDescription = null, modifier = Modifier.size(14.dp))
                            }
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    when (conversionMode) {
                        0 -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                TimeStepperBox(
                                    label = "Hour (0-23)",
                                    valueText = String.format(Locale.US, "%02d", gHour),
                                    onDecrement = { gHour = if (gHour == 0) 23 else gHour - 1 },
                                    onIncrement = { gHour = (gHour + 1) % 24 },
                                    modifier = Modifier.weight(1f)
                                )
                                TimeStepperBox(
                                    label = "Minute (0-59)",
                                    valueText = String.format(Locale.US, "%02d", gMinute),
                                    onDecrement = { gMinute = if (gMinute < 5) (gMinute + 55) % 60 else gMinute - 5 },
                                    onIncrement = { gMinute = (gMinute + 5) % 60 },
                                    modifier = Modifier.weight(1f)
                                )
                            }

                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "24-Hour Dial: ${String.format(Locale.US, "%02d:%02d", gHour, gMinute)} EAT",
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Slider(
                                value = gHour.toFloat(),
                                onValueChange = { gHour = it.toInt() },
                                valueRange = 0f..23f,
                                steps = 22,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                        1 -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                TimeStepperBox(
                                    label = "Hour (1-12)",
                                    valueText = ethHour.toString(),
                                    onDecrement = { ethHour = if (ethHour <= 1) 12 else ethHour - 1 },
                                    onIncrement = { ethHour = if (ethHour >= 12) 1 else ethHour + 1 },
                                    modifier = Modifier.weight(1f)
                                )
                                TimeStepperBox(
                                    label = "Minute (0-59)",
                                    valueText = String.format(Locale.US, "%02d", ethMinute),
                                    onDecrement = { ethMinute = if (ethMinute < 5) (ethMinute + 55) % 60 else ethMinute - 5 },
                                    onIncrement = { ethMinute = (ethMinute + 5) % 60 },
                                    modifier = Modifier.weight(1f)
                                )
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = if (ethIsDaytime) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                                    border = if (ethIsDaytime) BorderStroke(1.dp, MaterialTheme.colorScheme.primary) else null,
                                    modifier = Modifier
                                        .weight(1f)
                                        .minimumInteractiveComponentSize()
                                        .clip(RoundedCornerShape(12.dp))
                                        .clickable { ethIsDaytime = true }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(vertical = 10.dp, horizontal = 12.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.Center
                                    ) {
                                        Icon(
                                            Icons.Default.WbSunny,
                                            contentDescription = null,
                                            tint = if (ethIsDaytime) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = "Daytime (ቀን)",
                                            fontWeight = if (ethIsDaytime) FontWeight.Bold else FontWeight.Medium,
                                            color = if (ethIsDaytime) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                            fontSize = 12.sp
                                        )
                                    }
                                }

                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = if (!ethIsDaytime) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                                    border = if (!ethIsDaytime) BorderStroke(1.dp, MaterialTheme.colorScheme.primary) else null,
                                    modifier = Modifier
                                        .weight(1f)
                                        .minimumInteractiveComponentSize()
                                        .clip(RoundedCornerShape(12.dp))
                                        .clickable { ethIsDaytime = false }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(vertical = 10.dp, horizontal = 12.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.Center
                                    ) {
                                        Icon(
                                            Icons.Default.Nightlight,
                                            contentDescription = null,
                                            tint = if (!ethIsDaytime) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = "Nighttime (ሌሊት)",
                                            fontWeight = if (!ethIsDaytime) FontWeight.Bold else FontWeight.Medium,
                                            color = if (!ethIsDaytime) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                            fontSize = 12.sp
                                        )
                                    }
                                }
                            }
                        }
                        else -> {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .horizontalScroll(rememberScrollState()),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                listOf(
                                    "ber" to "🇩🇪 Berlin",
                                    "lon" to "🇬🇧 London",
                                    "par" to "🇫🇷 Paris",
                                    "sto" to "🇸🇪 Stockholm",
                                    "was" to "🇺🇸 Washington",
                                    "dxb" to "🇦🇪 Dubai",
                                    "ruh" to "🇸🇦 Riyadh"
                                ).forEach { (cid, clabel) ->
                                    FilterChip(
                                        selected = selectedSourceCityId == cid,
                                        onClick = { selectedSourceCityId = cid },
                                        label = { Text(clabel, fontSize = 11.sp) }
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                TimeStepperBox(
                                    label = "Local Hour",
                                    valueText = String.format(Locale.US, "%02d", sourceCityHour),
                                    onDecrement = { sourceCityHour = if (sourceCityHour == 0) 23 else sourceCityHour - 1 },
                                    onIncrement = { sourceCityHour = (sourceCityHour + 1) % 24 },
                                    modifier = Modifier.weight(1f)
                                )
                                TimeStepperBox(
                                    label = "Local Minute",
                                    valueText = String.format(Locale.US, "%02d", sourceCityMinute),
                                    onDecrement = { sourceCityMinute = if (sourceCityMinute < 5) (sourceCityMinute + 55) % 60 else sourceCityMinute - 5 },
                                    onIncrement = { sourceCityMinute = (sourceCityMinute + 5) % 60 },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "Quick Ethiopian Hours:",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        listOf(
                            Triple(6, 0, "12:00 Dawn (6 AM)"),
                            Triple(7, 0, "1:00 Morning (7 AM)"),
                            Triple(9, 0, "3:00 Morning (9 AM)"),
                            Triple(12, 0, "6:00 Noon (12 PM)"),
                            Triple(15, 0, "9:00 Afternoon (3 PM)"),
                            Triple(18, 0, "12:00 Dusk (6 PM)"),
                            Triple(20, 0, "2:00 Evening (8 PM)")
                        ).forEach { (h, m, label) ->
                            val isSel = effectiveAddisHour == h && effectiveAddisMinute == m
                            FilterChip(
                                selected = isSel,
                                onClick = {
                                    gHour = h
                                    gMinute = m
                                    val conv = EthiopianTimeConverter.gregorianToEthiopian(h, m)
                                    ethHour = conv.hour
                                    ethMinute = conv.minute
                                    ethIsDaytime = conv.isDaytime
                                    sourceCityHour = h
                                    sourceCityMinute = m
                                },
                                label = { Text(label, fontSize = 10.5.sp) }
                            )
                        }
                    }
                }
            }
        }

        // 3. DUAL-CLOCK CONVERSION RESULT HERO CARD
        item {
            ElevatedCard(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("time_converter_hero_card")
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f),
                                    MaterialTheme.colorScheme.surfaceVariant
                                )
                            )
                        )
                        .padding(18.dp)
                ) {
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "CONVERTED CLOCK",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = MaterialTheme.colorScheme.primary,
                                letterSpacing = 0.8.sp
                            )

                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (resultEthTime.isDaytime) {
                                    MaterialTheme.colorScheme.primaryContainer
                                } else {
                                    MaterialTheme.colorScheme.secondaryContainer
                                }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = if (resultEthTime.isDaytime) Icons.Default.WbSunny else Icons.Default.Nightlight,
                                        contentDescription = null,
                                        modifier = Modifier.size(13.dp),
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = if (resultEthTime.isDaytime) "Daytime (ቀን)" else "Nighttime (ሌሊት)",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Side-by-Side Comparison Tiles
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = MaterialTheme.colorScheme.surface,
                                modifier = Modifier.weight(1.1f)
                            ) {
                                Column(modifier = Modifier.padding(14.dp)) {
                                    Text(
                                        text = "🇪🇹 Ethiopian 12h",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = "${resultEthTime.hour}:${String.format(Locale.US, "%02d", resultEthTime.minute)}",
                                        fontSize = 26.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Text(
                                        text = "${resultEthTime.period.english} • ${resultEthTime.period.amharic}",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = geezTimeFormatted,
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }

                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = MaterialTheme.colorScheme.surface,
                                modifier = Modifier.weight(0.9f)
                            ) {
                                Column(modifier = Modifier.padding(14.dp)) {
                                    Text(
                                        text = "🌍 Addis EAT",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.secondary
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = String.format(Locale.US, "%02d:%02d", resultGregTime.hour24, resultGregTime.minute),
                                        fontSize = 26.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Text(
                                        text = "${resultGregTime.hour12}:${String.format(Locale.US, "%02d", resultGregTime.minute)} ${if (resultGregTime.isPm) "PM" else "AM"}",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = MaterialTheme.colorScheme.secondary
                                    )
                                    Text(
                                        text = "UTC+3 Standard",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedButton(
                                onClick = {
                                    val text = "Ethiopian Time: ${resultEthTime.period.english} ${resultEthTime.hour}:${String.format(Locale.US, "%02d", resultEthTime.minute)} (${resultEthTime.period.amharic} / $geezTimeFormatted)\nAddis Ababa Standard: ${String.format(Locale.US, "%02d:%02d", resultGregTime.hour24, resultGregTime.minute)} EAT"
                                    val clip = ClipData.newPlainText("Ethiopian Time Conversion", text)
                                    (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                    Toast.makeText(context, "Time copied!", Toast.LENGTH_SHORT).show()
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Copy", fontSize = 12.sp)
                            }

                            Button(
                                onClick = {
                                    val text = "Ethiopian Time: ${resultEthTime.period.english} ${resultEthTime.hour}:${String.format(Locale.US, "%02d", resultEthTime.minute)}\nAddis Ababa EAT: ${String.format(Locale.US, "%02d:%02d", resultGregTime.hour24, resultGregTime.minute)}"
                                    val intent = Intent().apply {
                                        action = Intent.ACTION_SEND
                                        putExtra(Intent.EXTRA_TEXT, text)
                                        type = "text/plain"
                                    }
                                    context.startActivity(Intent.createChooser(intent, "Share Time"))
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Share", fontSize = 12.sp)
                            }
                        }
                    }
                }
            }
        }

        // 4. WORLD CITIES SEARCH & FILTER HEADER
        item {
            Column(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Public, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "World & Diaspora Cities",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    Text(
                        text = "${filteredCities.size} cities",
                        fontSize = 11.5.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Search city or country...", fontSize = 12.5.sp) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp)) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Clear, contentDescription = "Clear", modifier = Modifier.size(18.dp))
                            }
                        }
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    WorldCountryEngine.WorldRegion.values().forEach { reg ->
                        FilterChip(
                            selected = selectedRegion == reg,
                            onClick = { selectedRegion = reg },
                            label = { Text(reg.labelEn, fontSize = 11.sp) }
                        )
                    }
                }
            }
        }

        // 5. WORLD CITIES LIST
        items(filteredCities, key = { it.city.id }) { item ->
            WorldCityTimeCard(item = item)
        }

        // 6. EDUCATIONAL GUIDE CARD
        item {
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .minimumInteractiveComponentSize()
                            .clickable { showExplanation = !showExplanation },
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Info, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "How Ethiopian 12h Time Works",
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        Text(
                            text = if (showExplanation) "Hide ▲" else "Learn ▼",
                            fontSize = 11.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    AnimatedVisibility(visible = showExplanation) {
                        Column(modifier = Modifier.padding(top = 10.dp)) {
                            Text(
                                text = "• Day begins at Sunrise (06:00 AM EAT = 12:00 Dawn Ethiopian).\n" +
                                    "• 07:00 AM EAT = 1:00 Morning; 12:00 PM EAT = 6:00 Noon.\n" +
                                    "• Night begins at Sunset (06:00 PM EAT = 12:00 Dusk Ethiopian).\n" +
                                    "• Quick rule: Add or subtract 6 hours between 12h Ethiopian and 12h standard time.",
                                fontSize = 12.sp,
                                lineHeight = 18.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TimeStepperBox(
    label: String,
    valueText: String,
    onDecrement: () -> Unit,
    onIncrement: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)),
        modifier = modifier
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp)
        ) {
            Text(
                text = label,
                fontSize = 10.5.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.surface,
                    modifier = Modifier
                        .size(38.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onDecrement() }
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.Remove, contentDescription = "Decrease $label", modifier = Modifier.size(18.dp), tint = MaterialTheme.colorScheme.primary)
                    }
                }

                Text(
                    text = valueText,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Black,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.surface,
                    modifier = Modifier
                        .size(38.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onIncrement() }
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.Add, contentDescription = "Increase $label", modifier = Modifier.size(18.dp), tint = MaterialTheme.colorScheme.primary)
                    }
                }
            }
        }
    }
}

@Composable
private fun WorldCityTimeCard(item: WorldCountryEngine.WorldCityTimeResult) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1.3f)) {
                Text(item.city.flag, fontSize = 24.sp)
                Spacer(modifier = Modifier.width(10.dp))
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = item.city.cityEn,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "(${item.city.cityAm})",
                            fontSize = 10.5.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text(
                        text = "${item.city.countryEn} • ${item.timeZoneAbbreviation}",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    val diff = item.differenceFromAddisHours
                    val diffLabel = when {
                        diff == 0.0 -> "Same as Addis"
                        diff > 0 -> "+${diff.toInt()}h ahead"
                        else -> "${diff.toInt()}h behind"
                    }
                    Text(
                        text = diffLabel,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1f)) {
                Text(
                    text = item.formattedTime12,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 16.sp,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "${item.formattedTime24} (24h)",
                    fontSize = 10.5.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (item.dayOffset != 0) {
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = MaterialTheme.colorScheme.errorContainer
                        ) {
                            Text(
                                text = if (item.dayOffset > 0) "+1d" else "-1d",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onErrorContainer,
                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                            )
                        }
                    }
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = Color(item.businessStatus.colorHex).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = item.businessStatus.label.substringBefore(" ("),
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(item.businessStatus.colorHex),
                            modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                        )
                    }
                }
            }
        }
    }
}
