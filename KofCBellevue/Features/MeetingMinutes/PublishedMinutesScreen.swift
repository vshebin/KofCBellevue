//
//  PublishedMinutesScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import SwiftUI

struct PublishedMinutesScreen: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(LocalMinutesStorage.publishedTitleKey)
    private var publishedTitle = ""

    @AppStorage(LocalMinutesStorage.publishedBodyKey)
    private var publishedBody = ""

    private var publishedDate: Date? {
        UserDefaults.standard.object(
            forKey: LocalMinutesStorage.publishedDateKey
        ) as? Date
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if publishedBody.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty {
                    ContentUnavailableView(
                        "No Published Minutes",
                        systemImage: "doc.text",
                        description: Text(
                            "Published meeting minutes will appear here."
                        )
                    )
                } else {
                    Label(
                        "MEETING MINUTES",
                        systemImage: "doc.text.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Text(publishedTitle)
                        .font(.title.bold())
                        .textSelection(.enabled)

                    if let publishedDate {
                        Text(
                            "Published \(publishedDate.formatted(date: .abbreviated, time: .omitted))"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text(publishedBody)
                        .font(.body)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .textSelection(.enabled)
                }
            }
            .padding(24)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .navigationTitle("Meeting Minutes")
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
