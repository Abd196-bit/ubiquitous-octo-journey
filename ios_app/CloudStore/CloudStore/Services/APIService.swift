import Foundation
import Alamofire

enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case unknown
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:8000/api"
    
    private init() {}
    
    // MARK: - File Operations
    
    func uploadFile(fileURL: URL, fileName: String, fileType: FileType, progress: @escaping (Float) -> Void, completion: @escaping (Result<FileItem, NetworkError>) -> Void) {
        guard let token = AuthService.shared.token else {
            completion(.failure(.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        AF.upload(
            multipartFormData: { multipartFormData in
                do {
                    let fileData = try Data(contentsOf: fileURL)
                    multipartFormData.append(fileData, withName: "file", fileName: fileName, mimeType: self.mimeTypeForFileType(fileType))
                    
                    if let typeData = fileType.rawValue.data(using: .utf8) {
                        multipartFormData.append(typeData, withName: "type")
                    }
                } catch {
                    print("Error loading file data: \(error)")
                }
            },
            to: "\(baseURL)/files/upload",
            headers: headers
        )
        .uploadProgress { progressData in
            progress(Float(progressData.fractionCompleted))
        }
        .responseDecodable(of: FileItem.self) { response in
            switch response.result {
            case .success(let fileItem):
                completion(.success(fileItem))
            case .failure(let error):
                if let data = response.data, let errorMessage = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorMessage["message"] {
                    completion(.failure(.serverError(message)))
                    return
                }
                completion(.failure(.requestFailed(error)))
            }
        }
    }
    
    func getFiles(completion: @escaping (Result<[FileItem], NetworkError>) -> Void) {
        guard let token = AuthService.shared.token else {
            completion(.failure(.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        AF.request("\(baseURL)/files", headers: headers)
            .validate()
            .responseDecodable(of: [FileItem].self) { response in
                switch response.result {
                case .success(let files):
                    completion(.success(files))
                case .failure(let error):
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        completion(.failure(.unauthorized))
                        return
                    }
                    completion(.failure(.requestFailed(error)))
                }
            }
    }
    
    func deleteFile(fileId: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        guard let token = AuthService.shared.token else {
            completion(.failure(.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        AF.request("\(baseURL)/files/\(fileId)", method: .delete, headers: headers)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 {
                            completion(.failure(.unauthorized))
                        } else {
                            completion(.failure(.requestFailed(error)))
                        }
                    } else {
                        completion(.failure(.requestFailed(error)))
                    }
                }
            }
    }
    
    func downloadFile(fileId: String, completion: @escaping (Result<URL, NetworkError>) -> Void) {
        guard let token = AuthService.shared.token else {
            completion(.failure(.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(fileId)_\(UUID().uuidString)")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download("\(baseURL)/files/\(fileId)/download", headers: headers, to: destination)
            .validate()
            .responseURL { response in
                switch response.result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        completion(.failure(.unauthorized))
                        return
                    }
                    completion(.failure(.requestFailed(error)))
                }
            }
    }
    
    // MARK: - User Operations
    
    func getUserInfo(completion: @escaping (Result<User, NetworkError>) -> Void) {
        guard let token = AuthService.shared.token else {
            completion(.failure(.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        
        AF.request("\(baseURL)/user", headers: headers)
            .validate()
            .responseDecodable(of: User.self) { response in
                switch response.result {
                case .success(let user):
                    completion(.success(user))
                case .failure(let error):
                    if let statusCode = response.response?.statusCode, statusCode == 401 {
                        completion(.failure(.unauthorized))
                        return
                    }
                    completion(.failure(.requestFailed(error)))
                }
            }
    }
    
    // MARK: - Helpers
    
    private func mimeTypeForFileType(_ fileType: FileType) -> String {
        switch fileType {
        case .image:
            return "image/jpeg"
        case .video:
            return "video/mp4"
        case .document:
            return "application/pdf"
        case .audio:
            return "audio/mpeg"
        case .other:
            return "application/octet-stream"
        }
    }
}
