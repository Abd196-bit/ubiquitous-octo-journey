import Foundation
import CoreData

enum FileType: String, Codable {
    case image
    case video
    case document
    case audio
    case other
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .document: return "doc.text"
        case .audio: return "music.note"
        case .other: return "questionmark.folder"
        }
    }
}

struct FileItem: Codable, Identifiable {
    let id: String
    let name: String
    let size: Int64
    let type: FileType
    let path: String
    let createdAt: Date
    let updatedAt: Date
    let userId: String
    let isUploaded: Bool
    let thumbnailUrl: String?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
    
    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension
    }
}

// FileItemEntity for CoreData
@objc(FileItemEntity)
class FileItemEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var size: Int64
    @NSManaged public var typeRaw: String
    @NSManaged public var path: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var userId: String
    @NSManaged public var isUploaded: Bool
    @NSManaged public var localPath: String?
    @NSManaged public var thumbnailUrl: String?
    @NSManaged public var uploadProgress: Float
    
    var type: FileType {
        get {
            return FileType(rawValue: typeRaw) ?? .other
        }
        set {
            typeRaw = newValue.rawValue
        }
    }
    
    func toFileItem() -> FileItem {
        return FileItem(
            id: id,
            name: name,
            size: size,
            type: type,
            path: path,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userId: userId,
            isUploaded: isUploaded,
            thumbnailUrl: thumbnailUrl
        )
    }
}

extension FileItemEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileItemEntity> {
        return NSFetchRequest<FileItemEntity>(entityName: "FileItemEntity")
    }
    
    static func createFrom(fileItem: FileItem, in context: NSManagedObjectContext) -> FileItemEntity {
        let entity = FileItemEntity(context: context)
        entity.id = fileItem.id
        entity.name = fileItem.name
        entity.size = fileItem.size
        entity.type = fileItem.type
        entity.path = fileItem.path
        entity.createdAt = fileItem.createdAt
        entity.updatedAt = fileItem.updatedAt
        entity.userId = fileItem.userId
        entity.isUploaded = fileItem.isUploaded
        entity.thumbnailUrl = fileItem.thumbnailUrl
        entity.uploadProgress = fileItem.isUploaded ? 1.0 : 0.0
        return entity
    }
}
