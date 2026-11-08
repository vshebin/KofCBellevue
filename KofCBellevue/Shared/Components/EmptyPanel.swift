//
//  EmptyPanel.swift
//  KofCBellevue
//
//  Created by Shebin on 11/6/26.
//
import SwiftUI

struct EmptyPanel: View {
    let symbol: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 38)).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(title).font(.headline)
            Text(subtitle).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(30).frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
