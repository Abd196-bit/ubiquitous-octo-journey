import Foundation
import Alamofire
import KeychainAccess

class AuthService {
    static let shared = AuthService()
    
    private let keychain = Keychain(service: "com.cloudstore.app")
    private let baseURL = "http://localhost:8000/api"
    
    private let tokenKey = "auth_token"
    private let userIdKey = "user_id"
    
    var token: String? {
        try? keychain.get(tokenKey)
    }
    
    var userId: String? {
        try? keychain.get(userIdKey)
    }
    
    var isUserLoggedIn: Bool {
        token != nil && userId != nil
    }
    
    private init() {}
    
    func login(email: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let credentials = UserCredentials(email: email, password: password)
        
        AF.request("\(baseURL)/auth/login",
                   method: .post,
                   parameters: credentials,
                   encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: AuthResponse.self) { response in
                switch response.result {
                case .success(let authResponse):
                    self.saveToken(authResponse.token)
                    self.saveUserId(authResponse.user.id)
                    completion(.success(authResponse.user))
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
    
    func register(name: String, email: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let parameters: [String: String] = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        AF.request("\(baseURL)/auth/register",
                   method: .post,
                   parameters: parameters,
                   encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: AuthResponse.self) { response in
                switch response.result {
                case .success(let authResponse):
                    self.saveToken(authResponse.token)
                    self.saveUserId(authResponse.user.id)
                    completion(.success(authResponse.user))
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
    
    func logout() {
        try? keychain.remove(tokenKey)
        try? keychain.remove(userIdKey)
        
        // Post notification that user logged out
        NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
    }
    
    private func saveToken(_ token: String) {
        try? keychain.set(token, key: tokenKey)
    }
    
    private func saveUserId(_ userId: String) {
        try? keychain.set(userId, key: userIdKey)
    }
}
