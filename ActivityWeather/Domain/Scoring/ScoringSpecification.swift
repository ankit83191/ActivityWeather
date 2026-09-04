enum ScoringSpecification {
    enum OutdoorVeto {
        static let thunderstormCodes: Set<Int> = [95, 96, 99]
        static let freezingRainCodes: Set<Int> = [66, 67]
        static let extremeGustKilometresPerHour = 90.0
    }

    enum IndoorTravelRisk {
        static let cap = 40.0
        static let codes: Set<Int> = [56, 57, 66, 67, 75, 82, 86, 95, 96, 99]
        static let gustKilometresPerHour = 80.0
    }

    enum Skiing {
        static let base = 45.0
        static let snowfallPointsPerCentimetre = 3.0
        static let snowfallAmountCap = 30.0
        static let snowWeatherCodes: Set<Int> = [71, 73, 77, 85]
        static let snowWeather = 12.0
        static let heavySnowCodes: Set<Int> = [75, 86]
        static let heavySnowPenalty = -12.0
        static let freezingDrizzleCodes: Set<Int> = [56, 57]
        static let freezingDrizzlePenalty = -16.0
        static let rainOnSnowMillimetres = 2.0
        static let rainOnSnow = -18.0
        static let freezeSevereColdCelsius = -20.0
        static let freezeIdealLowerCelsius = -12.0
        static let freezeIdealUpperCelsius = 1.0
        static let freezeSoftUpperCelsius = 4.0
        static let freezeWarmUpperCelsius = 8.0
        static let freezeSevereCold = -12.0
        static let freezeIdeal = 18.0
        static let freezeSoft = 8.0
        static let freezeWarm = -10.0
        static let freezeThaw = -22.0
        static let windStrongKilometresPerHour = 60.0
        static let windModerateKilometresPerHour = 45.0
        static let windStrong = -22.0
        static let windModerate = -12.0
        static let sunshineSeconds = 14_400.0
        static let sunshine = 5.0
    }

    enum Surfing {
        static let base = 50.0
        static let windCalmKilometresPerHour = 8.0
        static let windIdealLowerKilometresPerHour = 12.0
        static let windIdealUpperKilometresPerHour = 28.0
        static let windBreezyUpperKilometresPerHour = 40.0
        static let windSevereKilometresPerHour = 55.0
        static let windCalm = -6.0
        static let windIdeal = 16.0
        static let windBreezy = 6.0
        static let windStrong = -18.0
        static let windSevere = -28.0
        static let fairSkyCodes: Set<Int> = [0, 1, 2]
        static let overcastCode = 3
        static let fairSky = 10.0
        static let overcast = 4.0
        static let rainLightMillimetres = 2.0
        static let rainModerateMillimetres = 10.0
        static let rainHeavyMillimetres = 25.0
        static let rainModerate = -6.0
        static let rainHeavy = -14.0
        static let rainExtreme = -22.0
        static let violentRainCode = 82
        static let violentRain = -10.0
        static let freezingDrizzleCodes: Set<Int> = [56, 57]
        static let freezingDrizzlePenalty = -14.0
        static let airColdCelsius = 12.0
        static let airCoolCelsius = 14.0
        static let airIdealLowerCelsius = 18.0
        static let airIdealUpperCelsius = 28.0
        static let airWarmUpperCelsius = 32.0
        static let airCold = -12.0
        static let airCool = 6.0
        static let airIdeal = 14.0
        static let airWarm = 4.0
        static let airHot = -8.0
        static let snowAtCoast = -10.0
    }

    enum OutdoorSightseeing {
        static let base = 50.0
        static let comfortIdealLowerCelsius = 12.0
        static let comfortIdealUpperCelsius = 24.0
        static let comfortMildLowerCelsius = 8.0
        static let comfortMildUpperCelsius = 28.0
        static let comfortCoolLowerCelsius = 4.0
        static let comfortWarmUpperCelsius = 32.0
        static let comfortIdeal = 20.0
        static let comfortMild = 8.0
        static let comfortCool = -8.0
        static let comfortExtreme = -20.0
        static let dryNone = 14.0
        static let dryTraceMillimetres = 2.0
        static let dryTrace = 4.0
        static let dryLightMillimetres = 8.0
        static let dryLight = -12.0
        static let dryWetMillimetres = 20.0
        static let dryWet = -24.0
        static let drySoaked = -32.0
        static let sunHighRatio = 0.55
        static let sunHigh = 14.0
        static let sunModerateRatio = 0.30
        static let sunModerate = 6.0
        static let sunLowRatio = 0.12
        static let sunLow = -8.0
        static let uvUsefulLower = 3.0
        static let uvUsefulUpper = 7.0
        static let uvUseful = 4.0
        static let uvExtreme = 11.0
        static let uvExtremePenalty = -10.0
        static let fogCodes: Set<Int> = [45, 48]
        static let fog = -14.0
        static let windStrongGustKilometresPerHour = 70.0
        static let windStrong = -20.0
        static let windBreezyGustKilometresPerHour = 50.0
        static let windBreezy = -10.0
        static let heavySnowCodes: Set<Int> = [75, 86]
        static let heavySnowWalk = -18.0
        static let violentRainCode = 82
        static let violentRain = -16.0
        static let freezingDrizzleCodes: Set<Int> = [56, 57]
        static let freezingDrizzlePenalty = -14.0
    }

    enum IndoorSightseeing {
        static let base = 48.0
        static let wetHeavyMillimetres = 8.0
        static let wetHeavy = 18.0
        static let wetModerateMillimetres = 3.0
        static let wetModerate = 8.0
        static let longPrecipHours = 6.0
        static let longPrecip = 8.0
        static let rainCodes: Set<Int> = [51, 53, 55, 61, 63, 65, 80, 81]
        static let rainCode = 8.0
        static let tempColdCelsius = 5.0
        static let tempHotCelsius = 32.0
        static let tempExtreme = 12.0
        static let fogCodes: Set<Int> = [45, 48]
        static let fog = 6.0
        static let overcastCode = 3
        static let overcast = 4.0
        static let stayInsideCodes: Set<Int> = [95, 96, 99]
        static let stayInside = 6.0
        static let beautifulApparentLowerCelsius = 16.0
        static let beautifulApparentUpperCelsius = 26.0
        static let beautifulSunRatio = 0.50
        static let beautifulOutdoor = -16.0
    }
}
