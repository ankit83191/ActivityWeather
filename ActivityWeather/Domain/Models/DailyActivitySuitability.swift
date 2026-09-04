struct DailyActivitySuitability: Equatable, Sendable {
    let date: CivilDate
    let activity: Activity
    let score: SuitabilityScore
    let reasons: [SuitabilityReason]

    var level: SuitabilityLevel {
        score.level
    }
}

enum SuitabilityReason: String, Equatable, Hashable, Sendable {
    case criticalThunderstorm
    case criticalFreezingRain
    case criticalExtremeWind
    case dangerousTravelCap
    case stayInside
    case snowfallAmount
    case snowWeather
    case heavySnowPenalty
    case freezingDrizzlePenalty
    case rainOnSnow
    case freezeMax
    case skiWind
    case skiSunshine
    case windProxy
    case fairSky
    case surfRain
    case airTempComfort
    case snowAtCoast
    case comfortTemp
    case dry
    case sunRatio
    case uv
    case fog
    case outdoorWind
    case heavySnowWalk
    case violentRain
    case wetDay
    case longPrecip
    case rainCodes
    case tempExtreme
    case overcast
    case beautifulOutdoor
}
