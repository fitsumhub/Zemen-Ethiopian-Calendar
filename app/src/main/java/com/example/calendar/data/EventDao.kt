package com.example.calendar.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface EventDao {

    @Query("SELECT * FROM events ORDER BY gregorianYear ASC, gregorianMonth ASC, gregorianDay ASC, hour ASC, minute ASC")
    fun getAllEvents(): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE ethiopianYear = :year AND ethiopianMonth = :month ORDER BY ethiopianDay ASC, hour ASC")
    fun getEventsForEthiopianMonth(year: Int, month: Int): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE ethiopianYear = :year AND ethiopianMonth = :month AND ethiopianDay = :day ORDER BY hour ASC, minute ASC")
    fun getEventsForEthiopianDay(year: Int, month: Int, day: Int): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE title LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%' ORDER BY gregorianYear DESC")
    fun searchEvents(query: String): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE id = :id LIMIT 1")
    suspend fun getEventById(id: Long): EventEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvent(event: EventEntity): Long

    @Update
    suspend fun updateEvent(event: EventEntity)

    @Delete
    suspend fun deleteEvent(event: EventEntity)

    @Query("DELETE FROM events WHERE id = :id")
    suspend fun deleteEventById(id: Long)
}
