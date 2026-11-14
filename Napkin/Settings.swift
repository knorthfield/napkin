import SwiftUI

enum DecimalPlaces {
    static let key = "DecimalPlaces"
    static let standard = 2
}

struct SettingsView: View {
    let rates: CurrencyRates
    @AppStorage(DecimalPlaces.key) private var decimalPlaces = DecimalPlaces.standard

    var body: some View {
        Form {
            Section {
                Picker("Decimal places", selection: $decimalPlaces) {
                    ForEach(0...8, id: \.self) { Text("\($0)").tag($0) }
                }
            } header: {
                Text("Results")
            } footer: {
                Text("Money always shows 2 decimal places.")
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Exchange rates") {
                    Text(rates.date.map { "From \($0)" } ?? "Not available")
                }
            } header: {
                Text("Currencies")
            } footer: {
                Text("Rates of the European Central Bank, from frankfurter.dev. Napkin gets them when it opens, if its rates are more than 12 hours old.")
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Notes folder") {
                    Button("Show in Finder") { NSWorkspace.shared.open(NoteStore.defaultFolder) }
                }
            } header: {
                Text("Notes")
            } footer: {
                Text("Each note is a Markdown file.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }
}
