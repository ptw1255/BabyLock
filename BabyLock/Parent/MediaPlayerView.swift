import SwiftUI
import PhotosUI
import AVKit

struct MediaPickerButton: View {
    let contentManager: ContentManager
    let onSelected: (ContentSource) -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .any(of: [.videos, .images])) {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadItem(newItem)
            }
        }
    }

    private func loadItem(_ item: PhotosPickerItem) async {
        // Try video first
        if let videoData = try? await item.loadTransferable(type: VideoTransferable.self) {
            await MainActor.run {
                contentManager.loadVideo(videoData.url)
                onSelected(.localVideo(videoData.url))
            }
            return
        }

        // Try image
        if let imageData = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: imageData) {
            await MainActor.run {
                contentManager.loadPhoto(image)
                onSelected(.localPhoto(URL(string: "local://photo")!))
            }
        }
    }
}

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

struct MediaPlayerView: View {
    let contentManager: ContentManager
    let contentSource: ContentSource

    var body: some View {
        switch contentSource {
        case .localVideo:
            if let player = contentManager.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
        case .localPhoto:
            if let image = contentManager.photoImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.black)
            }
        default:
            EmptyView()
        }
    }
}
