struct SuitabilityScoringEngine: ActivityScoring {
    func suitability(
        for forecast: DailyForecast,
        activity: Activity
    ) -> DailyActivitySuitability {
        switch activity {
        case .skiing:
            return scoreSkiing(forecast)
        case .surfing:
            return scoreSurfing(forecast)
        case .outdoorSightseeing:
            return scoreOutdoor(forecast)
        case .indoorSightseeing:
            return scoreIndoor(forecast)
        }
    }

    private func scoreSkiing(_ day: DailyForecast) -> DailyActivitySuitability {
        if let veto = outdoorVeto(day) {
            return finished(day, .skiing, raw: 0, rules: [], leading: veto)
        }

        var rules: [ScoredRule] = []
        let snowPoints = min(
            ScoringSpecification.Skiing.snowfallAmountCap,
            ScoringSpecification.Skiing.snowfallPointsPerCentimetre * day.snowfallCentimetres
        )
        rules.append(.init(.snowfallAmount, snowPoints))
        if ScoringSpecification.Skiing.snowWeatherCodes.contains(day.weatherCode) {
            rules.append(.init(.snowWeather, ScoringSpecification.Skiing.snowWeather))
        }
        if ScoringSpecification.Skiing.heavySnowCodes.contains(day.weatherCode) {
            rules.append(.init(.heavySnowPenalty, ScoringSpecification.Skiing.heavySnowPenalty))
        }
        if ScoringSpecification.Skiing.freezingDrizzleCodes.contains(day.weatherCode) {
            rules.append(.init(.freezingDrizzlePenalty, ScoringSpecification.Skiing.freezingDrizzlePenalty))
        }
        if day.rainMillimetres >= ScoringSpecification.Skiing.rainOnSnowMillimetres {
            rules.append(.init(.rainOnSnow, ScoringSpecification.Skiing.rainOnSnow))
        }
        rules.append(.init(.freezeMax, freezeMax(day.maximumTemperatureCelsius)))
        rules.append(.init(.skiWind, skiWind(day.maximumWindSpeedKilometresPerHour)))
        if day.sunshineDurationSeconds >= ScoringSpecification.Skiing.sunshineSeconds {
            rules.append(.init(.skiSunshine, ScoringSpecification.Skiing.sunshine))
        }

        return finished(day, .skiing, raw: ScoringSpecification.Skiing.base + rules.total, rules: rules)
    }

    private func scoreSurfing(_ day: DailyForecast) -> DailyActivitySuitability {
        if let veto = outdoorVeto(day) {
            return finished(day, .surfing, raw: 0, rules: [], leading: veto)
        }

        var rules: [ScoredRule] = []
        rules.append(.init(.windProxy, surfWind(day.maximumWindSpeedKilometresPerHour)))
        if ScoringSpecification.Surfing.fairSkyCodes.contains(day.weatherCode) {
            rules.append(.init(.fairSky, ScoringSpecification.Surfing.fairSky))
        } else if day.weatherCode == ScoringSpecification.Surfing.overcastCode {
            rules.append(.init(.fairSky, ScoringSpecification.Surfing.overcast))
        }
        rules.append(.init(.surfRain, surfRain(day.rainMillimetres)))
        if day.weatherCode == ScoringSpecification.Surfing.violentRainCode {
            rules.append(.init(.violentRain, ScoringSpecification.Surfing.violentRain))
        }
        if ScoringSpecification.Surfing.freezingDrizzleCodes.contains(day.weatherCode) {
            rules.append(.init(.freezingDrizzlePenalty, ScoringSpecification.Surfing.freezingDrizzlePenalty))
        }
        rules.append(.init(.airTempComfort, airTempComfort(day.maximumTemperatureCelsius)))
        if day.snowfallCentimetres > 0 {
            rules.append(.init(.snowAtCoast, ScoringSpecification.Surfing.snowAtCoast))
        }

        return finished(day, .surfing, raw: ScoringSpecification.Surfing.base + rules.total, rules: rules)
    }

