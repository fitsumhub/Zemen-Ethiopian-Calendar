package com.example.calendar.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector

enum class NavScreen(
    val route: String,
    val stringKey: String,
    val icon: ImageVector
) {
    HOME("home", "nav_home", Icons.Default.Home),
    CALENDAR("calendar", "nav_calendar", Icons.Default.CalendarMonth),
    CONVERTER("converter", "nav_converter", Icons.Default.Calculate),
    HOLIDAYS("holidays", "nav_holidays", Icons.Default.NotificationsActive),
    EVENTS("events", "nav_events", Icons.Default.Event),
    SETTINGS("settings", "nav_more", Icons.Default.Settings)
}
