package com.example.calendar.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.dataStore by preferencesDataStore(name = "ethiocal_preferences")

class UserPreferencesRepository(private val context: Context) {

    companion object {
        val KEY_LANGUAGE = stringPreferencesKey("pref_language")
        val KEY_NUMERAL_TYPE = stringPreferencesKey("pref_numeral_type")
        val KEY_THEME = stringPreferencesKey("pref_theme")
        val KEY_ACCENT = stringPreferencesKey("pref_accent")
        val KEY_FIRST_DAY_WEEK = stringPreferencesKey("pref_first_day_week")
        val KEY_SHOW_FASTING = booleanPreferencesKey("pref_show_fasting")
        val KEY_SHOW_SAINTS = booleanPreferencesKey("pref_show_saints")
        val KEY_NOTIFICATIONS = booleanPreferencesKey("pref_notifications")
        val KEY_CALENDAR_FORMAT = stringPreferencesKey("pref_calendar_format")
        val KEY_ONBOARDING_COMPLETED = booleanPreferencesKey("pref_onboarding_completed")
    }

    data class UserSettings(
        val language: String = "ENGLISH", // ENGLISH, AMHARIC, OROMO, TIGRINYA, FRENCH
        val numeralType: String = "ARABIC", // ARABIC, GEEZ
        val calendarFormat: String = "ETHIOPIAN", // ETHIOPIAN, GREGORIAN
        val themeMode: String = "SYSTEM", // SYSTEM, LIGHT, DARK, AMOLED
        val accentPalette: String = "GOLD_EMERALD", // GOLD_EMERALD, ROYAL_INDIGO, CRIMSON, TERRACOTTA
        val firstDayOfWeek: String = "SUNDAY", // SUNDAY, MONDAY
        val showFasting: Boolean = true,
        val showMonthlySaints: Boolean = true,
        val notificationsEnabled: Boolean = true,
        val onboardingCompleted: Boolean = false
    )

    val userSettingsFlow: Flow<UserSettings> = context.dataStore.data.map { prefs ->
        UserSettings(
            language = prefs[KEY_LANGUAGE] ?: "ENGLISH",
            numeralType = prefs[KEY_NUMERAL_TYPE] ?: "ARABIC",
            calendarFormat = prefs[KEY_CALENDAR_FORMAT] ?: "ETHIOPIAN",
            themeMode = prefs[KEY_THEME] ?: "SYSTEM",
            accentPalette = prefs[KEY_ACCENT] ?: "GOLD_EMERALD",
            firstDayOfWeek = prefs[KEY_FIRST_DAY_WEEK] ?: "SUNDAY",
            showFasting = prefs[KEY_SHOW_FASTING] ?: true,
            showMonthlySaints = prefs[KEY_SHOW_SAINTS] ?: true,
            notificationsEnabled = prefs[KEY_NOTIFICATIONS] ?: true,
            onboardingCompleted = prefs[KEY_ONBOARDING_COMPLETED] ?: false
        )
    }

    suspend fun setOnboardingCompleted(completed: Boolean) {
        context.dataStore.edit { it[KEY_ONBOARDING_COMPLETED] = completed }
    }

    suspend fun setLanguage(language: String) {
        context.dataStore.edit { it[KEY_LANGUAGE] = language }
    }

    suspend fun setNumeralType(numeralType: String) {
        context.dataStore.edit { it[KEY_NUMERAL_TYPE] = numeralType }
    }

    suspend fun setThemeMode(mode: String) {
        context.dataStore.edit { it[KEY_THEME] = mode }
    }

    suspend fun setAccentPalette(palette: String) {
        context.dataStore.edit { it[KEY_ACCENT] = palette }
    }

    suspend fun setFirstDayOfWeek(firstDay: String) {
        context.dataStore.edit { it[KEY_FIRST_DAY_WEEK] = firstDay }
    }

    suspend fun setShowFasting(enabled: Boolean) {
        context.dataStore.edit { it[KEY_SHOW_FASTING] = enabled }
    }

    suspend fun setShowMonthlySaints(enabled: Boolean) {
        context.dataStore.edit { it[KEY_SHOW_SAINTS] = enabled }
    }

    suspend fun setNotificationsEnabled(enabled: Boolean) {
        context.dataStore.edit { it[KEY_NOTIFICATIONS] = enabled }
    }

    suspend fun setCalendarFormat(format: String) {
        context.dataStore.edit { it[KEY_CALENDAR_FORMAT] = format }
    }
}