    private func scoreOutdoor(_ day: DailyForecast) -> DailyActivitySuitability {
        if let veto = outdoorVeto(day) {
            return finished(day, .outdoorSightseeing, raw: 0, rules: [], leading: veto)
        }

        var rules: [ScoredRule] = []
        rules.append(.init(.comfortTemp, comfortTemp(day.maximumApparentTemperatureCelsius)))
        rules.append(.init(.dry, dry(day.precipitationMillimetres)))
        rules.append(.init(.sunRatio, sunRatioContribution(sunRatio(day))))
        rules.append(.init(.uv, uv(day.maximumUVIndex)))
        if ScoringSpecification.OutdoorSightseeing.fogCodes.contains(day.weatherCode) {
            rules.append(.init(.fog, ScoringSpecification.OutdoorSightseeing.fog))
        }
        rules.append(.init(.outdoorWind, outdoorWind(day.maximumWindGustKilometresPerHour)))
        if ScoringSpecification.OutdoorSightseeing.heavySnowCodes.contains(day.weatherCode) {
            rules.append(.init(.heavySnowWalk, ScoringSpecification.OutdoorSightseeing.heavySnowWalk))
        }
        if day.weatherCode == ScoringSpecification.OutdoorSightseeing.violentRainCode {
            rules.append(.init(.violentRain, ScoringSpecification.OutdoorSightseeing.violentRain))
        }
        if ScoringSpecification.OutdoorSightseeing.freezingDrizzleCodes.contains(day.weatherCode) {
            rules.append(.init(.freezingDrizzlePenalty, ScoringSpecification.OutdoorSightseeing.freezingDrizzlePenalty))
        }

        return finished(day, .outdoorSightseeing, raw: ScoringSpecification.OutdoorSightseeing.base + rules.total, rules: rules)
    }

    private func scoreIndoor(_ day: DailyForecast) -> DailyActivitySuitability {
        var rules: [ScoredRule] = []
        if day.precipitationMillimetres >= ScoringSpecification.IndoorSightseeing.wetHeavyMillimetres {
            rules.append(.init(.wetDay, ScoringSpecification.IndoorSightseeing.wetHeavy))
        } else if day.precipitationMillimetres >= ScoringSpecification.IndoorSightseeing.wetModerateMillimetres {
            rules.append(.init(.wetDay, ScoringSpecification.IndoorSightseeing.wetModerate))
        }
        if day.precipitationHours >= ScoringSpecification.IndoorSightseeing.longPrecipHours {
            rules.append(.init(.longPrecip, ScoringSpecification.IndoorSightseeing.longPrecip))
        }
        if ScoringSpecification.IndoorSightseeing.rainCodes.contains(day.weatherCode) {
            rules.append(.init(.rainCodes, ScoringSpecification.IndoorSightseeing.rainCode))
        }
        if day.maximumApparentTemperatureCelsius < ScoringSpecification.IndoorSightseeing.tempColdCelsius
            || day.maximumApparentTemperatureCelsius > ScoringSpecification.IndoorSightseeing.tempHotCelsius {
            rules.append(.init(.tempExtreme, ScoringSpecification.IndoorSightseeing.tempExtreme))
        }
        if ScoringSpecification.IndoorSightseeing.fogCodes.contains(day.weatherCode) {
            rules.append(.init(.fog, ScoringSpecification.IndoorSightseeing.fog))
        }
        if day.weatherCode == ScoringSpecification.IndoorSightseeing.overcastCode {
            rules.append(.init(.overcast, ScoringSpecification.IndoorSightseeing.overcast))
        }
        if ScoringSpecification.IndoorSightseeing.stayInsideCodes.contains(day.weatherCode) {
            rules.append(.init(.stayInside, ScoringSpecification.IndoorSightseeing.stayInside))
        }
        let ratio = sunRatio(day)
        if day.precipitationMillimetres == 0,
           (ScoringSpecification.IndoorSightseeing.beautifulApparentLowerCelsius...ScoringSpecification.IndoorSightseeing.beautifulApparentUpperCelsius)
            .contains(day.maximumApparentTemperatureCelsius),
           ratio >= ScoringSpecification.IndoorSightseeing.beautifulSunRatio {
            rules.append(.init(.beautifulOutdoor, ScoringSpecification.IndoorSightseeing.beautifulOutdoor))
        }

        var raw = ScoringSpecification.IndoorSightseeing.base + rules.total
        var leading: SuitabilityReason?
        if indoorTravelRisk(day), raw > ScoringSpecification.IndoorTravelRisk.cap {
            raw = ScoringSpecification.IndoorTravelRisk.cap
            leading = .dangerousTravelCap
        }
        return finished(day, .indoorSightseeing, raw: raw, rules: rules, leading: leading)
    }

