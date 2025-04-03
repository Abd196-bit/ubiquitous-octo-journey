import UIKit
import Photos

// MARK: - UIImage Extensions

extension UIImage {
    func scaled(to newSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return scaledImage
    }
    
    // Compress an image to reduce file size
    func compressed(quality: CGFloat = 0.7) -> UIImage? {
        guard let data = self.jpegData(compressionQuality: quality) else { return nil }
        return UIImage(data: data)
    }
    
    // Create thumbnail image
    func thumbnail(size: CGFloat = 200) -> UIImage? {
        let aspectRatio = self.size.width / self.size.height
        
        var newSize: CGSize
        if aspectRatio > 1 {
            // Landscape
            newSize = CGSize(width: size, height: size / aspectRatio)
        } else {
            // Portrait
            newSize = CGSize(width: size * aspectRatio, height: size)
        }
        
        return scaled(to: newSize)
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    func showActivityController(for url: URL, completion: (() -> Void)? = nil) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        activityController.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        
        // For iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            activityController.popoverPresentationController?.permittedArrowDirections = []
        }
        
        present(activityController, animated: true)
    }
}

// MARK: - PHAsset Extensions

extension PHAsset {
    func getImageData(completion: @escaping (Data?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .original
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImageDataAndOrientation(for: self, options: options) { (data, _, _, _) in
            completion(data)
        }
    }
    
    func getImage(targetSize: CGSize = PHImageManagerMaximumSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
            completion(image)
        }
    }
}

// MARK: - URLSession Extensions

extension URLSession {
    func dataTask(with url: URL, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: url) { data, response, error in
            if let error = error {
                result(.failure(error))
                return
            }
            
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response or data received"])
                result(.failure(error))
                return
            }
            
            result(.success((response, data)))
        }
    }
}

// MARK: - URL Extensions

extension URL {
    // Get file type based on file extension
    var fileType: FileType {
        let extension = self.pathExtension.lowercased()
        
        if ["jpg", "jpeg", "png", "gif", "heic"].contains(extension) {
            return .image
        } else if ["mp4", "mov", "avi", "wmv"].contains(extension) {
            return .video
        } else if ["pdf", "doc", "docx", "txt", "rtf", "xlsx", "pptx"].contains(extension) {
            return .document
        } else if ["mp3", "wav", "aac", "m4a"].contains(extension) {
            return .audio
        } else {
            return .other
        }
    }
}

// MARK: - FileManager Extensions

extension FileManager {
    func sizeOfFile(at url: URL) -> Int64 {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("Error getting file size: \(error)")
            return 0
        }
    }
    
    func clearTemporaryDirectory() {
        do {
            let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let contents = try contentsOfDirectory(at: tempDirectoryURL, includingPropertiesForKeys: nil)
            
            for fileURL in contents {
                try removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing temporary directory: \(error)")
        }
    }
}

// MARK: - Date Extensions

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }
        
        if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        }
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
        
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }
        
        return "Just now"
    }
    
    func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
