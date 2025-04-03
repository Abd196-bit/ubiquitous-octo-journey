import Foundation

struct Constants {
    
    struct Settings {
        static let autoBackupEnabled = "autoBackupEnabled"
        static let lastPhotoSyncDate = "lastPhotoSyncDate"
        static let uploadOriginalQuality = "uploadOriginalQuality"
        static let wifiOnlyUpload = "wifiOnlyUpload"
        static let deleteAfterUpload = "deleteAfterUpload"
        static let autoSyncEnabled = "autoSyncEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let userHasBeenOnboarded = "userHasBeenOnboarded"
    }
    
    struct API {
        static let baseURL = "http://localhost:8000/api"
        static let authLogin = "/auth/login"
        static let authRegister = "/auth/register"
        static let files = "/files"
        static let filesUpload = "/files/upload"
        static let filesDownload = "/files/download"
        static let user = "/user"
    }
    
    struct UserDefaults {
        static let userToken = "userToken"
        static let userId = "userId"
        static let userName = "userName"
        static let userEmail = "userEmail"
    }
    
    struct Keychain {
        static let serviceIdentifier = "com.cloudstore.app"
        static let tokenKey = "auth_token"
        static let userIdKey = "user_id"
    }
    
    struct ErrorMessages {
        static let loginFailed = "Failed to login. Please check your credentials and try again."
        static let registerFailed = "Failed to register. Please try again."
        static let networkError = "Network error. Please check your connection and try again."
        static let fileUploadFailed = "Failed to upload file. Please try again."
        static let fileDownloadFailed = "Failed to download file. Please try again."
        static let fileDeleteFailed = "Failed to delete file. Please try again."
        static let cameraAccessDenied = "Camera access denied. Please enable camera access in Settings."
        static let photoLibraryAccessDenied = "Photo library access denied. Please enable photo library access in Settings."
        static let unknownError = "An unknown error occurred. Please try again."
    }
    
    struct NotificationNames {
        static let userDidLogin = Notification.Name("userDidLogin")
        static let userDidLogout = Notification.Name("userDidLogout")
        static let fileUploadComplete = Notification.Name("fileUploadComplete")
        static let fileDownloadComplete = Notification.Name("fileDownloadComplete")
        static let fileDeleteComplete = Notification.Name("fileDeleteComplete")
        static let storageDidUpdate = Notification.Name("storageDidUpdate")
    }
    
    struct ContentTypes {
        static let jpeg = "image/jpeg"
        static let png = "image/png"
        static let pdf = "application/pdf"
        static let mp4 = "video/mp4"
        static let mp3 = "audio/mpeg"
        static let octetStream = "application/octet-stream"
    }
    
    struct FileExtensions {
        static let images = ["jpg", "jpeg", "png", "heic", "gif"]
        static let videos = ["mp4", "mov", "avi", "m4v"]
        static let documents = ["pdf", "doc", "docx", "txt", "rtf", "pages", "xlsx", "numbers"]
        static let audio = ["mp3", "wav", "aac", "m4a"]
    }
    
    struct UIConstants {
        static let cornerRadius: CGFloat = 12
        static let defaultPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let minTouchArea: CGFloat = 44
    }
}
