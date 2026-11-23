package com.example.calendar.ui.screens.holidays

import android.content.Intent
import android.widget.Toast
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
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

@Composable
fun MonthlySaintsTab(
    viewModel: MainViewModel,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian

    var searchQuery by remember { mutableStateOf("") }

    val todaySaint = remember(todayEth.day) {
        HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == todayEth.day }
            ?: HolidayEngine.MONTHLY_SAINTS.first()
    }

    val filteredSaints = remember(searchQuery) {
        if (searchQuery.isEmpty()) {
            HolidayEngine.MONTHLY_SAINTS
        } else {
            HolidayEngine.MONTHLY_SAINTS.filter { s ->
                s.day.toString() == searchQuery.trim() ||
                        s.nameAmharic.contains(searchQuery, ignoreCase = true) ||
                        s.nameEnglish.contains(searchQuery, ignoreCase = true) ||
                        s.nameOromo.contains(searchQuery, ignoreCase = true) ||
                        s.nameTigrinya.contains(searchQuery, ignoreCase = true) ||
                        s.significance.contains(searchQuery, ignoreCase = true)
            }
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 10.dp, bottom = 80.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // 1. TODAY'S MONTHLY SAINT HERO CARD
        item {
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF0F1B2C)),
                border = androidx.compose.foundation.BorderStroke(1.2.dp, Color(0xFFF59E0B).copy(alpha = 0.5f)),
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
                            Text("⛪", fontSize = 16.sp)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "TODAY'S TABOT & SAINT (የዕለቱ ታቦት / ቅዱስ)",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFFF59E0B)
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = Color(0xFFF59E0B).copy(alpha = 0.2f),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF59E0B).copy(alpha = 0.45f))
                        ) {
                            Text(
                                text = "DAY ${todayEth.day} (ቀን ${todayEth.day})",
                                fontSize = 10.5.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color(0xFFF59E0B),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = todaySaint.nameAmharic,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White
                    )
                    Text(
                        text = todaySaint.nameEnglish,
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFFBBF24)
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = todaySaint.significance,
                        fontSize = 12.sp,
                        color = Color(0xFFE2E8F0),
                        lineHeight = 16.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = {
                                val text = "🕊️ እንኳን ለ${todaySaint.nameAmharic} (${todaySaint.nameEnglish}) ወርሃዊ በዓል በሰላም አደረሳችሁ!\n" +
                                        "የቅዱሱ ረድኤትና በረከት ከሁላችን ጋር ይሁን። አሜን! 🇪🇹✨"
                                val intent = Intent().apply {
                                    action = Intent.ACTION_SEND
                                    putExtra(Intent.EXTRA_TEXT, text)
                                    type = "text/plain"
                                }
                                context.startActivity(Intent.createChooser(intent, "Share Saint's Blessing"))
                            },
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF59E0B)),
                            modifier = Modifier.weight(1.2f)
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null, tint = Color.Black, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Share Saint's Blessing", fontSize = 11.5.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        }

                        if (onNavigateToCalendar != null) {
                            OutlinedButton(
                                onClick = { onNavigateToCalendar(todayEth) },
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.weight(0.9f)
                            ) {
                                Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("In Calendar", fontSize = 11.5.sp, color = Color.White)
                            }
                        }
                    }
                }
            }
        }

        // 2. SEARCH BAR FOR SAINTS
        item {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search by Saint name or Day number (1-30)...", fontSize = 12.5.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp)) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }, modifier = Modifier.size(24.dp)) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear", modifier = Modifier.size(16.dp))
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )
        }

        // 3. DIRECTORY HEADER
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Complete 1-30 Monthly Tabot & Saints Calendar (የወር ጽላቶች)",
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "${filteredSaints.size} days",
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // 4. SAINTS LIST (1-30)
        items(filteredSaints, key = { it.day }) { saint ->
            val isTodaySaint = saint.day == todayEth.day

            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (isTodaySaint) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f) else MaterialTheme.colorScheme.surface
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    if (isTodaySaint) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Day Circle Badge
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = if (isTodaySaint) MaterialTheme.colorScheme.primary else Color(0xFF1E293B),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp,
                            if (isTodaySaint) MaterialTheme.colorScheme.primary else Color(0xFFF59E0B).copy(alpha = 0.4f)
                        ),
                        modifier = Modifier.size(42.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = saint.day.toString(),
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 15.sp,
                                color = if (isTodaySaint) MaterialTheme.colorScheme.onPrimary else Color(0xFFF59E0B)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(12.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = saint.nameAmharic,
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.5.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            if (isTodaySaint) {
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    shape = RoundedCornerShape(4.dp),
                                    color = Color(0xFF10B981)
                                ) {
                                    Text(
                                        text = "TODAY (ዛሬ)",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                    )
                                }
                            }
                        }

                        Text(
                            text = saint.nameEnglish,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.primary
                        )

                        Text(
                            text = saint.significance,
                            fontSize = 11.5.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 15.sp
                        )
                    }

                    IconButton(
                        onClick = {
                            val text = "🕊️ እንኳን ለ${saint.nameAmharic} (${saint.nameEnglish}) ወርሃዊ መታሰቢያ ቀን በሰላም አደረሳችሁ!\n" +
                                    "የቅዱሱ በረከትና ረድኤት ከሁላችን ጋር ይሁን! 🇪🇹"
                            val intent = Intent().apply {
                                action = Intent.ACTION_SEND
                                putExtra(Intent.EXTRA_TEXT, text)
                                type = "text/plain"
                            }
                            context.startActivity(Intent.createChooser(intent, "Share Saint Blessing"))
                        },
                        modifier = Modifier.size(34.dp)
                    ) {
                        Icon(
                            Icons.Default.Share,
                            contentDescription = "Share",
                            tint = Color(0xFFF59E0B),
                            modifier = Modifier.size(17.dp)
                        )
                    }
                }
            }
        }
    }
}
