package com.example.calendar.ui.screens.onboarding

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Church
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.R
import com.example.calendar.ui.MainViewModel
import kotlinx.coroutines.launch

/**
 * Premium Onboarding Suite for EthioCal Pro.
 * Provides a captivating first-run introduction to the Ethiopian Calendar,
 * European & World Converter, and rapid personalization options.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun OnboardingScreen(
    viewModel: MainViewModel,
    onFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    val pagerState = rememberPagerState(pageCount = { 3 })
    val coroutineScope = rememberCoroutineScope()

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF06181B),
                        Color(0xFF0B1424),
                        Color(0xFF040A12)
                    )
                )
            )
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp, vertical = 12.dp)
        ) {
            // Top Action Bar with Skip Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Subtle logo text tag
                Row(verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.foundation.Image(
                        painter = painterResource(id = R.drawable.ic_ethiocal_logo),
                        contentDescription = "EthioCal Emblem",
                        modifier = Modifier.size(28.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "EthioCal Pro",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color(0xFFF59E0B)
                    )
                }

                if (pagerState.currentPage < 2) {
                    TextButton(
                        onClick = {
                            viewModel.setOnboardingCompleted(true)
                            onFinish()
                        },
                        modifier = Modifier.testTag("skip_onboarding_button")
                    ) {
                        Text(
                            text = "Skip (ዝለል)",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                } else {
                    Spacer(modifier = Modifier.width(48.dp))
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Main Pager Content
            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) { page ->
                when (page) {
                    0 -> OnboardingPageWelcome()
                    1 -> OnboardingPageConverter()
                    2 -> OnboardingPageCustomization(viewModel = viewModel)
                }
            }

            // Bottom Navigation Controls
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Animated Page Indicator Pills
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(bottom = 18.dp)
                ) {
                    repeat(3) { index ->
                        val isSelected = pagerState.currentPage == index
                        val animatedWidth by animateDpAsState(
                            targetValue = if (isSelected) 28.dp else 8.dp,
                            animationSpec = tween(durationMillis = 300, easing = FastOutSlowInEasing),
                            label = "indicator_width"
                        )
                        Box(
                            modifier = Modifier
                                .padding(horizontal = 4.dp)
                                .height(8.dp)
                                .width(animatedWidth)
                                .clip(RoundedCornerShape(4.dp))
                                .background(
                                    if (isSelected) Color(0xFFF59E0B)
                                    else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                                )
                        )
                    }
                }

                // Action Buttons Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (pagerState.currentPage > 0) {
                        OutlinedButton(
                            onClick = {
                                coroutineScope.launch {
                                    pagerState.animateScrollToPage(pagerState.currentPage - 1)
                                }
                            },
                            shape = RoundedCornerShape(14.dp),
                            modifier = Modifier.weight(1f).height(50.dp)
                        ) {
                            Text("Back (ተመለስ)", fontSize = 13.sp)
                        }
                    }

                    Button(
                        onClick = {
                            if (pagerState.currentPage < 2) {
                                coroutineScope.launch {
                                    pagerState.animateScrollToPage(pagerState.currentPage + 1)
                                }
                            } else {
                                viewModel.setOnboardingCompleted(true)
                                onFinish()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFF59E0B),
                            contentColor = Color(0xFF1E1303)
                        ),
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier
                            .weight(if (pagerState.currentPage > 0) 1.5f else 1f)
                            .height(50.dp)
                            .testTag("onboarding_next_button")
                    ) {
                        Text(
                            text = if (pagerState.currentPage < 2) "Continue (ቀጥል)" else "Get Started (መተግበሪያውን ጀምር)",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(
                            imageVector = if (pagerState.currentPage < 2) Icons.AutoMirrored.Filled.ArrowForward else Icons.Default.Check,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun OnboardingPageWelcome() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // High-fidelity central emblem
        Surface(
            shape = CircleShape,
            color = Color(0xFF0F2328),
            border = androidx.compose.foundation.BorderStroke(2.dp, Color(0xFFF59E0B)),
            shadowElevation = 8.dp,
            modifier = Modifier.size(110.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                androidx.compose.foundation.Image(
                    painter = painterResource(id = R.drawable.ic_ethiocal_logo),
                    contentDescription = "EthioCal Logo",
                    modifier = Modifier.size(92.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Badge: 13 Months of Sunshine
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = Color(0xFFF59E0B).copy(alpha = 0.16f),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF59E0B).copy(alpha = 0.4f))
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("🇪🇹", fontSize = 14.sp)
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "13 Months of Sunshine (13 ወራት ፀጋ)",
                    fontSize = 11.5.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFF59E0B)
                )
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        Text(
            text = "Welcome to EthioCal Pro",
            fontSize = 24.sp,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )

        Text(
            text = "እንኳን ወደ ኢትዮጵያ የቀን መቁጠሪያ በደህና መጡ",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(18.dp))

        // Value Proposition Cards
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            FeatureHighlightItem(
                icon = Icons.Default.WbSunny,
                title = "13 Months Ethiopian Calendar",
                description = "Meskerem to Pagume with 5/6 leap day rules, accurate 7-8 years calculation."
            )
            FeatureHighlightItem(
                icon = Icons.Default.Church,
                title = "Bahire Hasab & Feasts",
                description = "Automatic computus calculation for Easter, Nineveh, Great Lent & daily saints."
            )
            FeatureHighlightItem(
                icon = Icons.Default.NotificationsActive,
                title = "Holiday & Event Reminders",
                description = "Reliable alarms for national holidays, fasting periods, and personal events."
            )
        }
    }
}

@Composable
private fun OnboardingPageConverter() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Graphic Card representing World Connectivity
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = Color(0xFF0F1B2C),
            border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFF38BDF8).copy(alpha = 0.5f)),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp)
        ) {
            Column(
                modifier = Modifier.padding(18.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Addis Ababa
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("🇪🇹", fontSize = 28.sp)
                        Text("Addis Ababa", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFFF59E0B))
                        Text("06:00 ቀን (12:00)", fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }

                    // Exchange / Arrow Badge
                    Surface(
                        shape = CircleShape,
                        color = Color(0xFF1E293B),
                        modifier = Modifier.size(36.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text("⇄", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF38BDF8))
                        }
                    }

                    // Europe / World
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Row { Text("🇬🇧 "); Text("🇩🇪 "); Text("🇺🇸") }
                        Text("Europe & World", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF38BDF8))
                        Text("London • Berlin • DC", fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Flags ribbon
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    listOf("🇬🇧 London", "🇩🇪 Berlin", "🇫🇷 Paris", "🇺🇸 Washington", "🇦🇪 Dubai").forEach { city ->
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        ) {
                            Text(
                                text = city,
                                fontSize = 9.5.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "Europe & World Converter",
            fontSize = 22.sp,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )

        Text(
            text = "ቀን እና የዓለም ከተሞች ሰዓታት ቀያሪ",
            fontSize = 13.5.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(18.dp))

        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            FeatureHighlightItem(
                icon = Icons.Default.Public,
                title = "European & World Date Formats",
                description = "Convert Ethiopian dates directly to EU standard, UK, Germany, USA, and ISO 8601."
            )
            FeatureHighlightItem(
                icon = Icons.Default.Public,
                title = "World & Europe Timezone Grid",
                description = "Compare Ethiopian traditional 12h clock with London, Berlin, Dubai, New York & Sydney."
            )
            FeatureHighlightItem(
                icon = Icons.Default.Church,
                title = "Julian & Coptic Sister Calendars",
                description = "Compare with Eastern Orthodox Julian (Old Style) and Egyptian Coptic calendars."
            )
        }
    }
}

@Composable
private fun OnboardingPageCustomization(viewModel: MainViewModel) {
    val currentLang = viewModel.currentAppLanguage()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Surface(
            shape = CircleShape,
            color = Color(0xFF102E24),
            border = androidx.compose.foundation.BorderStroke(2.dp, Color(0xFF10B981)),
            modifier = Modifier.size(64.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = null,
                    tint = Color(0xFF10B981),
                    modifier = Modifier.size(32.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Personalize Your EthioCal",
            fontSize = 22.sp,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )

        Text(
            text = "ቋንቋዎን እና የቁጥር አጠቃቀም ይምረጡ",
            fontSize = 13.5.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Preference Selection Card
        Card(
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF0F1B2C)),
            border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                // Language Selection
                Text(
                    text = "Select Language (ቋንቋ ይምረጡ):",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFF59E0B)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    listOf(
                        "ENGLISH" to "English",
                        "AMHARIC" to "አማርኛ",
                        "OROMO" to "Oromoo",
                        "TIGRINYA" to "ትግርኛ"
                    ).forEach { (code, label) ->
                        val selected = viewModel.userSettings.value.language == code
                        FilterChip(
                            selected = selected,
                            onClick = { viewModel.setLanguage(code) },
                            label = { Text(label, fontSize = 11.sp, fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Numeral Type
                Text(
                    text = "Numeral Display (የቁጥር ዓይነት):",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFF59E0B)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val currentNum = viewModel.userSettings.value.numeralType
                    listOf(
                        "ARABIC" to "Arabic (1, 2, 3...)",
                        "GEEZ" to "Ge'ez (፩, ፪, ፫...)"
                    ).forEach { (code, label) ->
                        val selected = currentNum == code
                        FilterChip(
                            selected = selected,
                            onClick = { viewModel.setNumeralType(code) },
                            label = { Text(label, fontSize = 11.5.sp, fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FeatureHighlightItem(
    icon: ImageVector,
    title: String,
    description: String
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = Color(0xFF0F1B2C).copy(alpha = 0.8f),
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = Color(0xFFF59E0B).copy(alpha = 0.15f),
                modifier = Modifier.size(38.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = Color(0xFFF59E0B),
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = title,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = description,
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    lineHeight = 15.sp
                )
            }
        }
    }
}