    private func outdoorVeto(_ day: DailyForecast) -> SuitabilityReason? {
        if ScoringSpecification.OutdoorVeto.thunderstormCodes.contains(day.weatherCode) {
            return .criticalThunderstorm
        }
        if ScoringSpecification.OutdoorVeto.freezingRainCodes.contains(day.weatherCode) {
            return .criticalFreezingRain
        }
        if day.maximumWindGustKilometresPerHour >= ScoringSpecification.OutdoorVeto.extremeGustKilometresPerHour {
            return .criticalExtremeWind
        }
        return nil
    }

    private func indoorTravelRisk(_ day: DailyForecast) -> Bool {
        ScoringSpecification.IndoorTravelRisk.codes.contains(day.weatherCode)
            || day.maximumWindGustKilometresPerHour >= ScoringSpecification.IndoorTravelRisk.gustKilometresPerHour
    }

    private func freezeMax(_ temperature: Double) -> Double {
        let spec = ScoringSpecification.Skiing.self
        if temperature < spec.freezeSevereColdCelsius { return spec.freezeSevereCold }
        if temperature >= spec.freezeIdealLowerCelsius && temperature <= spec.freezeIdealUpperCelsius {
            return spec.freezeIdeal
        }
        if temperature > spec.freezeIdealUpperCelsius && temperature <= spec.freezeSoftUpperCelsius {
            return spec.freezeSoft
        }
        if temperature > spec.freezeSoftUpperCelsius && temperature <= spec.freezeWarmUpperCelsius {
            return spec.freezeWarm
        }
        if temperature > spec.freezeWarmUpperCelsius { return spec.freezeThaw }
        return 0
    }

    private func skiWind(_ speed: Double) -> Double {
        if speed > ScoringSpecification.Skiing.windStrongKilometresPerHour {
            return ScoringSpecification.Skiing.windStrong
        }
        if speed > ScoringSpecification.Skiing.windModerateKilometresPerHour {
            return ScoringSpecification.Skiing.windModerate
        }
        return 0
    }

    private func surfWind(_ speed: Double) -> Double {
        let spec = ScoringSpecification.Surfing.self
        if speed < spec.windCalmKilometresPerHour { return spec.windCalm }
        if speed >= spec.windIdealLowerKilometresPerHour && speed <= spec.windIdealUpperKilometresPerHour {
            return spec.windIdeal
        }
        if (speed >= spec.windCalmKilometresPerHour && speed < spec.windIdealLowerKilometresPerHour)
            || (speed > spec.windIdealUpperKilometresPerHour && speed <= spec.windBreezyUpperKilometresPerHour) {
            return spec.windBreezy
        }
        if speed > spec.windSevereKilometresPerHour { return spec.windSevere }
        if speed > spec.windBreezyUpperKilometresPerHour { return spec.windStrong }
        return 0
    }

    private func surfRain(_ rain: Double) -> Double {
        let spec = ScoringSpecification.Surfing.self
        if rain <= spec.rainLightMillimetres { return 0 }
        if rain <= spec.rainModerateMillimetres { return spec.rainModerate }
        if rain <= spec.rainHeavyMillimetres { return spec.rainHeavy }
        return spec.rainExtreme
    }

    private func airTempComfort(_ temperature: Double) -> Double {
        let spec = ScoringSpecification.Surfing.self
        if temperature < spec.airColdCelsius { return spec.airCold }
        if temperature >= spec.airIdealLowerCelsius && temperature <= spec.airIdealUpperCelsius {
            return spec.airIdeal
        }
        if temperature >= spec.airCoolCelsius && temperature < spec.airIdealLowerCelsius {
            return spec.airCool
        }
        if temperature > spec.airIdealUpperCelsius && temperature <= spec.airWarmUpperCelsius {
            return spec.airWarm
        }
        if temperature > spec.airWarmUpperCelsius { return spec.airHot }
        return 0
    }

