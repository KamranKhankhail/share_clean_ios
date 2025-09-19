import UIKit
import Photos

enum PhotoLibraryError: Error {
    case unauthorized
    case albumCreationFailed
    case saveFailed(Error)
}

final class PhotoLibraryManager {
    func save(images: [UIImage], albumName: String) async throws {
        let authStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authStatus == .authorized || authStatus == .limited else {
            throw PhotoLibraryError.unauthorized
        }
        
        guard let album = await getOrCreateAlbum(named: albumName) else {
            throw PhotoLibraryError.albumCreationFailed
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let reqs = images.map { PHAssetChangeRequest.creationRequestForAsset(from: $0) }
                let ph = reqs.compactMap { $0.placeholderForCreatedAsset }
                PHAssetCollectionChangeRequest(for: album)?.addAssets(ph as NSArray)
            }
        } catch {
            throw PhotoLibraryError.saveFailed(error)
        }
    }
    private func getOrCreateAlbum(named: String) async -> PHAssetCollection? {
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var found: PHAssetCollection?
        fetch.enumerateObjects { col,_,stop in if col.localizedTitle == named { found = col; stop.pointee = true } }
        if let f = found { return f }
        
        var placeholder: PHObjectPlaceholder?
        do {
            try await PHPhotoLibrary.shared().performChanges {
                placeholder = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: named).placeholderForCreatedAssetCollection
            }
        } catch {
            print("Failed to create album: \(error)")
            return nil
        }
        
        if let id = placeholder?.localIdentifier {
            return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject
        }
        return nil
    }
}
