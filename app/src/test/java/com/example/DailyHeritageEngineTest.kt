package com.example

import com.example.calendar.engine.DailyHeritageEngine
import com.example.calendar.engine.EthiopianDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DailyHeritageEngineTest {

    @Test
    fun testAllThirtyDaysHaveProverbs() {
        assertEquals(30, DailyHeritageEngine.PROVERBS_BY_DAY.size)
        for (day in 1..30) {
            val date = EthiopianDate(2017, 1, day)
            val heritage = DailyHeritageEngine.getHeritageForDate(date)
            assertNotNull(heritage.proverb)
            assertTrue(heritage.proverb.amharic.isNotEmpty())
            assertTrue(heritage.proverb.englishTranslation.isNotEmpty())
            assertTrue(heritage.proverb.meaning.isNotEmpty())
            assertTrue(heritage.proverb.category.isNotEmpty())
        }
    }

    @Test
    fun testPagumeProverbs() {
        assertEquals(6, DailyHeritageEngine.PAGUME_PROVERBS.size)
        // In 2015 (Leap Year, Luke), Pagume has 6 days
        for (day in 1..6) {
            val date = EthiopianDate(2015, 13, day)
            val heritage = DailyHeritageEngine.getHeritageForDate(date)
            assertNotNull(heritage.proverb)
            assertTrue(heritage.proverb.amharic.isNotEmpty())
            assertEquals("ክረምት (Summer / Rainy Season)", heritage.solarPhase)
        }
    }

    @Test
    fun testEvangelistAndSolarPhaseMapping() {
        // 2017 is Matthew (ዘመነ ማቴዎስ: (2017 + 5500) % 4 = 1)
        val dateMeskerem = EthiopianDate(2017, 1, 1)
        val heritageMeskerem = DailyHeritageEngine.getHeritageForDate(dateMeskerem)
        assertEquals("ዘመነ ማቴዎስ", heritageMeskerem.evangelist)
        assertEquals("መከር (Autumn / Harvest)", heritageMeskerem.solarPhase)

        val dateTahsas = EthiopianDate(2017, 4, 1)
        val heritageTahsas = DailyHeritageEngine.getHeritageForDate(dateTahsas)
        assertEquals("በጋ (Winter / Dry Season)", heritageTahsas.solarPhase)

        val dateMegabit = EthiopianDate(2017, 7, 1)
        val heritageMegabit = DailyHeritageEngine.getHeritageForDate(dateMegabit)
        assertEquals("በልግ (Spring / Blossom)", heritageMegabit.solarPhase)
    }

    @Test
    fun testSaintMappingIntegrity() {
        // 21st is Maryam (ማርያም)
        val date21 = EthiopianDate(2017, 2, 21)
        val heritage21 = DailyHeritageEngine.getHeritageForDate(date21)
        assertNotNull(heritage21.saint)
        assertTrue(heritage21.saint!!.nameAmharic.contains("ማርያም"))

        // 12th is Mikael (ሚካኤል)
        val date12 = EthiopianDate(2017, 3, 12)
        val heritage12 = DailyHeritageEngine.getHeritageForDate(date12)
        assertNotNull(heritage12.saint)
        assertTrue(heritage12.saint!!.nameAmharic.contains("ሚካኤል"))
    }
}
