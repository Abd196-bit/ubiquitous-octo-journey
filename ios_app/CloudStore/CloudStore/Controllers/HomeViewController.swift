import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var user: User?
    private let apiService = APIService.shared
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let storageUsageView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let storageUsageLabel: UILabel = {
        let label = UILabel()
        label.text = "Storage Usage"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let storageProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemBlue
        progressView.layer.cornerRadius = 6
        progressView.clipsToBounds = true
        progressView.layer.borderWidth = 0.5
        progressView.layer.borderColor = UIColor.systemGray4.cgColor
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let storageDetailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quickActionsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quick Actions"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var uploadPhotosButton: UIButton = {
        let button = createQuickActionButton(title: "Upload Photos", imageName: "photo")
        button.addTarget(self, action: #selector(uploadPhotosButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var takePictureButton: UIButton = {
        let button = createQuickActionButton(title: "Take Picture", imageName: "camera")
        button.addTarget(self, action: #selector(takePictureButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var browseFilesButton: UIButton = {
        let button = createQuickActionButton(title: "Browse Files", imageName: "folder")
        button.addTarget(self, action: #selector(browseFilesButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = createQuickActionButton(title: "Settings", imageName: "gear")
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data each time the view appears
        fetchUserInfo()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "CloudStore"
        
        // Add refresh button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
        
        // Setup scroll view and content
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(welcomeLabel)
        contentView.addSubview(storageUsageView)
        contentView.addSubview(quickActionsTitleLabel)
        contentView.addSubview(uploadPhotosButton)
        contentView.addSubview(takePictureButton)
        contentView.addSubview(browseFilesButton)
        contentView.addSubview(settingsButton)
        contentView.addSubview(activityIndicator)
        
        // Setup storage usage view
        storageUsageView.addSubview(storageUsageLabel)
        storageUsageView.addSubview(storageProgressView)
        storageUsageView.addSubview(storageDetailsLabel)
        
        setupConstraints()
        
        // Start with loading state
        activityIndicator.startAnimating()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            welcomeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            storageUsageView.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            storageUsageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            storageUsageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            storageUsageLabel.topAnchor.constraint(equalTo: storageUsageView.topAnchor, constant: 16),
            storageUsageLabel.leadingAnchor.constraint(equalTo: storageUsageView.leadingAnchor, constant: 16),
            storageUsageLabel.trailingAnchor.constraint(equalTo: storageUsageView.trailingAnchor, constant: -16),
            
            storageProgressView.topAnchor.constraint(equalTo: storageUsageLabel.bottomAnchor, constant: 16),
            storageProgressView.leadingAnchor.constraint(equalTo: storageUsageView.leadingAnchor, constant: 16),
            storageProgressView.trailingAnchor.constraint(equalTo: storageUsageView.trailingAnchor, constant: -16),
            storageProgressView.heightAnchor.constraint(equalToConstant: 8),
            
            storageDetailsLabel.topAnchor.constraint(equalTo: storageProgressView.bottomAnchor, constant: 12),
            storageDetailsLabel.leadingAnchor.constraint(equalTo: storageUsageView.leadingAnchor, constant: 16),
            storageDetailsLabel.trailingAnchor.constraint(equalTo: storageUsageView.trailingAnchor, constant: -16),
            storageDetailsLabel.bottomAnchor.constraint(equalTo: storageUsageView.bottomAnchor, constant: -16),
            
            quickActionsTitleLabel.topAnchor.constraint(equalTo: storageUsageView.bottomAnchor, constant: 30),
            quickActionsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickActionsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            uploadPhotosButton.topAnchor.constraint(equalTo: quickActionsTitleLabel.bottomAnchor, constant: 20),
            uploadPhotosButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            uploadPhotosButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            uploadPhotosButton.heightAnchor.constraint(equalToConstant: 120),
            
            takePictureButton.topAnchor.constraint(equalTo: quickActionsTitleLabel.bottomAnchor, constant: 20),
            takePictureButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            takePictureButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            takePictureButton.heightAnchor.constraint(equalToConstant: 120),
            
            browseFilesButton.topAnchor.constraint(equalTo: uploadPhotosButton.bottomAnchor, constant: 16),
            browseFilesButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            browseFilesButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            browseFilesButton.heightAnchor.constraint(equalToConstant: 120),
            
            settingsButton.topAnchor.constraint(equalTo: takePictureButton.bottomAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            settingsButton.heightAnchor.constraint(equalToConstant: 120),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: browseFilesButton.bottomAnchor, constant: 30),
            activityIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createQuickActionButton(title: String, imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.05).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 16
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add shadows and styling
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 5
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Using larger, filled SF Symbols for better visibility
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        let filledImageName = imageName + ".fill"
        let image = UIImage(systemName: filledImageName, withConfiguration: config) ?? 
                   UIImage(systemName: imageName, withConfiguration: config)
                   
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        button.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 48),
            imageView.widthAnchor.constraint(equalToConstant: 48),
            
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        // Add frame resizing callback to update gradient
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layoutIfNeeded()
        
        // Update gradient frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = button.bounds
        CATransaction.commit()
        
        return button
    }
    
    // MARK: - Data Fetching
    
    private func fetchUserInfo() {
        activityIndicator.startAnimating()
        
        apiService.getUserInfo { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let user):
                    self.user = user
                    self.updateUI(with: user)
                case .failure(let error):
                    if case .unauthorized = error {
                        self.handleUnauthorizedError()
                    } else {
                        self.showAlert(title: "Error", message: "Failed to load user information.")
                    }
                }
            }
        }
    }
    
    private func updateUI(with user: User) {
        welcomeLabel.text = "Welcome, \(user.name)"
        storageProgressView.progress = user.storagePercentageUsed
        storageDetailsLabel.text = "\(user.storageUsedFormatted) used of \(user.storageLimitFormatted)"
    }
    
    private func handleUnauthorizedError() {
        AuthService.shared.logout()
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.presentLoginScreen()
        }
    }
    
    // MARK: - Actions
    
    @objc private func refreshData() {
        fetchUserInfo()
    }
    
    @objc private func uploadPhotosButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @objc private func takePictureButtonTapped() {
        let cameraVC = CameraViewController()
        navigationController?.pushViewController(cameraVC, animated: true)
    }
    
    @objc private func browseFilesButtonTapped() {
        tabBarController?.selectedIndex = 1
    }
    
    @objc private func settingsButtonTapped() {
        tabBarController?.selectedIndex = 3
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            showAlert(title: "Error", message: "Failed to get image from picker")
            return
        }
        
        // Start uploading
        let loadingAlert = UIAlertController(title: "Uploading", message: "Uploading image...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        let fileUploadService = FileUploadService()
        fileUploadService.uploadImage(image: image) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    switch result {
                    case .success:
                        self.showAlert(title: "Success", message: "Image uploaded successfully")
                        self.fetchUserInfo() // Refresh user info
                    case .failure:
                        self.showAlert(title: "Error", message: "Failed to upload image")
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
