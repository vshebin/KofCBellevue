//
//  SideMenuView.swift
//  KofCBellevue
//
//  Created by Shebin on 11/7/26.
//

import SwiftUI

struct SideMenuView: View {
    let selectedDestination: SideMenuDestination
    let accent: Color

    let onSelect: (SideMenuDestination) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    menuItems(SideMenuDestination.mainItems)

                    sectionTitle("Meeting Minutes")
                    menuItems(SideMenuDestination.minutesItems)
                    
                    sectionTitle("Content Management")
                    menuItems(SideMenuDestination.managementItems)

                    Text(
                        "Publishing is a UI preview until login "
                        + "and permissions are connected."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    Divider()
                        .padding(.vertical, 8)

                }
                .padding(16)
            }

            Divider()

            Text("UI preview • No live account or publishing")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(20)
        }
        .background(
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.title)
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)

                Text("KofC Bellevue")
                    .font(.title2.bold())

                Text("Council menu")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close menu")
        }
        .padding(20)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func menuItems(
        _ destinations: [SideMenuDestination]
    ) -> some View {
        ForEach(destinations) { destination in
            menuButton(destination)
        }
    }

    private func menuButton(
        _ destination: SideMenuDestination
    ) -> some View {
        let isSelected = selectedDestination == destination

        return Button {
            onSelect(destination)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: destination.systemImage)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(destination.title)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .font(.headline)
            .foregroundStyle(isSelected ? accent : Color.primary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? accent.opacity(0.12) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
