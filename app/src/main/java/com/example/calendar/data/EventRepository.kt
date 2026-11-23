package com.example.calendar.data

import kotlinx.coroutines.flow.Flow

class EventRepository(private val eventDao: EventDao) {

    val allEvents: Flow<List<EventEntity>> = eventDao.getAllEvents()

    fun getEventsForMonth(year: Int, month: Int): Flow<List<EventEntity>> =
        eventDao.getEventsForEthiopianMonth(year, month)

    fun getEventsForDay(year: Int, month: Int, day: Int): Flow<List<EventEntity>> =
        eventDao.getEventsForEthiopianDay(year, month, day)

    fun searchEvents(query: String): Flow<List<EventEntity>> =
        eventDao.searchEvents(query)

    suspend fun getEventById(id: Long): EventEntity? =
        eventDao.getEventById(id)

    suspend fun insert(event: EventEntity): Long =
        eventDao.insertEvent(event)

    suspend fun update(event: EventEntity) =
        eventDao.updateEvent(event)

    suspend fun delete(event: EventEntity) =
        eventDao.deleteEvent(event)

    suspend fun deleteById(id: Long) =
        eventDao.deleteEventById(id)
}