    private func comfortTemp(_ apparent: Double) -> Double {
        let spec = ScoringSpecification.OutdoorSightseeing.self
        if apparent >= spec.comfortIdealLowerCelsius && apparent <= spec.comfortIdealUpperCelsius {
            return spec.comfortIdeal
        }
        if (apparent >= spec.comfortMildLowerCelsius && apparent < spec.comfortIdealLowerCelsius)
            || (apparent > spec.comfortIdealUpperCelsius && apparent <= spec.comfortMildUpperCelsius) {
            return spec.comfortMild
        }
        if (apparent >= spec.comfortCoolLowerCelsius && apparent < spec.comfortMildLowerCelsius)
            || (apparent > spec.comfortMildUpperCelsius && apparent <= spec.comfortWarmUpperCelsius) {
            return spec.comfortCool
        }
        return spec.comfortExtreme
    }

    private func dry(_ precipitation: Double) -> Double {
        let spec = ScoringSpecification.OutdoorSightseeing.self
        if precipitation == 0 { return spec.dryNone }
        if precipitation <= spec.dryTraceMillimetres { return spec.dryTrace }
        if precipitation <= spec.dryLightMillimetres { return spec.dryLight }
        if precipitation <= spec.dryWetMillimetres { return spec.dryWet }
        return spec.drySoaked
    }

    private func sunRatio(_ day: DailyForecast) -> Double {
        guard day.daylightDurationSeconds > 0 else {
            return 0
        }
        return day.sunshineDurationSeconds / day.daylightDurationSeconds
    }

    private func sunRatioContribution(_ ratio: Double) -> Double {
        let spec = ScoringSpecification.OutdoorSightseeing.self
        if ratio >= spec.sunHighRatio { return spec.sunHigh }
        if ratio >= spec.sunModerateRatio { return spec.sunModerate }
        if ratio < spec.sunLowRatio { return spec.sunLow }
        return 0
    }

    private func uv(_ index: Double) -> Double {
        let spec = ScoringSpecification.OutdoorSightseeing.self
        if index >= spec.uvUsefulLower && index <= spec.uvUsefulUpper { return spec.uvUseful }
        if index >= spec.uvExtreme { return spec.uvExtremePenalty }
        return 0
    }

    private func outdoorWind(_ gusts: Double) -> Double {
        if gusts >= ScoringSpecification.OutdoorSightseeing.windStrongGustKilometresPerHour {
            return ScoringSpecification.OutdoorSightseeing.windStrong
        }
        if gusts >= ScoringSpecification.OutdoorSightseeing.windBreezyGustKilometresPerHour {
            return ScoringSpecification.OutdoorSightseeing.windBreezy
        }
        return 0
    }

    private func finished(
        _ day: DailyForecast,
        _ activity: Activity,
        raw: Double,
        rules: [ScoredRule],
        leading: SuitabilityReason? = nil
    ) -> DailyActivitySuitability {
        let rounded = Int(raw.rounded(.toNearestOrAwayFromZero))
        return DailyActivitySuitability(
            day: day,
            activity: activity,
            score: SuitabilityScore(clamping: rounded),
            reasons: orderedReasons(rules, leading: leading)
        )
    }

    private func orderedReasons(_ rules: [ScoredRule], leading: SuitabilityReason?) -> [SuitabilityReason] {
        var unique: [SuitabilityReason: Double] = [:]
        for rule in rules where rule.contribution != 0 {
            unique[rule.reason, default: 0] += rule.contribution
        }
        var ordered = unique
            .map { ScoredRule($0.key, $0.value) }
            .sorted { lhs, rhs in
                let left = abs(lhs.contribution)
                let right = abs(rhs.contribution)
                if left != right {
                    return left > right
                }
                return lhs.reason.rawValue < rhs.reason.rawValue
            }
            .map(\.reason)
        if let leading {
            ordered.removeAll { $0 == leading }
            ordered.insert(leading, at: 0)
        }
        return ordered
    }
}

private struct ScoredRule {
    let reason: SuitabilityReason
    let contribution: Double

    init(_ reason: SuitabilityReason, _ contribution: Double) {
        self.reason = reason
        self.contribution = contribution
    }
}

private extension Array where Element == ScoredRule {
    var total: Double {
        reduce(0) { $0 + $1.contribution }
    }
}
