import Foundation
import UIKit
import Photos
import CoreData

enum UploadError: Error {
    case fileNotFound
    case accessDenied
    case uploadFailed
    case networkError
}

class FileUploadService {
    private let apiService = APIService.shared
    
    // MARK: - File Upload Methods
    
    func uploadFile(from url: URL, type: FileType, completion: @escaping (Result<FileItem, UploadError>) -> Void) {
        let fileName = url.lastPathComponent
        
        apiService.uploadFile(fileURL: url, fileName: fileName, fileType: type, progress: { _ in
            // Progress handling if needed
        }) { result in
            switch result {
            case .success(let fileItem):
                self.saveFileItemToLocalStorage(fileItem)
                completion(.success(fileItem))
            case .failure:
                completion(.failure(.uploadFailed))
            }
        }
    }
    
    func uploadImage(image: UIImage, fileName: String = "image.jpg", completion: @escaping (Result<FileItem, UploadError>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(.fileNotFound))
            return
        }
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            
            apiService.uploadFile(fileURL: fileURL, fileName: fileName, fileType: .image, progress: { _ in
                // Progress handling if needed
            }) { result in
                // Clean up temporary file
                try? FileManager.default.removeItem(at: fileURL)
                
                switch result {
                case .success(let fileItem):
                    self.saveFileItemToLocalStorage(fileItem)
                    completion(.success(fileItem))
                case .failure:
                    completion(.failure(.uploadFailed))
                }
            }
        } catch {
            completion(.failure(.fileNotFound))
        }
    }
    
    // MARK: - Background Sync
    
    func performBackgroundSync(completion: @escaping (Result<Int, Error>) -> Void) {
        checkPendingUploads { result in
            switch result {
            case .success(let count):
                completion(.success(count))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func checkPendingUploads(completion: @escaping (Result<Int, Error>) -> Void) {
        guard UserDefaults.standard.bool(forKey: Constants.Settings.autoBackupEnabled) else {
            completion(.success(0))
            return
        }
        
        let photoLibrary = PHPhotoLibrary.shared()
        
        // Request authorization
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure(UploadError.accessDenied))
                return
            }
            
            // Get last sync date
            let lastSyncDate = UserDefaults.standard.object(forKey: Constants.Settings.lastPhotoSyncDate) as? Date ?? Date.distantPast
            
            // Fetch new photos
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "creationDate > %@", lastSyncDate as NSDate)
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let assetsFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            var uploadedCount = 0
            let group = DispatchGroup()
            
            assetsFetchResult.enumerateObjects { (asset, index, stopPointer) in
                group.enter()
                
                let imageManager = PHImageManager.default()
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                
                imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { (image, info) in
                    guard let image = image else {
                        group.leave()
                        return
                    }
                    
                    // Generate a unique filename based on asset local identifier
                    let fileName = "photo_\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).jpg"
                    
                    // Upload the image
                    self.uploadImage(image: image, fileName: fileName) { result in
                        switch result {
                        case .success:
                            uploadedCount += 1
                        case .failure:
                            // Just continue with the next one
                            break
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                // Update last sync date
                UserDefaults.standard.set(Date(), forKey: Constants.Settings.lastPhotoSyncDate)
                completion(.success(uploadedCount))
            }
        }
    }
    
    // MARK: - CoreData Storage
    
    private func saveFileItemToLocalStorage(_ fileItem: FileItem) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Check if file already exists
        let fetchRequest: NSFetchRequest<FileItemEntity> = FileItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", fileItem.id)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingFile = results.first {
                // Update existing file
                existingFile.name = fileItem.name
                existingFile.size = fileItem.size
                existingFile.type = fileItem.type
                existingFile.path = fileItem.path
                existingFile.updatedAt = fileItem.updatedAt
                existingFile.isUploaded = fileItem.isUploaded
                existingFile.thumbnailUrl = fileItem.thumbnailUrl
                existingFile.uploadProgress = 1.0
            } else {
                // Create new file entity
                _ = FileItemEntity.createFrom(fileItem: fileItem, in: context)
            }
            
            try context.save()
        } catch {
            print("Error saving file item to Core Data: \(error)")
        }
    }
}
