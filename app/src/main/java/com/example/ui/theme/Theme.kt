package com.example.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private fun createDarkColorScheme(accentPalette: String) = when (accentPalette) {
    "ROYAL_INDIGO" -> darkColorScheme(
        primary = EthioIndigoPrimary,
        onPrimary = Color.White,
        primaryContainer = EthioIndigoDark,
        onPrimaryContainer = EthioIndigoLight,
        secondary = EthioGoldPrimary,
        onSecondary = Color.Black,
        background = DarkBackground,
        surface = DarkSurface,
        surfaceVariant = DarkSurfaceElevated,
        onBackground = DarkTextPrimary,
        onSurface = DarkTextPrimary,
        onSurfaceVariant = DarkTextSecondary
    )
    "CRIMSON" -> darkColorScheme(
        primary = EthioCrimsonPrimary,
        onPrimary = Color.White,
        primaryContainer = EthioCrimsonDark,
        onPrimaryContainer = EthioCrimsonLight,
        secondary = EthioGoldPrimary,
        onSecondary = Color.Black,
        background = DarkBackground,
        surface = DarkSurface,
        surfaceVariant = DarkSurfaceElevated,
        onBackground = DarkTextPrimary,
        onSurface = DarkTextPrimary,
        onSurfaceVariant = DarkTextSecondary
    )
    "TERRACOTTA" -> darkColorScheme(
        primary = EthioTerracottaPrimary,
        onPrimary = Color.White,
        primaryContainer = EthioTerracottaDark,
        onPrimaryContainer = EthioTerracottaLight,
        secondary = EthioEmerald,
        onSecondary = Color.Black,
        background = DarkBackground,
        surface = DarkSurface,
        surfaceVariant = DarkSurfaceElevated,
        onBackground = DarkTextPrimary,
        onSurface = DarkTextPrimary,
        onSurfaceVariant = DarkTextSecondary
    )
    else -> darkColorScheme(
        primary = EthioGoldPrimary,
        onPrimary = Color(0xFF261900),
        primaryContainer = Color(0xFF533B00),
        onPrimaryContainer = EthioGoldLight,
        secondary = EthioEmerald,
        onSecondary = Color.Black,
        secondaryContainer = EthioEmeraldDark,
        onSecondaryContainer = EthioEmeraldLight,
        background = DarkBackground,
        surface = DarkSurface,
        surfaceVariant = DarkSurfaceElevated,
        onBackground = DarkTextPrimary,
        onSurface = DarkTextPrimary,
        onSurfaceVariant = DarkTextSecondary
    )
}

private fun createLightColorScheme(accentPalette: String) = when (accentPalette) {
    "ROYAL_INDIGO" -> lightColorScheme(
        primary = EthioIndigoDark,
        onPrimary = Color.White,
        primaryContainer = EthioIndigoLight,
        onPrimaryContainer = EthioIndigoDark,
        secondary = EthioGoldDark,
        onSecondary = Color.White,
        background = LightBackground,
        surface = LightSurface,
        surfaceVariant = LightSurfaceElevated,
        onBackground = LightTextPrimary,
        onSurface = LightTextPrimary,
        onSurfaceVariant = LightTextSecondary
    )
    "CRIMSON" -> lightColorScheme(
        primary = EthioCrimsonPrimary,
        onPrimary = Color.White,
        primaryContainer = EthioCrimsonLight,
        onPrimaryContainer = EthioCrimsonDark,
        secondary = EthioGoldDark,
        onSecondary = Color.White,
        background = LightBackground,
        surface = LightSurface,
        surfaceVariant = LightSurfaceElevated,
        onBackground = LightTextPrimary,
        onSurface = LightTextPrimary,
        onSurfaceVariant = LightTextSecondary
    )
    "TERRACOTTA" -> lightColorScheme(
        primary = EthioTerracottaPrimary,
        onPrimary = Color.White,
        primaryContainer = EthioTerracottaLight,
        onPrimaryContainer = EthioTerracottaDark,
        secondary = EthioEmeraldDark,
        onSecondary = Color.White,
        background = LightBackground,
        surface = LightSurface,
        surfaceVariant = LightSurfaceElevated,
        onBackground = LightTextPrimary,
        onSurface = LightTextPrimary,
        onSurfaceVariant = LightTextSecondary
    )
    else -> lightColorScheme(
        primary = Color(0xFFB45309), // Warm Deep Amber/Gold for contrast
        onPrimary = Color.White,
        primaryContainer = Color(0xFFFEF3C7),
        onPrimaryContainer = Color(0xFF78350F),
        secondary = EthioEmeraldDark,
        onSecondary = Color.White,
        secondaryContainer = EthioEmeraldLight,
        onSecondaryContainer = Color(0xFF064E3B),
        background = LightBackground,
        surface = LightSurface,
        surfaceVariant = LightSurfaceElevated,
        onBackground = LightTextPrimary,
        onSurface = LightTextPrimary,
        onSurfaceVariant = LightTextSecondary
    )
}

@Composable
fun EthioCalTheme(
    themeMode: String = "SYSTEM",
    accentPalette: String = "GOLD_EMERALD",
    content: @Composable () -> Unit
) {
    val isDark = when (themeMode) {
        "DARK", "AMOLED" -> true
        "LIGHT" -> false
        else -> isSystemInDarkTheme()
    }

    val colorScheme = if (isDark) {
        createDarkColorScheme(accentPalette)
    } else {
        createLightColorScheme(accentPalette)
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
