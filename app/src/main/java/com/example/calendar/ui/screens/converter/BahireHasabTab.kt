package com.example.calendar.ui.screens.converter

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
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
import androidx.compose.material.icons.filled.Church
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.engine.BahireHasabCalculator
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

/**
 * Modern Bahire Hasab (Computus & Movable Feasts) Explorer.
 * Tactile year stepper capsule, dynamic year presets centered on the active year,
 * theme-aware computus hero card, and filterable movable feasts & fasts list.
 */
@Composable
fun BahireHasabTab(viewModel: MainViewModel, currentLang: AppLanguage) {
    val context = LocalContext.current
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA
    val todayEth = viewModel.todayEthiopian

    var queryYear by remember { mutableIntStateOf(todayEth.year) }
    var showYearDialog by remember { mutableStateOf(false) }
    var yearInputText by remember { mutableStateOf("") }
    var feastFilter by remember { mutableStateOf("ALL") } // "ALL" | "FEAST" | "FAST"

    val bahireHasab = remember(queryYear) {
        BahireHasabCalculator.calculate(queryYear)
    }
    val isLeap = LeapYearCalculator.isEthiopianLeapYear(queryYear)
    val neneweGreg = remember(bahireHasab) {
        EthiopianCalendarEngine.toGregorian(bahireHasab.nenewe)
    }

    val filteredFeasts = remember(bahireHasab, feastFilter) {
        when (feastFilter) {
            "FEAST" -> bahireHasab.movableFeasts.filter { !it.isFast }
            "FAST" -> bahireHasab.movableFeasts.filter { it.isFast }
            else -> bahireHasab.movableFeasts
        }
    }

    val yearPresets = remember(todayEth.year) {
        listOf(
            "${todayEth.year - 2}" to (todayEth.year - 2).coerceAtLeast(1),
            "${todayEth.year - 1}" to (todayEth.year - 1).coerceAtLeast(1),
            "${todayEth.year} (Current)" to todayEth.year,
            "${todayEth.year + 1}" to todayEth.year + 1,
            "${todayEth.year + 2}" to todayEth.year + 2,
            "${todayEth.year + 5}" to todayEth.year + 5,
            "${todayEth.year + 10}" to todayEth.year + 10
        )
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 84.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. TACTILE COMPUTUS YEAR SELECTOR CARD
        item {
            Card(
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
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
                                text = "COMPUTUS YEAR • ባሕረ ሐሳብ",
                                fontSize = 10.5.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = MaterialTheme.colorScheme.primary,
                                letterSpacing = 0.8.sp
                            )
                            Text(
                                text = if (isGeezScript) "የበዓላትና አጽዋማት ቀመር" else "Movable Feasts & Fasts",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }

                        AssistChip(
                            onClick = { queryYear = todayEth.year },
                            label = { Text(if (isGeezScript) "የዘንድሮ ዓመት" else "This Year", fontSize = 11.sp) },
                            leadingIcon = {
                                Icon(Icons.Default.Today, contentDescription = null, modifier = Modifier.size(14.dp))
                            }
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Tactile Year Stepper Capsule
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 8.dp, vertical = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                BahireYearStepPill("-5") { queryYear = (queryYear - 5).coerceAtLeast(1) }
                                BahireYearStepPill("-1") { queryYear = (queryYear - 1).coerceAtLeast(1) }
                            }

                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = MaterialTheme.colorScheme.primaryContainer,
                                modifier = Modifier
                                    .minimumInteractiveComponentSize()
                                    .clip(RoundedCornerShape(12.dp))
                                    .clickable {
                                        yearInputText = queryYear.toString()
                                        showYearDialog = true
                                    }
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
                                ) {
                                    Text(
                                        text = "$queryYear ዓ.ም",
                                        fontSize = 17.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Icon(
                                        Icons.Default.Edit,
                                        contentDescription = "Edit Computus Year",
                                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                        modifier = Modifier.size(14.dp)
                                    )
                                }
                            }

                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                BahireYearStepPill("+1") { queryYear = (queryYear + 1).coerceAtMost(9999) }
                                BahireYearStepPill("+5") { queryYear = (queryYear + 5).coerceAtMost(9999) }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Dynamic Unclipped Quick Jump Presets
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        yearPresets.forEach { (label, targetYear) ->
                            FilterChip(
                                selected = queryYear == targetYear,
                                onClick = { queryYear = targetYear },
                                label = { Text(label, fontSize = 11.sp) }
                            )
                        }
                    }
                }
            }
        }

        // 2. SUMMARY COMPUTUS HERO CARD (Theme-aware Gradient Surface)
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
                        .padding(18.dp)
                ) {
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.Top
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Year $queryYear E.C. • ${bahireHasab.evangelist.english}",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Black,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "ዘመነ ${bahireHasab.evangelist.amharic} • ${if (isLeap) "Leap Year (ዘመነ ሉቃስ)" else "Common Year (መደበኛ ዓመት)"}",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (isLeap) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface
                            ) {
                                Text(
                                    text = if (isLeap) "366 Days" else "365 Days",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isLeap) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.padding(horizontal = 9.dp, vertical = 4.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Computus 2x2 Metrics Grid
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            ComputusMetricCard(
                                title = "Amete Alem",
                                value = "${bahireHasab.ameteAlem}",
                                subtitle = "ዓመተ ዓለም (5500 + $queryYear)",
                                accent = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.weight(1f)
                            )
                            ComputusMetricCard(
                                title = "Wenber (ወንበር)",
                                value = "${bahireHasab.wenber}",
                                subtitle = "19-year lunar cycle",
                                accent = MaterialTheme.colorScheme.secondary,
                                modifier = Modifier.weight(1f)
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            ComputusMetricCard(
                                title = "Abeqte (አበቅቴ)",
                                value = "${bahireHasab.abeqte}",
                                subtitle = "Lunar epact age",
                                accent = MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.weight(1f)
                            )
                            ComputusMetricCard(
                                title = "Metqi (መጥቅዕ)",
                                value = "${bahireHasab.metqi} ${if (bahireHasab.metqiMonth == 1) "Meskerem" else "Tikimt"}",
                                subtitle = "Paschal anchor date",
                                accent = MaterialTheme.colorScheme.tertiary,
                                modifier = Modifier.weight(1f)
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        // Nineveh Fast Highlight Banner
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = MaterialTheme.colorScheme.primaryContainer,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.Church,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(22.dp)
                                )
                                Spacer(modifier = Modifier.width(10.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = "Fast of Nineveh (ጾመ ነነዌ)",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = "${LocaleStrings.getMonthName(bahireHasab.nenewe.month, AppLanguage.ENGLISH)} ${bahireHasab.nenewe.day}, $queryYear E.C. • ${neneweGreg.day}/${neneweGreg.month}/${neneweGreg.year} G.C.",
                                        fontSize = 13.5.sp,
                                        fontWeight = FontWeight.ExtraBold,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                    Text(
                                        text = "Foundation date from which all movable fasts & Easter are calculated",
                                        fontSize = 10.5.sp,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.82f)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. MOVABLE FEASTS HEADER, FILTER CHIPS & SHARE/COPY
        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Movable Feasts & Fasts (${filteredFeasts.size})",
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.primary
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        OutlinedButton(
                            onClick = {
                                val text = buildString {
                                    appendLine("Bahire Hasab ($queryYear E.C.) • Year of ${bahireHasab.evangelist.english}")
                                    appendLine("Amete Alem: ${bahireHasab.ameteAlem} | Wenber: ${bahireHasab.wenber} | Abeqte: ${bahireHasab.abeqte} | Metqi: ${bahireHasab.metqi}")
                                    bahireHasab.movableFeasts.forEach { f ->
                                        val g = EthiopianCalendarEngine.toGregorian(f.ethiopianDate)
                                        appendLine("• ${f.nameEnglish} (${f.nameAmharic}): ${LocaleStrings.getMonthName(f.ethiopianDate.month, AppLanguage.ENGLISH)} ${f.ethiopianDate.day} = ${g.day}/${g.month}/${g.year}")
                                    }
                                }
                                val clip = ClipData.newPlainText("Bahire Hasab", text)
                                (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                Toast.makeText(context, "Computus copied!", Toast.LENGTH_SHORT).show()
                            },
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                            modifier = Modifier.minimumInteractiveComponentSize()
                        ) {
                            Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Copy", fontSize = 11.5.sp)
                        }

                        OutlinedButton(
                            onClick = {
                                val text = buildString {
                                    appendLine("Ethiopian Orthodox Bahire Hasab for Year $queryYear E.C.:")
                                    appendLine("Evangelist: Year of ${bahireHasab.evangelist.english} (${bahireHasab.evangelist.amharic})")
                                    appendLine("Amete Alem: ${bahireHasab.ameteAlem} • Wenber: ${bahireHasab.wenber} • Abeqte: ${bahireHasab.abeqte} • Metqi: ${bahireHasab.metqi}")
                                    appendLine()
                                    bahireHasab.movableFeasts.forEach { f ->
                                        val g = EthiopianCalendarEngine.toGregorian(f.ethiopianDate)
                                        appendLine("• ${f.nameEnglish} (${f.nameAmharic}): ${LocaleStrings.getMonthName(f.ethiopianDate.month, AppLanguage.ENGLISH)} ${f.ethiopianDate.day} = ${g.day}/${g.month}/${g.year} G.C.")
                                    }
                                }
                                val intent = Intent().apply {
                                    action = Intent.ACTION_SEND
                                    putExtra(Intent.EXTRA_TEXT, text)
                                    type = "text/plain"
                                }
                                context.startActivity(Intent.createChooser(intent, "Share Movable Feasts"))
                            },
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                            modifier = Modifier.minimumInteractiveComponentSize()
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Share", fontSize = 11.5.sp)
                        }
                    }
                }

                // Filter Pills
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf(
                        "ALL" to "All (${bahireHasab.movableFeasts.size})",
                        "FEAST" to "Feasts (${bahireHasab.movableFeasts.count { !it.isFast }})",
                        "FAST" to "Fasts (${bahireHasab.movableFeasts.count { it.isFast }})"
                    ).forEach { (key, label) ->
                        FilterChip(
                            selected = feastFilter == key,
                            onClick = { feastFilter = key },
                            label = { Text(label, fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold) }
                        )
                    }
                }
            }
        }

        // 4. MOVABLE FEASTS LIST
        items(filteredFeasts, key = { "${it.nameEnglish}_${it.ethiopianDate.month}_${it.ethiopianDate.day}" }) { feast ->
            val gDate = EthiopianCalendarEngine.toGregorian(feast.ethiopianDate)
            val dow = EthiopianCalendarEngine.getDayOfWeek(feast.ethiopianDate)
            val daysDiff = EthiopianCalendarEngine.daysBetween(todayEth, feast.ethiopianDate)
            val countdownBadge = when {
                daysDiff == 0L -> "Today!"
                daysDiff == 1L -> "Tomorrow"
                daysDiff > 1L -> "In $daysDiff days"
                else -> "Passed"
            }

            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = feast.nameEnglish,
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                color = if (feast.isFast) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.primary,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f, fill = false)
                            )
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (feast.isFast) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.primaryContainer
                            ) {
                                Text(
                                    text = if (feast.isFast) "Fast (ጾም)" else "Feast (በዓል)",
                                    fontSize = 9.5.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (feast.isFast) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onPrimaryContainer,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(2.dp))

                        Text(
                            text = feast.nameAmharic,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface
                        )

                        Text(
                            text = feast.description,
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    Spacer(modifier = Modifier.width(10.dp))

                    Column(horizontalAlignment = Alignment.End) {
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = MaterialTheme.colorScheme.surfaceVariant
                        ) {
                            Text(
                                text = "${LocaleStrings.getMonthName(feast.ethiopianDate.month, AppLanguage.ENGLISH)} ${feast.ethiopianDate.day}",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(horizontal = 9.dp, vertical = 4.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(4.dp))

                        Text(
                            text = "${gDate.day}/${gDate.month}/${gDate.year} (${LocaleStrings.getWeekdayShort(dow, AppLanguage.ENGLISH)})",
                            fontSize = 10.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Text(
                            text = countdownBadge,
                            fontSize = 10.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (daysDiff in 0..30) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }

    if (showYearDialog) {
        AlertDialog(
            onDismissRequest = { showYearDialog = false },
            title = {
                Text(
                    text = "Enter Computus Year (E.C.)",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column {
                    Text(
                        text = "Enter any Ethiopian year from 1 to 9999.",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = yearInputText,
                        onValueChange = { yearInputText = it },
                        singleLine = true,
                        label = { Text("Year E.C.") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    yearInputText.toIntOrNull()?.let { y ->
                        if (y in 1..9999) queryYear = y
                    }
                    showYearDialog = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showYearDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun BahireYearStepPill(label: String, onClick: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
        modifier = Modifier
            .size(width = 40.dp, height = 38.dp)
            .clip(RoundedCornerShape(10.dp))
            .clickable { onClick() }
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = label,
                fontSize = 11.5.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun ComputusMetricCard(
    title: String,
    value: String,
    subtitle: String,
    accent: androidx.compose.ui.graphics.Color,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(title, fontSize = 10.5.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(2.dp))
            Text(value, fontSize = 16.sp, fontWeight = FontWeight.Black, color = accent, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(subtitle, fontSize = 9.5.sp, color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.85f), maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}
