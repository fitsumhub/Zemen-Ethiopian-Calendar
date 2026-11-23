package com.example.calendar.ui.screens.converter

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Church
import androidx.compose.material.icons.filled.FormatListNumbered
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import com.example.calendar.ui.MainViewModel

/**
 * Unified, High-Craft Converter Suite for Ethiopian Calendar.
 * Features a single clean pill-tab selector with today's dual-date context strip
 * and 6 specialized calculation tools:
 * 1. Date Converter (Ethiopian ⇄ Gregorian)
 * 2. Time Converter (Ethiopian 12h ⇄ Global 24h & World Cities)
 * 3. Age & Difference Calculator
 * 4. Bahire Hasab (Computus & Movable Feasts)
 * 5. Ge'ez Numerals (Arabic ⇄ Ge'ez)
 * 6. World Hub (Country Comparator)
 */
@Composable
fun ConverterScreen(
    viewModel: MainViewModel,
    onNavigateToCalendar: ((EthiopianDate) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    var selectedTab by remember { mutableIntStateOf(0) }
    val currentLang = viewModel.currentAppLanguage()
    val todayEth = viewModel.todayEthiopian
    val todayGreg = viewModel.todayGregorian
    val isGeezScript = currentLang == AppLanguage.AMHARIC || currentLang == AppLanguage.TIGRINYA

    data class TabItem(
        val labelEn: String,
        val labelAm: String,
        val subtitleEn: String,
        val subtitleAm: String,
        val icon: ImageVector
    )

    val tabs = remember {
        listOf(
            TabItem("Date", "ቀን", "Ethiopian ⇄ Gregorian", "ኢትዮጵያ ⇄ ፈረንጅ", Icons.Default.CalendarMonth),
            TabItem("Time", "ሰዓት", "12h Clock & World", "የኢትዮጵያ ሰዓት", Icons.Default.AccessTime),
            TabItem("Age", "ዕድሜ", "Age & Date Span", "ዕድሜ እና ልዩነት", Icons.Default.Cake),
            TabItem("Computus", "ባሕረ ሐሳብ", "Feasts & Fasts", "የበዓላት ቀመር", Icons.Default.Church),
            TabItem("Ge'ez", "ግዕዝ", "Arabic ⇄ Ge'ez", "የግዕዝ አኃዛት", Icons.Default.FormatListNumbered),
            TabItem("World", "ዓለም", "Country Compare", "የሀገራት ንጽጽር", Icons.Default.Public)
        )
    }

    val activeTab = tabs[selectedTab]
    val ethMonthShort = LocaleStrings.getMonthName(todayEth.month, currentLang)

    Column(modifier = modifier.fillMaxSize()) {
        // Unified Converter Header & Single Pill Tab Bar
        Surface(
            tonalElevation = 2.dp,
            color = MaterialTheme.colorScheme.surface,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                // Compact Context Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = if (isGeezScript) "${activeTab.labelAm} • ${activeTab.subtitleAm}" else "${activeTab.labelEn} Converter • ${activeTab.subtitleEn}",
                            fontSize = 13.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }

                    // Live Today Dual-Date Reference Pill
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.65f)
                    ) {
                        Text(
                            text = "$ethMonthShort ${todayEth.day} ⇄ ${todayGreg.day}/${todayGreg.month}/${todayGreg.year}",
                            fontSize = 10.5.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }

                // Single Clean Scrollable Pill Tab Bar
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(start = 14.dp, end = 14.dp, bottom = 10.dp)
                        .testTag("converter_screen_tab_row"),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    tabs.forEachIndexed { index, item ->
                        val isSelected = selectedTab == index
                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = if (isSelected) {
                                MaterialTheme.colorScheme.primary
                            } else {
                                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
                            },
                            border = if (isSelected) {
                                null
                            } else {
                                BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
                            },
                            shadowElevation = if (isSelected) 3.dp else 0.dp,
                            modifier = Modifier
                                .minimumInteractiveComponentSize()
                                .clip(RoundedCornerShape(14.dp))
                                .clickable { selectedTab = index }
                                .testTag("converter_tab_$index")
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                            ) {
                                Icon(
                                    imageVector = item.icon,
                                    contentDescription = item.labelEn,
                                    modifier = Modifier.size(17.dp),
                                    tint = if (isSelected) {
                                        MaterialTheme.colorScheme.onPrimary
                                    } else {
                                        MaterialTheme.colorScheme.primary
                                    }
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = if (isGeezScript) item.labelAm else item.labelEn,
                                    fontSize = 12.5.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) {
                                        MaterialTheme.colorScheme.onPrimary
                                    } else {
                                        MaterialTheme.colorScheme.onSurface
                                    }
                                )
                            }
                        }
                    }
                }

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
                )
            }
        }

        // Animated Tab Content Container
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 14.dp)
        ) {
            AnimatedContent(
                targetState = selectedTab,
                transitionSpec = {
                    val direction = if (targetState > initialState) 1 else -1
                    (slideInHorizontally(animationSpec = tween(220)) { it / 6 * direction } + fadeIn(tween(200)))
                        .togetherWith(slideOutHorizontally(animationSpec = tween(180)) { -it / 6 * direction } + fadeOut(tween(150)))
                },
                label = "ConverterTabContent"
            ) { targetIndex ->
                when (targetIndex) {
                    0 -> DateConverterTab(
                        viewModel = viewModel,
                        currentLang = currentLang,
                        onNavigateToCalendar = onNavigateToCalendar
                    )
                    1 -> TimeConverterTab(
                        currentLang = currentLang
                    )
                    2 -> AgeAndDifferenceTab(
                        viewModel = viewModel,
                        currentLang = currentLang
                    )
                    3 -> BahireHasabTab(
                        viewModel = viewModel,
                        currentLang = currentLang
                    )
                    4 -> GeezNumeralTab(
                        todayEthYear = todayEth.year
                    )
                    5 -> CountryComparatorTab(
                        viewModel = viewModel,
                        currentLang = currentLang
                    )
                }
            }
        }
    }
}
