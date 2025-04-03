import UIKit
import Photos

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    private var user: User?
    private let apiService = APIService.shared
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
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
        setupTableView()
        fetchUserInfo()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Settings"
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Data Fetching
    
    private func fetchUserInfo() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        
        apiService.getUserInfo { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.tableView.isHidden = false
                
                switch result {
                case .success(let user):
                    self.user = user
                    self.tableView.reloadData()
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
    
    private func handleUnauthorizedError() {
        AuthService.shared.logout()
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.presentLoginScreen()
        }
    }
    
    // MARK: - Actions
    
    private func logoutButtonTapped() {
        let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        
        present(alertController, animated: true)
    }
    
    private func logout() {
        AuthService.shared.logout()
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.presentLoginScreen()
        }
    }
    
    private func showPhotoPermissionsSettings() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        case .restricted, .denied:
            let alertController = UIAlertController(
                title: "Photo Library Access",
                message: "CloudStore needs access to your photos to upload them. Please enable access in Settings.",
                preferredStyle: .alert
            )
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            
            present(alertController, animated: true)
        case .authorized, .limited:
            showAlert(title: "Access Granted", message: "You already have photo library access.")
        @unknown default:
            break
        }
    }
    
    private func showCameraPermissionsSettings() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        case .restricted, .denied:
            let alertController = UIAlertController(
                title: "Camera Access",
                message: "CloudStore needs access to your camera to take photos. Please enable access in Settings.",
                preferredStyle: .alert
            )
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            
            present(alertController, animated: true)
        case .authorized:
            showAlert(title: "Access Granted", message: "You already have camera access.")
        @unknown default:
            break
        }
    }
    
    private func toggleAutoBackup(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: Constants.Settings.autoBackupEnabled)
        
        if isEnabled {
            // Check if we have photo permissions
            let status = PHPhotoLibrary.authorizationStatus()
            if status != .authorized && status != .limited {
                showPhotoPermissionsSettings()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2  // Account info
        case 1: return 1  // Auto backup
        case 2: return 2  // Permissions
        case 3: return 1  // Logout
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Account"
                cell.detailTextLabel?.text = nil
                if let user = user {
                    cell.detailTextLabel?.text = user.email
                }
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                cell.accessoryType = .none
                return cell
            case 1:
                cell.textLabel?.text = "Storage"
                if let user = user {
                    cell.detailTextLabel?.text = "\(user.storageUsedFormatted) of \(user.storageLimitFormatted)"
                }
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                cell.accessoryType = .none
                return cell
            default:
                return cell
            }
            
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.identifier, for: indexPath) as? SwitchTableViewCell else {
                return UITableViewCell()
            }
            
            let isAutoBackupEnabled = UserDefaults.standard.bool(forKey: Constants.Settings.autoBackupEnabled)
            cell.configure(title: "Auto Backup Photos", isOn: isAutoBackupEnabled) { [weak self] isOn in
                self?.toggleAutoBackup(isOn)
            }
            
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Photo Library Access"
                cell.accessoryType = .disclosureIndicator
                return cell
            case 1:
                cell.textLabel?.text = "Camera Access"
                cell.accessoryType = .disclosureIndicator
                return cell
            default:
                return cell
            }
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "Logout"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Account Information"
        case 1: return "Backup"
        case 2: return "Permissions"
        case 3: return nil
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 2:
            switch indexPath.row {
            case 0:
                showPhotoPermissionsSettings()
            case 1:
                showCameraPermissionsSettings()
            default:
                break
            }
        case 3:
            if indexPath.row == 0 {
                logoutButtonTapped()
            }
        default:
            break
        }
    }
}

// MARK: - SwitchTableViewCell

class SwitchTableViewCell: UITableViewCell {
    static let identifier = "SwitchTableViewCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = .systemBlue
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private var switchToggleHandler: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        selectionStyle = .none
    }
    
    func configure(title: String, isOn: Bool, handler: @escaping (Bool) -> Void) {
        titleLabel.text = title
        switchControl.isOn = isOn
        switchToggleHandler = handler
    }
    
    @objc private func switchValueChanged() {
        switchToggleHandler?(switchControl.isOn)
    }
}
