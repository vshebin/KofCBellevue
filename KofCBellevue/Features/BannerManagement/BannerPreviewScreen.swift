import SwiftUI

struct BannerPreviewScreen: View {
    let banner: BannerContent
    var imageData: Data? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HomeBannerCard(banner: banner, imageOverride: imageData.flatMap { UIImage(data: $0) })
                    .frame(height: 285)
                Text("Preview only. Nothing is published from this screen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
        .navigationTitle("Banner Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}
