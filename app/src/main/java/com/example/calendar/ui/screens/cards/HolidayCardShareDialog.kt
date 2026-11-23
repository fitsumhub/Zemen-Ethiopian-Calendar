package com.example.calendar.ui.screens.cards

import android.content.Intent
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings

@Composable
fun HolidayCardShareDialog(
    currentDate: EthiopianDate,
    currentLanguage: AppLanguage,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val dow = EthiopianCalendarEngine.getDayOfWeek(currentDate)
    val gDate = EthiopianCalendarEngine.toGregorian(currentDate)
    val monthName = LocaleStrings.getMonthName(currentDate.month, currentLanguage)
    val dayText = currentDate.day.toString()

    var customMessage by remember {
        mutableStateOf("እንኳን ለዚህ የተቀደሰ ቀን በሰላም አደረሳችሁ! መልካም ዕለት ይሁንላችሁ! 🇪🇹✨")
    }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 8.dp,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "የበዓል እና የዕለት ካርድ (Share Greeting)",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    IconButton(onClick = onDismiss, modifier = Modifier.size(36.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // The Beautiful Rendered Card
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(18.dp))
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color(0xFF0F2027),
                                    Color(0xFF203A43),
                                    Color(0xFF2C5364)
                                )
                            )
                        )
                        .border(
                            width = 1.5.dp,
                            brush = Brush.horizontalGradient(
                                listOf(Color(0xFF0F9D58), Color(0xFFF4B400), Color(0xFFDB4437))
                            ),
                            shape = RoundedCornerShape(18.dp)
                        )
                        .padding(20.dp)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Ethiopian Flag ribbon
                        Row(
                            modifier = Modifier
                                .height(4.dp)
                                .fillMaxWidth(0.6f)
                                .clip(RoundedCornerShape(2.dp))
                        ) {
                            Box(modifier = Modifier.weight(1f).background(Color(0xFF0F9D58)))
                            Box(modifier = Modifier.weight(1f).background(Color(0xFFF4B400)))
                            Box(modifier = Modifier.weight(1f).background(Color(0xFFDB4437)))
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // App Label
                        Text(
                            text = "🇪🇹 EthioCal Pro",
                            color = Color(0xFFFBBF24),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            letterSpacing = 1.5.sp
                        )

                        Spacer(modifier = Modifier.height(10.dp))

                        // Big Ethiopian Date
                        Text(
                            text = "$monthName $dayText",
                            color = Color(0xFFFEF08A),
                            fontSize = 26.sp,
                            fontWeight = FontWeight.ExtraBold,
                            textAlign = TextAlign.Center
                        )

                        Text(
                            text = "${currentDate.year} ዓ.ም • ${LocaleStrings.getWeekdayLong(dow, currentLanguage)}",
                            color = Color.White,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium
                        )

                        Spacer(modifier = Modifier.height(6.dp))

                        Text(
                            text = "${gDate.day} / ${gDate.month} / ${gDate.year} G.C.",
                            color = Color(0xFF94A3B8),
                            fontSize = 12.sp
                        )

                        Spacer(modifier = Modifier.height(14.dp))

                        // Message Box
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0x22FFFFFF))
                                .padding(12.dp)
                        ) {
                            Text(
                                text = customMessage,
                                color = Color.White,
                                fontSize = 14.sp,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Custom Message Input
                OutlinedTextField(
                    value = customMessage,
                    onValueChange = { customMessage = it },
                    label = { Text("የመልእክት ጽሑፍ (Custom Message)") },
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Share Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("ተመለስ (Close)")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = {
                            val shareBody = """
                                🇪🇹 Ethiopian Calendar Pro
                                
                                📅 $monthName $dayText፣ ${currentDate.year} ዓ.ም
                                📆 ${LocaleStrings.getWeekdayLong(dow, currentLanguage)} | ${gDate.day}/${gDate.month}/${gDate.year} G.C.
                                
                                $customMessage
                                
                                የተላከው ከ EthioCal Pro
                            """.trimIndent()

                            val sendIntent = Intent().apply {
                                action = Intent.ACTION_SEND
                                putExtra(Intent.EXTRA_TEXT, shareBody)
                                type = "text/plain"
                            }
                            context.startActivity(Intent.createChooser(sendIntent, "Share Greeting Card"))
                            onDismiss()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        modifier = Modifier.testTag("share_greeting_button")
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("አጋራ (Share)")
                    }
                }
            }
        }
    }
}
