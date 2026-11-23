package com.example.calendar.ui.screens.holidays

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

@Composable
fun GreetingCardStudioTab(
    viewModel: MainViewModel,
    preSelectedHoliday: HolidayEngine.Holiday? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    data class HolidayPreset(
        val key: String,
        val titleAmharic: String,
        val titleEnglish: String,
        val defaultBlessing: String,
        val defaultRecipient: String,
        val symbol: String
    )

    val presets = remember {
        listOf(
            HolidayPreset(
                "enkutatash",
                "እንቁጣጣሽ (አዲስ ዓመት)",
                "Enkutatash (New Year)",
                "እንኳን ከአሮጌው ዓመት ወደ አዲሱ ዓመት በሰላምና በጤና አሸጋገራችሁ! አዲሱ ዓመት የሰላም፣ የፍቅርና የዕድገት ይሁንላችሁ! 🌼✨",
                "ውድ ቤተሰቦቼና ወዳጆቼ",
                "🌼"
            ),
            HolidayPreset(
                "meskel",
                "መስቀል (ደመራ)",
                "Meskel (Demera)",
                "እንኳን ለብርሃነ መስቀሉና ለደመራ በዓል በሰላም አደረሳችሁ! የመስቀሉ ፍቅርና በረከት ከሁላችን ጋር ይሁን! 🔥✝️",
                "ውድ ወገኖቼ",
                "✝️"
            ),
            HolidayPreset(
                "genna",
                "ገና (የጌታችን ልደት)",
                "Genna (Christmas)",
                "እንኳን ለጌታችን ለመድኃኒታችን ለኢየሱስ ክርስቶስ የልደት በዓል በሰላም አደረሳችሁ! መልካም የገና በዓል! 🎄✨",
                "የተወደዳችሁ ቤተሰቦች",
                "🎄"
            ),
            HolidayPreset(
                "timket",
                "ጥምቀት (ኤጲፋንያ)",
                "Timket (Epiphany)",
                "እንኳን ለብርሃነ ጥምቀቱ በሰላም አደረሳችሁ! ጥምቀቱ የሰላምና የበረከት ይሁንልን! 🕊️💧",
                "ውድ ቤተሰቦቼ",
                "🕊️"
            ),
            HolidayPreset(
                "fasika",
                "ፋሲካ (ትንሣኤ)",
                "Fasika (Easter)",
                "ክርስቶስ ተንሥአ እሙታን! እንኳን ለብርሃነ ትንሣኤው በሰላም አደረሳችሁ! መልካም የትንሣኤ በዓል! 🌸🕯️",
                "ውድ ቤተሰቦቼ",
                "🌸"
            ),
            HolidayPreset(
                "eid_fitr",
                "ዒድ አል-ፊጥር",
                "Eid al-Fitr",
                "ዒድ ሙባረክ! ተቀበለላሁ ሚና ወሚንኩም ሷሊሐል አዕማል! እንኳን ለዒድ አል-ፊጥር በዓል በሰላም አደረሳችሁ! 🌙✨",
                "ውድ ወንድም እህቶቼ",
                "🌙"
            ),
            HolidayPreset(
                "eid_adha",
                "ዒድ አል-አድሃ (አረፋ)",
                "Eid al-Adha",
                "መልካም የአረፋ በዓል! ዒድ ሙባረክ! የሰላም፣ የደስታና የጤና በዓል ይሁንላችሁ! 🐑✨",
                "ውድ ቤተሰቦቼ",
                "🐑"
            ),
            HolidayPreset(
                "irreecha",
                "ኢሬቻ (የምስጋና በዓል)",
                "Irreechaa (Thanksgiving)",
                "Baga ayyaana Irreechaa nagaan geessan! እንኳን ለኢሬቻ የምስጋና በዓል በሰላም አደረሳችሁ! 🌾🌿",
                "Hawaasa kabajamoo",
                "🌾"
            )
        )
    }

    var selectedPresetIndex by remember {
        val initialIndex = if (preSelectedHoliday != null) {
            val idx = presets.indexOfFirst {
                it.titleAmharic.contains(preSelectedHoliday.titleAmharic) ||
                        preSelectedHoliday.titleEnglish.contains(it.titleEnglish)
            }
            if (idx >= 0) idx else 0
        } else 0
        mutableIntStateOf(initialIndex)
    }

    val activePreset = presets[selectedPresetIndex]

    var recipientName by remember(activePreset) { mutableStateOf(activePreset.defaultRecipient) }
    var customMessage by remember(activePreset) { mutableStateOf(activePreset.defaultBlessing) }

    data class ThemeColor(val name: String, val gradient: List<Color>, val accentColor: Color)

    val themes = remember {
        listOf(
            ThemeColor("Imperial Gold", listOf(Color(0xFF06221A), Color(0xFF0B1526), Color(0xFF060C16)), Color(0xFFF59E0B)),
            ThemeColor("Midnight Blue", listOf(Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)), Color(0xFF38BDF8)),
            ThemeColor("Demera Crimson", listOf(Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFF2B0606)), Color(0xFFFBBF24)),
            ThemeColor("Adey Yellow", listOf(Color(0xFF78350F), Color(0xFF92400E), Color(0xFF451A03)), Color(0xFFFCD34D)),
            ThemeColor("Emerald Green", listOf(Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF022C22)), Color(0xFF6EE7B7))
        )
    }

    var selectedThemeIndex by remember { mutableIntStateOf(0) }
    val activeTheme = themes[selectedThemeIndex]

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 10.dp, bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // 1. HOLIDAY PRESET SELECTOR
        item {
            Column {
                Text(
                    text = "Select Holiday Celebration (የበዓል ምርጫ):",
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
                    presets.forEachIndexed { index, preset ->
                        FilterChip(
                            selected = selectedPresetIndex == index,
                            onClick = { selectedPresetIndex = index },
                            label = { Text("${preset.symbol} ${preset.titleEnglish}", fontSize = 11.sp, fontWeight = FontWeight.SemiBold) }
                        )
                    }
                }
            }
        }

        // 2. THEME COLOR PICKER
        item {
            Column {
                Text(
                    text = "Card Theme Style (የካርድ ቀለም ስልት):",
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    themes.forEachIndexed { index, theme ->
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = theme.gradient[1],
                            border = androidx.compose.foundation.BorderStroke(
                                if (selectedThemeIndex == index) 2.dp else 1.dp,
                                if (selectedThemeIndex == index) Color.White else theme.accentColor.copy(alpha = 0.5f)
                            ),
                            modifier = Modifier
                                .weight(1f)
                                .height(38.dp)
                                .clickable { selectedThemeIndex = index }
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                if (selectedThemeIndex == index) {
                                    Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                } else {
                                    Text(
                                        text = theme.name.take(3),
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = theme.accentColor
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. EDITABLE INPUT FIELDS
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    OutlinedTextField(
                        value = recipientName,
                        onValueChange = { recipientName = it },
                        label = { Text("To / Recipient (ለማን)") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    OutlinedTextField(
                        value = customMessage,
                        onValueChange = { customMessage = it },
                        label = { Text("Holiday Greeting Blessing (የእንኳን አደረሳችሁ መልእክት)") },
                        maxLines = 4,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }

        // 4. LIVE CARD PREVIEW
        item {
            Column {
                Text(
                    text = "Live Card Preview (የካርዱ ቅድመ-እይታ):",
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(8.dp))

                Card(
                    shape = RoundedCornerShape(22.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                Brush.verticalGradient(
                                    colors = activeTheme.gradient
                                )
                            )
                            .border(
                                2.dp,
                                activeTheme.accentColor.copy(alpha = 0.6f),
                                RoundedCornerShape(22.dp)
                            )
                            .padding(20.dp)
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            // Top Ethiopian Tricolor Ribbon
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth(0.5f)
                                    .height(3.dp)
                                    .clip(RoundedCornerShape(2.dp))
                            ) {
                                Box(modifier = Modifier.weight(1f).fillMaxSize().background(Color(0xFF10B981)))
                                Box(modifier = Modifier.weight(1f).fillMaxSize().background(Color(0xFFFBBF24)))
                                Box(modifier = Modifier.weight(1f).fillMaxSize().background(Color(0xFFEF4444)))
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Text(
                                text = activePreset.symbol,
                                fontSize = 36.sp
                            )

                            Spacer(modifier = Modifier.height(6.dp))

                            Text(
                                text = activePreset.titleAmharic,
                                fontSize = 21.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = activeTheme.accentColor,
                                textAlign = TextAlign.Center
                            )

                            Text(
                                text = activePreset.titleEnglish,
                                fontSize = 13.5.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White.copy(alpha = 0.85f),
                                textAlign = TextAlign.Center
                            )

                            Spacer(modifier = Modifier.height(14.dp))

                            // Recipient pill
                            if (recipientName.isNotEmpty()) {
                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = Color.Black.copy(alpha = 0.3f),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, activeTheme.accentColor.copy(alpha = 0.4f))
                                ) {
                                    Text(
                                        text = "ለ $recipientName",
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 5.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.height(12.dp))
                            }

                            // Custom message body
                            Text(
                                text = customMessage,
                                fontSize = 14.5.sp,
                                lineHeight = 21.sp,
                                fontWeight = FontWeight.Medium,
                                color = Color(0xFFF8FAFC),
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(horizontal = 10.dp)
                            )

                            Spacer(modifier = Modifier.height(16.dp))

                            // Footer: EthioCal Pro badge & Year
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(0.8f)
                                    .height(1.dp)
                                    .background(activeTheme.accentColor.copy(alpha = 0.3f))
                            )
                            Spacer(modifier = Modifier.height(8.dp))

                            Text(
                                text = "🇪🇹 EthioCal Pro • ${todayEth.year} ዓ.ም",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = activeTheme.accentColor.copy(alpha = 0.9f)
                            )
                        }
                    }
                }
            }
        }

        // 5. SHARE & COPY ACTION BUTTONS
        item {
            val shareableText = buildString {
                appendLine("✨ ${activePreset.symbol} ${activePreset.titleAmharic} (${activePreset.titleEnglish}) ✨")
                if (recipientName.isNotEmpty()) {
                    appendLine("ለ: $recipientName")
                }
                appendLine()
                appendLine(customMessage)
                appendLine()
                appendLine("🇪🇹 መልካም በዓል! በEthioCal Pro የተዘጋጀ።")
            }

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = {
                        val intent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_TEXT, shareableText)
                            type = "text/plain"
                        }
                        context.startActivity(Intent.createChooser(intent, "Share Holiday Greeting"))
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = activeTheme.accentColor),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.Share, contentDescription = null, tint = Color.Black, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Share Greeting Card via WhatsApp / Telegram / SMS",
                        fontSize = 12.5.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }

                OutlinedButton(
                    onClick = {
                        val clip = ClipData.newPlainText("Holiday Greeting", shareableText)
                        (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                        Toast.makeText(context, "Greeting text copied to clipboard!", Toast.LENGTH_SHORT).show()
                    },
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Copy Greeting Text to Clipboard", fontSize = 12.sp)
                }
            }
        }
    }
}
