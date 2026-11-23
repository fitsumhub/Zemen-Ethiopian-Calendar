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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Backspace
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.core.GeezNumeral

/**
 * Bidirectional Ge'ez Numeral (የግዕዝ አኃዛት) Converter & Educational Reference.
 * Supports Arabic ⇄ Ge'ez conversion with dynamic current year default,
 * mathematical place-value decomposition, and a tactile Ge'ez virtual keypad.
 */
@Composable
fun GeezNumeralTab(todayEthYear: Int = 2019) {
    val context = LocalContext.current
    var isArabicToGeez by remember { mutableStateOf(true) }

    var arabicInput by remember { mutableIntStateOf(todayEthYear) }
    var geezInputText by remember { mutableStateOf(GeezNumeral.toGeez(todayEthYear)) }

    data class GeezSymbolInfo(val symbol: String, val value: Int, val nameGeez: String)

    val geezReferenceList = remember {
        listOf(
            GeezSymbolInfo("፩", 1, "አሐዱ"),
            GeezSymbolInfo("፪", 2, "ክልኤቱ"),
            GeezSymbolInfo("፫", 3, "ሠለስቱ"),
            GeezSymbolInfo("፬", 4, "አርባዕቱ"),
            GeezSymbolInfo("፭", 5, "ኀምስቱ"),
            GeezSymbolInfo("፮", 6, "ሰድስቱ"),
            GeezSymbolInfo("፯", 7, "ሰብዐቱ"),
            GeezSymbolInfo("፰", 8, "ሰመንቱ"),
            GeezSymbolInfo("፱", 9, "ተስዐቱ"),
            GeezSymbolInfo("፲", 10, "ዐሠርቱ"),
            GeezSymbolInfo("፳", 20, "ዕሥራ"),
            GeezSymbolInfo("፴", 30, "ሠላሳ"),
            GeezSymbolInfo("፵", 40, "አርብዓ"),
            GeezSymbolInfo("፶", 50, "ኀምሳ"),
            GeezSymbolInfo("፷", 60, "ስድሳ"),
            GeezSymbolInfo("፸", 70, "ሰብዓ"),
            GeezSymbolInfo("፹", 80, "ሰማንያ"),
            GeezSymbolInfo("፺", 90, "ተስዓ"),
            GeezSymbolInfo("፻", 100, "ምእት"),
            GeezSymbolInfo("፼", 10000, "እልፍ")
        )
    }

    fun explainGeezDecomposition(n: Int): String {
        if (n <= 0) return ""
        val parts = mutableListOf<String>()
        val myriads = n / 10000
        val remAfterMyriad = n % 10000
        val hundreds = remAfterMyriad / 100
        val remAfterHundreds = remAfterMyriad % 100
        val tens = (remAfterHundreds / 10) * 10
        val ones = remAfterHundreds % 10
        if (myriads > 0) parts.add(if (myriads == 1) "፼ (10,000)" else "${GeezNumeral.toGeez(myriads)}×፼ (${myriads * 10000})")
        if (hundreds > 0) parts.add(if (hundreds == 1) "፻ (100)" else "${GeezNumeral.toGeez(hundreds)}×፻ (${hundreds * 100})")
        if (tens > 0) parts.add("${GeezNumeral.toGeez(tens)} ($tens)")
        if (ones > 0) parts.add("${GeezNumeral.toGeez(ones)} ($ones)")
        return parts.joinToString(" + ")
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 84.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. CLEAN 2-SEGMENT MODE SWITCHER
        item {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    listOf(
                        true to "123 Arabic ➔ ፩፪፫ Ge'ez",
                        false to "፩፪፫ Ge'ez ➔ 123 Arabic"
                    ).forEach { (toGeezOption, label) ->
                        val active = isArabicToGeez == toGeezOption
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (active) MaterialTheme.colorScheme.primary else Color.Transparent,
                            modifier = Modifier
                                .weight(1f)
                                .minimumInteractiveComponentSize()
                                .clip(RoundedCornerShape(12.dp))
                                .clickable { isArabicToGeez = toGeezOption }
                        ) {
                            Box(
                                contentAlignment = Alignment.Center,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 10.dp)
                            ) {
                                Text(
                                    text = label,
                                    fontSize = 11.5.sp,
                                    fontWeight = if (active) FontWeight.Bold else FontWeight.Medium,
                                    color = if (active) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }

        // 2. INPUT CARD
        item {
            Card(
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = if (isArabicToGeez) "ENTER ARABIC NUMBER (1 – 99,999)" else "COMPOSE GE'EZ NUMERAL",
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.primary,
                        letterSpacing = 0.8.sp
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    if (isArabicToGeez) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            OutlinedTextField(
                                value = arabicInput.toString(),
                                onValueChange = {
                                    it.toIntOrNull()?.let { num ->
                                        if (num in 1..99999) arabicInput = num
                                    }
                                },
                                label = { Text("Arabic Number") },
                                singleLine = true,
                                modifier = Modifier.weight(1.2f)
                            )

                            FilledTonalButton(
                                onClick = { if (arabicInput > 1) arabicInput -= 1 },
                                modifier = Modifier.height(52.dp)
                            ) {
                                Text("-1", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            }

                            FilledTonalButton(
                                onClick = { if (arabicInput < 99999) arabicInput += 1 },
                                modifier = Modifier.height(52.dp)
                            ) {
                                Text("+1", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            listOf("+10" to 10, "+100" to 100, "+1000" to 1000).forEach { (lbl, step) ->
                                FilledTonalButton(
                                    onClick = { arabicInput = (arabicInput + step).coerceAtMost(99999) },
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(38.dp)
                                ) {
                                    Text(lbl, fontSize = 11.5.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = "Quick Presets:",
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
                                "1 (፩)" to 1,
                                "7 (፯)" to 7,
                                "12 (፲፪)" to 12,
                                "30 (፴)" to 30,
                                "100 (፻)" to 100,
                                "$todayEthYear (${GeezNumeral.toGeez(todayEthYear)})" to todayEthYear
                            ).forEach { (label, value) ->
                                FilterChip(
                                    selected = arabicInput == value,
                                    onClick = { arabicInput = value },
                                    label = { Text(label, fontSize = 11.sp) }
                                )
                            }
                        }
                    } else {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedTextField(
                                value = geezInputText,
                                onValueChange = { geezInputText = it },
                                label = { Text("Ge'ez Numeral (e.g. ${GeezNumeral.toGeez(todayEthYear)})") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )

                            IconButton(
                                onClick = {
                                    if (geezInputText.isNotEmpty()) {
                                        geezInputText = geezInputText.dropLast(1)
                                    }
                                }
                            ) {
                                Icon(Icons.AutoMirrored.Filled.Backspace, contentDescription = "Backspace")
                            }

                            FilledTonalButton(
                                onClick = { geezInputText = "" },
                                modifier = Modifier.height(50.dp)
                            ) {
                                Text("Clear", fontSize = 12.sp)
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = "Units (1 – 9)",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            listOf("፩", "፪", "፫", "፬", "፭", "፮", "፯", "፰", "፱").forEach { sym ->
                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.65f),
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(44.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .clickable { geezInputText += sym }
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Text(
                                            text = sym,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 16.sp,
                                            color = MaterialTheme.colorScheme.onPrimaryContainer
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        Text(
                            text = "Tens, Hundred (፻) & Ten-Thousand (፼)",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            listOf("፲", "፳", "፴", "፵", "፶", "፷", "፸", "፹", "፺", "፻", "፼").forEach { sym ->
                                val isMultiplier = sym == "፻" || sym == "፼"
                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = if (isMultiplier) {
                                        MaterialTheme.colorScheme.secondaryContainer
                                    } else {
                                        MaterialTheme.colorScheme.surfaceVariant
                                    },
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(44.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .clickable { geezInputText += sym }
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Text(
                                            text = sym,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 14.sp,
                                            color = if (isMultiplier) {
                                                MaterialTheme.colorScheme.onSecondaryContainer
                                            } else {
                                                MaterialTheme.colorScheme.onSurface
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. CONVERSION RESULT HERO CARD
        item {
            val parsedNumber = if (isArabicToGeez) arabicInput else GeezNumeral.fromGeez(geezInputText.trim())
            val isValid = parsedNumber != null && parsedNumber > 0
            val arabicDisplay = if (isValid) parsedNumber.toString() else "Invalid Ge'ez Numeral"
            val geezDisplay = if (isArabicToGeez) GeezNumeral.toGeez(arabicInput) else geezInputText
            val breakdown = if (parsedNumber != null && parsedNumber > 0) explainGeezDecomposition(parsedNumber) else ""

            ElevatedCard(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp),
                modifier = Modifier.fillMaxWidth()
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
                        Text(
                            text = "GE'EZ CONVERSION RESULT",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = MaterialTheme.colorScheme.primary,
                            letterSpacing = 0.8.sp
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = MaterialTheme.colorScheme.surface,
                                modifier = Modifier.weight(1f)
                            ) {
                                Column(modifier = Modifier.padding(14.dp)) {
                                    Text("Ge'ez Script", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = geezDisplay.ifBlank { "—" },
                                        fontSize = 28.sp,
                                        fontWeight = FontWeight.Black,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }

                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = MaterialTheme.colorScheme.surface,
                                modifier = Modifier.weight(1f)
                            ) {
                                Column(modifier = Modifier.padding(14.dp)) {
                                    Text("Arabic Value", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = arabicDisplay,
                                        fontSize = if (isValid) 26.sp else 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.secondary
                                    )
                                }
                            }
                        }

                        if (breakdown.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(10.dp))
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = MaterialTheme.colorScheme.surface.copy(alpha = 0.85f),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = "Structure: $breakdown",
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedButton(
                                onClick = {
                                    val clip = ClipData.newPlainText("Geez Numeral", geezDisplay)
                                    (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                                    Toast.makeText(context, "Copied $geezDisplay", Toast.LENGTH_SHORT).show()
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(15.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Copy Ge'ez", fontSize = 12.sp)
                            }

                            Button(
                                onClick = {
                                    val text = "$arabicDisplay in Ge'ez Numerals: $geezDisplay"
                                    val intent = Intent().apply {
                                        action = Intent.ACTION_SEND
                                        putExtra(Intent.EXTRA_TEXT, text)
                                        type = "text/plain"
                                    }
                                    context.startActivity(Intent.createChooser(intent, "Share Ge'ez Numeral"))
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

        // 4. INTERACTIVE REFERENCE CHART
        item {
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Ge'ez Numerals Chart",
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.5.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "Tap any symbol to convert or insert immediately",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        geezReferenceList.chunked(4).forEach { rowItems ->
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                rowItems.forEach { item ->
                                    Surface(
                                        shape = RoundedCornerShape(12.dp),
                                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f),
                                        modifier = Modifier
                                            .weight(1f)
                                            .clip(RoundedCornerShape(12.dp))
                                            .clickable {
                                                arabicInput = item.value
                                                geezInputText = if (isArabicToGeez) item.symbol else geezInputText + item.symbol
                                                Toast.makeText(context, "${item.nameGeez} (${item.value})", Toast.LENGTH_SHORT).show()
                                            }
                                    ) {
                                        Column(
                                            modifier = Modifier.padding(8.dp),
                                            horizontalAlignment = Alignment.CenterHorizontally
                                        ) {
                                            Text(
                                                text = item.symbol,
                                                fontSize = 20.sp,
                                                fontWeight = FontWeight.ExtraBold,
                                                color = MaterialTheme.colorScheme.primary
                                            )
                                            Text(
                                                text = item.value.toString(),
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = MaterialTheme.colorScheme.onSurface
                                            )
                                            Text(
                                                text = item.nameGeez,
                                                fontSize = 9.5.sp,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
