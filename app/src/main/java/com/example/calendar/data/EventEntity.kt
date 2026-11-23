package com.example.calendar.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "events")
data class EventEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val title: String,
    val description: String = "",
    val category: String = "TASK", // BIRTHDAY, MEETING, EXAM, TASK, ANNIVERSARY, RELIGIOUS, CULTURAL, OTHER
    val ethiopianYear: Int,
    val ethiopianMonth: Int,
    val ethiopianDay: Int,
    val gregorianYear: Int,
    val gregorianMonth: Int,
    val gregorianDay: Int,
    val hour: Int = 9,
    val minute: Int = 0,
    val isAllDay: Boolean = true,
    val recurrence: String = "NONE", // NONE, DAILY, WEEKLY, MONTHLY_ETHIOPIAN, MONTHLY_GREGORIAN, YEARLY_ETHIOPIAN, YEARLY_GREGORIAN
    val reminderMinutesBefore: Int = 15, // -1 = None, 0 = At time, 15, 60, 1440
    val colorHex: String = "#E6A817",
    val isCompleted: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
