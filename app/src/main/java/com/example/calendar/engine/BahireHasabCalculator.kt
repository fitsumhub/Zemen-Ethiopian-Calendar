package com.example.calendar.engine

import com.example.calendar.core.BahireHasab
import com.example.calendar.core.LeapYearCalculator

typealias OrthodoxFeast = BahireHasab.OrthodoxFeast

/**
 * Bahire Hasab (ባሕረ ሐሳብ) - Engine wrapper delegating core computus and movable feasts
 * calculations directly to [BahireHasab] in the `:calendar-core` module.
 */
object BahireHasabCalculator {

    enum class Evangelist(val amharic: String, val english: String, val geez: String) {
        JOHN("ዮሐንስ", "John", "ዮሐንስ"),
        MATTHEW("ማቴዎስ", "Matthew", "ማቴዎስ"),
        MARK("ማርቆስ", "Mark", "ማርቆስ"),
        LUKE("ሉቃስ (ዘመነ ሉቃስ - ዘመነ ዮሐንስ መሸጋገሪያ)", "Luke (Leap Year)", "ሉቃስ")
    }

    data class BahireHasabResult(
        val ethiopianYear: Int,
        val ameteAlem: Int,
        val evangelist: Evangelist,
        val wenber: Int,
        val abeqte: Int,
        val metqi: Int,
        val metqiMonth: Int,
        val nenewe: EthiopianDate,
        val movableFeasts: List<OrthodoxFeast>
    )

    /**
     * Calculates Bahire Hasab for any Ethiopian year by delegating to :calendar-core.
     */
    fun calculate(year: Int): BahireHasabResult {
        val coreResult = BahireHasab.calculate(year)
        val ev = when (coreResult.evangelist) {
            LeapYearCalculator.Evangelist.MATTHEW -> Evangelist.MATTHEW
            LeapYearCalculator.Evangelist.MARK -> Evangelist.MARK
            LeapYearCalculator.Evangelist.LUKE -> Evangelist.LUKE
            LeapYearCalculator.Evangelist.JOHN -> Evangelist.JOHN
        }
        return BahireHasabResult(
            ethiopianYear = coreResult.ethiopianYear,
            ameteAlem = coreResult.ameteAlem,
            evangelist = ev,
            wenber = coreResult.wenber,
            abeqte = coreResult.abeqte,
            metqi = coreResult.metqi,
            metqiMonth = coreResult.metqiMonth,
            nenewe = coreResult.nenewe,
            movableFeasts = coreResult.movableFeasts
        )
    }

    // Direct mathematical delegations to calendar-core algorithms:
    fun ameteAlem(year: Int): Int = BahireHasab.ameteAlem(year)
    fun wenber(year: Int): Int = BahireHasab.wenber(year)
    fun abeqte(year: Int): Int = BahireHasab.abeqte(year)
    fun metqi(year: Int): Int = BahireHasab.metqi(year)
    fun metqiMonth(year: Int): Int = BahireHasab.metqiMonth(year)
    fun nenewe(year: Int): EthiopianDate = BahireHasab.nenewe(year)
    fun abiyTsom(year: Int): EthiopianDate = BahireHasab.abiyTsom(year)
    fun debreZeit(year: Int): EthiopianDate = BahireHasab.debreZeit(year)
    fun hosanna(year: Int): EthiopianDate = BahireHasab.hosanna(year)
    fun siklet(year: Int): EthiopianDate = BahireHasab.siklet(year)
    fun fasika(year: Int): EthiopianDate = BahireHasab.fasika(year)
    fun rikbeKahnat(year: Int): EthiopianDate = BahireHasab.rikbeKahnat(year)
    fun erget(year: Int): EthiopianDate = BahireHasab.erget(year)
    fun paraclete(year: Int): EthiopianDate = BahireHasab.paraclete(year)
    fun tsomeHawaryat(year: Int): EthiopianDate = BahireHasab.tsomeHawaryat(year)
    fun tsomeDihnet(year: Int): EthiopianDate = BahireHasab.tsomeDihnet(year)
    fun apostlesFastDuration(year: Int): Int = BahireHasab.apostlesFastDuration(year)
    fun isGreatLent(date: EthiopianDate): Boolean = BahireHasab.isGreatLent(date)
    fun isApostlesFast(date: EthiopianDate): Boolean = BahireHasab.isApostlesFast(date)
    fun isNinevehFast(date: EthiopianDate): Boolean = BahireHasab.isNinevehFast(date)
    fun isFiftyDaysOfJoy(date: EthiopianDate): Boolean = BahireHasab.isFiftyDaysOfJoy(date)
    fun isWeeklyFastDay(date: EthiopianDate): Boolean = BahireHasab.isWeeklyFastDay(date)
}
