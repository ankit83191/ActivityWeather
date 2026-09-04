import SwiftUI

struct ActivityForecastView: View {
    @State private var viewModel: ActivityForecastViewModel
    @State private var isShowingExplanation = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: ActivityForecastViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.status {
            case .idle, .loading:
                ProgressView("Loading activity forecast")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("activity-forecast-loading")
            case let .loaded(result):
                loadedContent(result)
            case .failure:
                failureContent
            }
        }
        .navigationTitle(viewModel.locationName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingExplanation = true
                } label: {
                    Label("How scoring works", systemImage: "info.circle")
                }
                .accessibilityIdentifier("scoring-explanation-button")
            }
        }
        .sheet(isPresented: $isShowingExplanation) {
            ScoringExplanationView()
        }
        .task {
            viewModel.load()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private func loadedContent(
        _ result: LocationActivityForecast
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                activitySelector
                heuristicDisclaimer
                dataAttribution

                if viewModel.selectedActivity == .surfing {
                    surfingDisclaimer
                }

                if let rows = ActivityForecastPresentation.rankedDays(
                    in: result,
                    for: viewModel.selectedActivity
                ) {
                    if let best = rows.first {
                        bestDaySummary(
                            best,
                            timeZoneIdentifier: result.forecast.timeZoneIdentifier
                        )
                    }
                    ForEach(rows) { row in
                        rankingCard(
                            row,
                            timeZoneIdentifier: result.forecast.timeZoneIdentifier
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "Forecast details unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(
                            "The weather and ranking dates could not be matched."
                        )
                    )
                    .frame(minHeight: 240)
                }
            }
            .padding()
        }
    }

    private var activitySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
                ),
                spacing: 8
            ) {
                ForEach(Activity.allCases, id: \.self) { activity in
                    let selected = viewModel.selectedActivity == activity
                    Button {
                        viewModel.selectActivity(activity)
                    } label: {
                        HStack(spacing: 6) {
                            Text(activity.shortDisplayName)
                            if selected {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .background(
                            selected
                                ? Color.accentColor
                                : Color.secondary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(activity.accessibilityDisplayName)
                    .accessibilityValue(selected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityHint(
                        selected
                            ? "Currently showing this activity ranking"
                            : "Shows this activity ranking"
                    )
                    .accessibilityIdentifier(
                        "activity-selector-\(activity.shortDisplayName.lowercased())"
                    )
                }
            }
        }
    }

    private var heuristicDisclaimer: some View {
        Text(
            "Scores are a rule-based weather-suitability heuristic, not a "
                + "safety guarantee or confirmation that a venue exists."
        )
        .font(.callout)
        .foregroundStyle(.primary)
    }

    private var dataAttribution: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let openMeteoURL = URL(string: "https://open-meteo.com/") {
                Link(
                    "Weather data by Open-Meteo.com",
                    destination: openMeteoURL
                )
                .accessibilityIdentifier("forecast-data-attribution")
            }

            Text(
                "Activity scores are this application’s heuristic "
                    + "transformations of the source weather data and are not "
                    + "endorsed by Open-Meteo."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var surfingDisclaimer: some View {
        Text(
            "Surfing uses weather proxies only. Wave height, swell, tides, "
                + "coastal suitability and water temperature are not included."
        )
        .font(.callout.weight(.semibold))
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.55), lineWidth: 1)
        }
        .accessibilityLabel(
            "Surfing limitation. Surfing uses weather proxies only. "
                + "Wave height, swell, tides, coastal suitability and water "
                + "temperature are not included."
        )
    }

    private func bestDaySummary(
        _ row: RankedForecastDay,
        timeZoneIdentifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Best day")
                .font(.headline)
            Text(dateText(row.suitability.date, timeZoneIdentifier))
                .font(.title2.bold())
            Text(
                "\(row.suitability.score.value) out of 100 · "
                    + row.suitability.level.rawValue
            )
            .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("activity-forecast-best-day")
    }

    private func rankingCard(
        _ row: RankedForecastDay,
        timeZoneIdentifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            rankingHeader(row, timeZoneIdentifier: timeZoneIdentifier)

            weatherFacts(row.forecast)

            if !row.suitability.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why")
                        .font(.subheadline.bold())
                    ForEach(row.suitability.reasons, id: \.self) { reason in
                        Text("• \(reason.presentationText)")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ActivityForecastPresentation.accessibilitySummary(
                for: row,
                timeZoneIdentifier: timeZoneIdentifier
            )
        )
        .accessibilityIdentifier("activity-forecast-rank-\(row.rank)")
    }

    @ViewBuilder
    private func rankingHeader(
        _ row: RankedForecastDay,
        timeZoneIdentifier: String
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                rankAndDate(row, timeZoneIdentifier: timeZoneIdentifier)
                Spacer(minLength: 8)
                score(row)
            }

            VStack(alignment: .leading, spacing: 10) {
                rankAndDate(row, timeZoneIdentifier: timeZoneIdentifier)
                HStack(alignment: .firstTextBaseline) {
                    Text("Score")
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    score(row)
                }
            }
        }
    }

    private func rankAndDate(
        _ row: RankedForecastDay,
        timeZoneIdentifier: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(row.rank)")
                .font(.title2.bold())
                .frame(minWidth: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(dateText(row.suitability.date, timeZoneIdentifier))
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(row.suitability.level.rawValue)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func score(_ row: RankedForecastDay) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(row.suitability.score.value)")
                .font(.title.bold())
            Text("out of 100")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func weatherFacts(_ forecast: DailyForecast) -> some View {
        let facts = ActivityForecastPresentation.weatherFacts(
            for: forecast,
            activity: viewModel.selectedActivity
        )

        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                ForEach(facts) { fact in
                    weatherFact(fact)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(facts) { fact in
                    weatherFact(fact)
                }
            }
        }
    }

    private func weatherFact(_ fact: WeatherFact) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(fact.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(fact.value)
                .font(.subheadline.weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }

    private var failureContent: some View {
        ContentUnavailableView {
            Label(
                "Couldn’t load forecast",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text((viewModel.failure ?? .generic).recoveryMessage)
        } actions: {
            Button("Try Again") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Attempts to load this forecast again")
            .accessibilityIdentifier("activity-forecast-retry")
        }
    }

    private func dateText(
        _ date: CivilDate,
        _ timeZoneIdentifier: String
    ) -> String {
        ForecastDateFormatting.string(
            for: date,
            timeZoneIdentifier: timeZoneIdentifier
        ) ?? "Date unavailable"
    }
}

private struct ScoringExplanationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Score bands") {
                    Text("0–24 · Poor")
                    Text("25–49 · Fair")
                    Text("50–74 · Good")
                    Text("75–100 · Great")
                }

                Section("How scores work") {
                    Text(
                        "Scores use transparent, rule-based weather heuristics "
                            + "and are not scientifically validated."
                    )
                    Text(
                        "Weather suitability does not confirm that a ski area, "
                            + "surf break, museum or other venue exists."
                    )
                    Text(
                        "Reasons show the weather rules that affected each score."
                    )
                }

                Section("Surfing limitation") {
                    Text(
                        "Surfing uses weather proxies only. Wave height, swell, "
                            + "tides, coastal suitability and water temperature "
                            + "are not included."
                    )
                }
            }
            .navigationTitle("About the scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
