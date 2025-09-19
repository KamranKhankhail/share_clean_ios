import UIKit
import Photos

final class PhotoLibraryManager {
    func save(images: [UIImage], albumName: String) async {
        _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard let album = await getOrCreateAlbum(named: albumName) else { return }
        try? await PHPhotoLibrary.shared().performChanges {
            let reqs = images.map { PHAssetChangeRequest.creationRequestForAsset(from: $0) }
            let ph = reqs.compactMap { $0.placeholderForCreatedAsset }
            PHAssetCollectionChangeRequest(for: album)?.addAssets(ph as NSArray)
        }
    }
    private func getOrCreateAlbum(named: String) async -> PHAssetCollection? {
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var found: PHAssetCollection?
        fetch.enumerateObjects { col,_,stop in if col.localizedTitle == named { found = col; stop.pointee = true } }
        if let f = found { return f }
        var placeholder: PHObjectPlaceholder?
        try? await PHPhotoLibrary.shared().performChanges {
            placeholder = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: named).placeholderForCreatedAssetCollection
        }
        if let id = placeholder?.localIdentifier {
            return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject
        }
        return nil
    }
}
