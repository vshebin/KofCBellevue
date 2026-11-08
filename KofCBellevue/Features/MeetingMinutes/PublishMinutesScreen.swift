//
//  PublishMinutesScreen.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import SwiftUI

// Local-only storage shared by the editor and Home banner.
// This prototype supports one draft and one published MOM.
enum LocalMinutesStorage {
    static let draftTitleKey = "mom.draft.title"
    static let draftBodyKey = "mom.draft.body"

    static let publishedTitleKey = "mom.published.title"
    static let publishedBodyKey = "mom.published.body"
    static let publishedDateKey = "mom.published.date"

    @MainActor
    static func refreshBanner(
        in bannerModel: BannerManagementViewModel
    ) {
        let defaults = UserDefaults.standard

        let title = defaults.string(
            forKey: publishedTitleKey
        ) ?? ""

        let body = defaults.string(
            forKey: publishedBodyKey
        ) ?? ""

        guard !title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty,
        !body.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            bannerModel.setLatestMinutesBanner(nil)
            return
        }

        let publishedDate = defaults.object(
            forKey: publishedDateKey
        ) as? Date

        let subtitle: String

        if let publishedDate {
            subtitle = "Published \(publishedDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            subtitle = "Published meeting minutes"
        }

        bannerModel.setLatestMinutesBanner(
            BannerContent(
                slot: .minutes,
                title: title,
                subtitle: subtitle,
                imageDescription: "Published meeting minutes",
                isPublished: true,
                isEnabled: true
            )
        )
    }
}

struct PublishMinutesScreen: View {
    @EnvironmentObject private var bannerModel:
        BannerManagementViewModel

    @AppStorage(LocalMinutesStorage.draftTitleKey)
    private var savedDraftTitle = ""

    @AppStorage(LocalMinutesStorage.draftBodyKey)
    private var savedDraftBody = ""

    @State private var title = ""
    @State private var minutesBody = ""

    @State private var loadedDraft = false
    @State private var showPreview = false
    @State private var showPublishConfirmation = false

    @State private var showMessage = false
    @State private var messageTitle = ""
    @State private var messageText = ""

    private var canPublish: Bool {
        !title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty &&
        !minutesBody.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    var body: some View {
        Form {
            Section("Meeting title") {
                TextField(
                    "For example: November Council Meeting",
                    text: $title,
                    axis: .vertical
                )
            }

            Section("Minutes of meeting") {
                TextEditor(text: $minutesBody)
                    .frame(minHeight: 300)
                    .accessibilityLabel("Meeting minutes")
            }

            Section {
                Button("Save Draft") {
                    saveDraft()

                    notify(
                        title: "Draft Saved",
                        text: "Your draft is saved on this device."
                    )
                }

                Button("Preview") {
                    showPreview = true
                }
                .disabled(!canPublish)

                Button("Publish on This Device") {
                    showPublishConfirmation = true
                }
                .disabled(!canPublish)
            } footer: {
                Text(
                    """
                    Publishing updates Banner 5 on this device. \
                    It replaces the previous locally published MOM. \
                    It does not send anything to other members.
                    """
                )
            }
        }
        .navigationTitle("Publish Minutes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !loadedDraft else { return }

            title = savedDraftTitle
            minutesBody = savedDraftBody
            loadedDraft = true
        }
        .sheet(isPresented: $showPreview) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(title)
                            .font(.title.bold())

                        Text(minutesBody)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .textSelection(.enabled)
                    }
                    .padding()
                }
                .navigationTitle("MOM Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(
                        placement: .confirmationAction
                    ) {
                        Button("Done") {
                            showPreview = false
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Publish these minutes on this device?",
            isPresented: $showPublishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Publish Locally") {
                publish()
            }
        } message: {
            Text(
                """
                This replaces the previous locally published MOM \
                and updates Banner 5 on Home.
                """
            )
        }
        .alert(
            messageTitle,
            isPresented: $showMessage
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(messageText)
        }
    }

    private func saveDraft() {
        savedDraftTitle = title
        savedDraftBody = minutesBody
    }

    private func publish() {
        guard canPublish else { return }
        
        // Capture the completed MOM before clearing the form.
        let publishedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let publishedBody = minutesBody.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let defaults = UserDefaults.standard
        
        // Save the published MOM separately from the draft.
        defaults.set(
            publishedTitle,
            forKey: LocalMinutesStorage.publishedTitleKey
        )
        
        defaults.set(
            publishedBody,
            forKey: LocalMinutesStorage.publishedBodyKey
        )
        
        defaults.set(
            Date(),
            forKey: LocalMinutesStorage.publishedDateKey
        )
        
        // Update Home using the saved published content.
        LocalMinutesStorage.refreshBanner(in: bannerModel)
        
        // Clear the saved draft and editor for the next MOM.
        savedDraftTitle = ""
        savedDraftBody = ""
        
        title = ""
        minutesBody = ""
        
        notify(
            title: "Minutes Published",
            text: """
                Your MOM is published on this device.
                The form is now ready for a new meeting.
                """
        )
    }

    private func notify(title: String, text: String) {
        messageTitle = title
        messageText = text
        showMessage = true
    }
}

#Preview("Publish Minutes") {
    NavigationStack {
        PublishMinutesScreen()
    }
    .environmentObject(
        BannerManagementViewModel(
            repository: LocalBannerRepository()
        )
    )
}
