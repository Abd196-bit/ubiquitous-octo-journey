import Foundation

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let storageUsed: Int64
    let storageLimit: Int64
    
    var storageUsedFormatted: String {
        ByteCountFormatter.string(fromByteCount: storageUsed, countStyle: .file)
    }
    
    var storageLimitFormatted: String {
        ByteCountFormatter.string(fromByteCount: storageLimit, countStyle: .file)
    }
    
    var storagePercentageUsed: Float {
        if storageLimit == 0 { return 0 }
        return Float(storageUsed) / Float(storageLimit)
    }
}

struct UserCredentials: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}
