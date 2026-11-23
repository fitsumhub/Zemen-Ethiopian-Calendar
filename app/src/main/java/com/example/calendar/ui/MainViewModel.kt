package com.example.calendar.ui

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.calendar.data.AndroidCalendarSyncManager
import com.example.calendar.data.AppDatabase
import com.example.calendar.data.EventEntity
import com.example.calendar.data.EventRepository
import com.example.calendar.data.UserPreferencesRepository
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.notification.NotificationScheduler
import com.example.calendar.widget.EthioCalWidgetProvider
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val db = AppDatabase.getDatabase(application)
    private val eventRepository = EventRepository(db.eventDao())
    private val preferencesRepository = UserPreferencesRepository(application)

    init {
        viewModelScope.launch {
            val settings = preferencesRepository.userSettingsFlow.firstOrNull()
            if (settings?.notificationsEnabled == true) {
                val events = eventRepository.allEvents.firstOrNull() ?: emptyList()
                NotificationScheduler.rescheduleAllActiveEvents(getApplication(), events)
            }
        }
    }

    val userSettings: StateFlow<UserPreferencesRepository.UserSettings> =
        preferencesRepository.userSettingsFlow.stateIn(
            scope = viewModelScope,
            started = SharingStarted.Eagerly,
            initialValue = UserPreferencesRepository.UserSettings()
        )

    val todayEthiopian = EthiopianCalendarEngine.todayEthiopian()
    val todayGregorian = EthiopianCalendarEngine.todayGregorian()

    private val _selectedDate = MutableStateFlow(todayEthiopian)
    val selectedDate: StateFlow<EthiopianDate> = _selectedDate.asStateFlow()

    private val _viewYear = MutableStateFlow(todayEthiopian.year)
    val viewYear: StateFlow<Int> = _viewYear.asStateFlow()

    private val _viewMonth = MutableStateFlow(todayEthiopian.month)
    val viewMonth: StateFlow<Int> = _viewMonth.asStateFlow()

    private val _calendarViewMode = MutableStateFlow("MONTH") // MONTH, WEEK, YEAR, DAY
    val calendarViewMode: StateFlow<String> = _calendarViewMode.asStateFlow()

    val allEvents: StateFlow<List<EventEntity>> = eventRepository.allEvents.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    private val _eventSearchQuery = MutableStateFlow("")
    val eventSearchQuery: StateFlow<String> = _eventSearchQuery.asStateFlow()

    private val _eventCategoryFilter = MutableStateFlow("ALL")
    val eventCategoryFilter: StateFlow<String> = _eventCategoryFilter.asStateFlow()

    val filteredEvents: StateFlow<List<EventEntity>> = combine(
        allEvents,
        _eventSearchQuery,
        _eventCategoryFilter
    ) { events, query, category ->
        events.filter { event ->
            val matchesQuery = query.isEmpty() ||
                    event.title.contains(query, ignoreCase = true) ||
                    event.description.contains(query, ignoreCase = true)
            val matchesCategory = category == "ALL" || event.category == category
            matchesQuery && matchesCategory
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val eventsForSelectedDate: StateFlow<List<EventEntity>> = combine(
        allEvents,
        _selectedDate
    ) { events, selected ->
        events.filter { event ->
            eventMatchesDate(event, selected)
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val holidaysForViewYear: StateFlow<List<HolidayEngine.Holiday>> = _viewYear.combine(_viewMonth) { year, _ ->
        HolidayEngine.getHolidaysForYear(year)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), HolidayEngine.getHolidaysForYear(todayEthiopian.year))

    val upcomingHoliday: StateFlow<HolidayEngine.Holiday?> = holidaysForViewYear.combine(_selectedDate) { holidays, _ ->
        val currentYearHolidays = HolidayEngine.getHolidaysForYear(todayEthiopian.year)
        val upcoming = currentYearHolidays.firstOrNull { it.ethiopianDate >= todayEthiopian }
        upcoming ?: HolidayEngine.getHolidaysForYear(todayEthiopian.year + 1).firstOrNull()
    }.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    fun selectDate(date: EthiopianDate) {
        _selectedDate.value = date
        _viewYear.value = date.year
        _viewMonth.value = date.month
    }

    fun nextMonth() {
        if (_viewMonth.value == 13) {
            _viewMonth.value = 1
            _viewYear.value += 1
        } else {
            _viewMonth.value += 1
        }
    }

    fun prevMonth() {
        if (_viewMonth.value == 1) {
            _viewMonth.value = 13
            _viewYear.value -= 1
        } else {
            _viewMonth.value -= 1
        }
    }

    fun nextYear(delta: Int = 1) {
        _viewYear.value += delta
    }

    fun prevYear(delta: Int = 1) {
        _viewYear.value = (_viewYear.value - delta).coerceAtLeast(1)
    }

    fun setYear(year: Int) {
        if (year in 1..9999) {
            _viewYear.value = year
        }
    }

    fun jumpYears(delta: Int) {
        _viewYear.value = (_viewYear.value + delta).coerceAtLeast(1)
    }

    fun setMonthAndYear(year: Int, month: Int) {
        _viewYear.value = year
        _viewMonth.value = month.coerceIn(1, 13)
    }

    fun goToToday() {
        selectDate(todayEthiopian)
    }

    fun setCalendarViewMode(mode: String) {
        _calendarViewMode.value = mode
    }

    fun setSearchQuery(query: String) {
        _eventSearchQuery.value = query
    }

    fun setCategoryFilter(category: String) {
        _eventCategoryFilter.value = category
    }

    fun saveEvent(event: EventEntity) {
        viewModelScope.launch {
            val id = if (event.id == 0L) {
                eventRepository.insert(event)
            } else {
                eventRepository.update(event)
                event.id
            }
            val savedEvent = event.copy(id = id)
            if (userSettings.value.notificationsEnabled && savedEvent.reminderMinutesBefore >= 0 && !savedEvent.isCompleted) {
                NotificationScheduler.scheduleEventReminder(getApplication(), savedEvent)
            } else {
                NotificationScheduler.cancelEventReminder(getApplication(), id)
            }
            EthioCalWidgetProvider.updateAllWidgets(getApplication())
        }
    }

    fun deleteEvent(event: EventEntity) {
        viewModelScope.launch {
            NotificationScheduler.cancelEventReminder(getApplication(), event.id)
            eventRepository.delete(event)
            EthioCalWidgetProvider.updateAllWidgets(getApplication())
        }
    }

    fun toggleEventCompletion(event: EventEntity) {
        viewModelScope.launch {
            val updated = event.copy(isCompleted = !event.isCompleted)
            eventRepository.update(updated)
            if (updated.isCompleted) {
                NotificationScheduler.cancelEventReminder(getApplication(), updated.id)
            } else if (userSettings.value.notificationsEnabled && updated.reminderMinutesBefore >= 0) {
                NotificationScheduler.scheduleEventReminder(getApplication(), updated)
            }
            EthioCalWidgetProvider.updateAllWidgets(getApplication())
        }
    }

    fun syncEventsToDeviceCalendar(context: Context, onResult: (String) -> Unit) {
        viewModelScope.launch {
            val events = allEvents.value
            val result = AndroidCalendarSyncManager.syncAllEventsToDevice(context, events)
            onResult(result.message)
        }
    }

    fun importEventsFromDeviceCalendar(context: Context, onResult: (String) -> Unit) {
        viewModelScope.launch {
            val imported = AndroidCalendarSyncManager.importEventsFromDeviceCalendar(context)
            var count = 0
            val notifyEnabled = userSettings.value.notificationsEnabled
            for (event in imported) {
                val savedId = eventRepository.insert(event)
                if (notifyEnabled && event.reminderMinutesBefore >= 0 && !event.isCompleted) {
                    NotificationScheduler.scheduleEventReminder(getApplication(), event.copy(id = savedId))
                }
                count++
            }
            if (count > 0) {
                EthioCalWidgetProvider.updateAllWidgets(getApplication())
            }
            onResult(if (count > 0) "$count ማስታወሻዎች በተሳካ ሁኔታ ገብተዋል (Imported $count events)" else "ምንም አዲስ ማስታወሻ አልተገኘም (No new events found)")
        }
    }

    // Holiday reminder helper methods
    fun getEventForHoliday(holiday: HolidayEngine.Holiday): EventEntity? {
        val events = allEvents.value
        return events.firstOrNull { event ->
            (event.ethiopianYear == holiday.ethiopianDate.year || event.recurrence == "YEARLY_ETHIOPIAN") &&
            event.ethiopianMonth == holiday.ethiopianDate.month &&
            event.ethiopianDay == holiday.ethiopianDate.day &&
            (event.title.contains(holiday.titleEnglish, ignoreCase = true) ||
             event.title.contains(holiday.titleAmharic, ignoreCase = true) ||
             (event.category == "HOLIDAY" && holiday.titleAmharic.contains(event.title, ignoreCase = true)))
        }
    }

    fun scheduleHolidayReminder(
        holiday: HolidayEngine.Holiday,
        alertHour: Int,
        alertMinute: Int,
        remindOnEve: Boolean = false,
        reminderMinutesBefore: Int = 0,
        onDone: ((EventEntity) -> Unit)? = null
    ) {
        viewModelScope.launch {
            val targetDate = if (remindOnEve) {
                // Calculate previous Ethiopian day
                if (holiday.ethiopianDate.day > 1) {
                    EthiopianDate(holiday.ethiopianDate.year, holiday.ethiopianDate.month, holiday.ethiopianDate.day - 1)
                } else {
                    val prevMonth = if (holiday.ethiopianDate.month > 1) holiday.ethiopianDate.month - 1 else 13
                    val prevYear = if (holiday.ethiopianDate.month > 1) holiday.ethiopianDate.year else holiday.ethiopianDate.year - 1
                    val prevMonthDays = EthiopianDate.daysInMonth(prevYear, prevMonth)
                    EthiopianDate(prevYear, prevMonth, prevMonthDays)
                }
            } else {
                holiday.ethiopianDate
            }

            val gDate = EthiopianCalendarEngine.toGregorian(targetDate)
            val existing = getEventForHoliday(holiday)
            val eveSuffix = if (remindOnEve) " [ዋዜማ / Eve]" else ""
            val title = "${holiday.titleAmharic} (${holiday.titleEnglish})$eveSuffix"

            val eventToSave = EventEntity(
                id = existing?.id ?: 0L,
                title = title,
                description = holiday.description,
                category = "HOLIDAY",
                ethiopianYear = targetDate.year,
                ethiopianMonth = targetDate.month,
                ethiopianDay = targetDate.day,
                gregorianYear = gDate.year,
                gregorianMonth = gDate.month,
                gregorianDay = gDate.day,
                hour = alertHour,
                minute = alertMinute,
                isAllDay = true,
                recurrence = "NONE",
                reminderMinutesBefore = reminderMinutesBefore,
                colorHex = if (holiday.isPublicHoliday) "#EF4444" else "#F59E0B"
            )

            val savedId = if (eventToSave.id == 0L) {
                eventRepository.insert(eventToSave)
            } else {
                eventRepository.update(eventToSave)
                eventToSave.id
            }

            val finalEvent = eventToSave.copy(id = savedId)
            if (userSettings.value.notificationsEnabled && reminderMinutesBefore >= 0) {
                NotificationScheduler.scheduleEventReminder(getApplication(), finalEvent)
            }
            EthioCalWidgetProvider.updateAllWidgets(getApplication())
            onDone?.invoke(finalEvent)
        }
    }

    fun cancelHolidayReminder(holiday: HolidayEngine.Holiday, onDone: (() -> Unit)? = null) {
        viewModelScope.launch {
            val existing = getEventForHoliday(holiday)
            if (existing != null) {
                NotificationScheduler.cancelEventReminder(getApplication(), existing.id)
                eventRepository.delete(existing)
                EthioCalWidgetProvider.updateAllWidgets(getApplication())
            }
            onDone?.invoke()
        }
    }

    fun scheduleAllAnnualHolidays(
        year: Int,
        alertHour: Int = 8,
        alertMinute: Int = 0,
        reminderMinutesBefore: Int = 0,
        onResult: (Int) -> Unit
    ) {
        viewModelScope.launch {
            val holidays = HolidayEngine.getHolidaysForYear(year).filter {
                it.isPublicHoliday ||
                it.type == HolidayEngine.HolidayType.NATIONAL_PUBLIC ||
                it.type == HolidayEngine.HolidayType.ORTHODOX_MAJOR ||
                it.type == HolidayEngine.HolidayType.ISLAMIC
            }

            var count = 0
            for (holiday in holidays) {
                val existing = getEventForHoliday(holiday)
                val gDate = EthiopianCalendarEngine.toGregorian(holiday.ethiopianDate)
                val event = EventEntity(
                    id = existing?.id ?: 0L,
                    title = "${holiday.titleAmharic} (${holiday.titleEnglish})",
                    description = holiday.description,
                    category = "HOLIDAY",
                    ethiopianYear = holiday.ethiopianDate.year,
                    ethiopianMonth = holiday.ethiopianDate.month,
                    ethiopianDay = holiday.ethiopianDate.day,
                    gregorianYear = gDate.year,
                    gregorianMonth = gDate.month,
                    gregorianDay = gDate.day,
                    hour = alertHour,
                    minute = alertMinute,
                    isAllDay = true,
                    reminderMinutesBefore = reminderMinutesBefore,
                    colorHex = if (holiday.isPublicHoliday) "#EF4444" else "#F59E0B"
                )

                val savedId = if (event.id == 0L) {
                    eventRepository.insert(event)
                } else {
                    eventRepository.update(event)
                    event.id
                }

                if (userSettings.value.notificationsEnabled) {
                    NotificationScheduler.scheduleEventReminder(getApplication(), event.copy(id = savedId))
                }
                count++
            }

            if (count > 0) {
                EthioCalWidgetProvider.updateAllWidgets(getApplication())
            }
            onResult(count)
        }
    }


    // Settings actions
    fun setLanguage(lang: String) = viewModelScope.launch { 
        preferencesRepository.setLanguage(lang)
        EthioCalWidgetProvider.updateAllWidgets(getApplication())
    }
    fun setNumeralType(type: String) = viewModelScope.launch { 
        preferencesRepository.setNumeralType(type)
        EthioCalWidgetProvider.updateAllWidgets(getApplication())
    }
    fun setThemeMode(mode: String) = viewModelScope.launch { preferencesRepository.setThemeMode(mode) }
    fun setAccentPalette(palette: String) = viewModelScope.launch { preferencesRepository.setAccentPalette(palette) }
    fun setFirstDayOfWeek(firstDay: String) = viewModelScope.launch { preferencesRepository.setFirstDayOfWeek(firstDay) }
    fun setShowFasting(enabled: Boolean) = viewModelScope.launch { 
        preferencesRepository.setShowFasting(enabled)
        EthioCalWidgetProvider.updateAllWidgets(getApplication())
    }
    fun setShowMonthlySaints(enabled: Boolean) = viewModelScope.launch { 
        preferencesRepository.setShowMonthlySaints(enabled)
        EthioCalWidgetProvider.updateAllWidgets(getApplication())
    }

    fun refreshWidgets() {
        EthioCalWidgetProvider.updateAllWidgets(getApplication())
    }

    fun setNotificationsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            preferencesRepository.setNotificationsEnabled(enabled)
            val events = allEvents.value
            if (enabled) {
                NotificationScheduler.rescheduleAllActiveEvents(getApplication(), events)
            } else {
                NotificationScheduler.cancelAllReminders(getApplication(), events)
            }
        }
    }

    fun testNotification() {
        NotificationScheduler.scheduleTestReminder(getApplication(), delaySeconds = 2)
    }

    fun resyncAllReminders(onDone: (Int) -> Unit = {}) {
        viewModelScope.launch {
            val events = eventRepository.allEvents.firstOrNull() ?: emptyList()
            if (userSettings.value.notificationsEnabled) {
                NotificationScheduler.rescheduleAllActiveEvents(getApplication(), events)
                onDone(NotificationScheduler.countActiveScheduledEvents(events))
            } else {
                NotificationScheduler.cancelAllReminders(getApplication(), events)
                onDone(0)
            }
        }
    }

    fun currentAppLanguage(): AppLanguage {
        return when (userSettings.value.language) {
            "ENGLISH" -> AppLanguage.ENGLISH
            "AMHARIC" -> AppLanguage.AMHARIC
            "OROMO" -> AppLanguage.OROMO
            "TIGRINYA" -> AppLanguage.TIGRINYA
            "FRENCH" -> AppLanguage.FRENCH
            else -> AppLanguage.ENGLISH
        }
    }

    fun setCalendarFormat(format: String) {
        viewModelScope.launch {
            preferencesRepository.setCalendarFormat(format)
        }
    }

    fun setOnboardingCompleted(completed: Boolean) {
        viewModelScope.launch {
            preferencesRepository.setOnboardingCompleted(completed)
        }
    }

    private fun eventMatchesDate(event: EventEntity, date: EthiopianDate): Boolean {
        return when (event.recurrence) {
            "NONE" -> event.ethiopianYear == date.year && event.ethiopianMonth == date.month && event.ethiopianDay == date.day
            "DAILY" -> true
            "WEEKLY" -> {
                val eventDow = EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(event.ethiopianYear, event.ethiopianMonth, event.ethiopianDay))
                val targetDow = EthiopianCalendarEngine.getDayOfWeek(date)
                eventDow == targetDow
            }
            "MONTHLY_ETHIOPIAN" -> event.ethiopianDay == date.day
            "MONTHLY_GREGORIAN" -> {
                val gDate = EthiopianCalendarEngine.toGregorian(date)
                event.gregorianDay == gDate.day
            }
            "YEARLY_ETHIOPIAN" -> event.ethiopianMonth == date.month && event.ethiopianDay == date.day
            "YEARLY_GREGORIAN" -> {
                val gDate = EthiopianCalendarEngine.toGregorian(date)
                event.gregorianMonth == gDate.month && event.gregorianDay == gDate.day
            }
            else -> event.ethiopianYear == date.year && event.ethiopianMonth == date.month && event.ethiopianDay == date.day
        }
    }
}
