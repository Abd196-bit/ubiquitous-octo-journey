import UIKit
import CoreData
import QuickLook

class FileBrowserViewController: UIViewController {
    
    // MARK: - Properties
    
    private var files: [FileItem] = []
    private var filteredFiles: [FileItem] = []
    private var selectedType: FileType?
    private let apiService = APIService.shared
    private var previewController: QLPreviewController?
    private var previewItem: PreviewItem?
    
    // MARK: - UI Components
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(FileCell.self, forCellReuseIdentifier: FileCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let noFilesView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let noFilesImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "doc.text.magnifyingglass")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let noFilesLabel: UILabel = {
        let label = UILabel()
        label.text = "No files found"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let filterSegmentedControl: UISegmentedControl = {
        let items = ["All", "Images", "Videos", "Docs", "Other"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        setupTableView()
        fetchFiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFiles()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Files"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshFiles))
        
        view.addSubview(filterSegmentedControl)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        setupNoFilesView()
        
        NSLayoutConstraint.activate([
            filterSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }
    
    private func setupNoFilesView() {
        noFilesView.addSubview(noFilesImageView)
        noFilesView.addSubview(noFilesLabel)
        view.addSubview(noFilesView)
        
        NSLayoutConstraint.activate([
            noFilesView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noFilesView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noFilesView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            noFilesView.heightAnchor.constraint(equalToConstant: 200),
            
            noFilesImageView.topAnchor.constraint(equalTo: noFilesView.topAnchor),
            noFilesImageView.centerXAnchor.constraint(equalTo: noFilesView.centerXAnchor),
            noFilesImageView.widthAnchor.constraint(equalToConstant: 80),
            noFilesImageView.heightAnchor.constraint(equalToConstant: 80),
            
            noFilesLabel.topAnchor.constraint(equalTo: noFilesImageView.bottomAnchor, constant: 16),
            noFilesLabel.leadingAnchor.constraint(equalTo: noFilesView.leadingAnchor),
            noFilesLabel.trailingAnchor.constraint(equalTo: noFilesView.trailingAnchor),
            noFilesLabel.bottomAnchor.constraint(equalTo: noFilesView.bottomAnchor)
        ])
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Set search bar text color
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .label
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(refreshFiles), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Data Fetching
    
    private func fetchFiles() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        noFilesView.isHidden = true
        
        apiService.getFiles { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let files):
                    self.files = files
                    self.applyFilter()
                    self.tableView.isHidden = false
                    self.updateNoFilesView()
                case .failure(let error):
                    if case .unauthorized = error {
                        self.handleUnauthorizedError()
                    } else {
                        self.showAlert(title: "Error", message: "Failed to load files.")
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
    
    private func updateNoFilesView() {
        if filteredFiles.isEmpty {
            noFilesView.isHidden = false
            if let searchText = searchController.searchBar.text, !searchText.isEmpty {
                noFilesLabel.text = "No files matching '\(searchText)'"
            } else if selectedType != nil {
                let typeString = selectedType == .image ? "images" :
                                selectedType == .video ? "videos" :
                                selectedType == .document ? "documents" :
                                selectedType == .audio ? "audio files" : "files"
                noFilesLabel.text = "No \(typeString) found"
            } else {
                noFilesLabel.text = "No files found"
            }
        } else {
            noFilesView.isHidden = true
        }
    }
    
    // MARK: - Filtering
    
    private func applyFilter() {
        // First apply type filter
        var tempFilteredFiles = files
        
        if let selectedType = selectedType {
            tempFilteredFiles = files.filter { $0.type == selectedType }
        }
        
        // Then apply search filter if needed
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            tempFilteredFiles = tempFilteredFiles.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        filteredFiles = tempFilteredFiles
        tableView.reloadData()
        updateNoFilesView()
    }
    
    @objc private func filterChanged() {
        let selectedIndex = filterSegmentedControl.selectedSegmentIndex
        
        switch selectedIndex {
        case 0:
            selectedType = nil
        case 1:
            selectedType = .image
        case 2:
            selectedType = .video
        case 3:
            selectedType = .document
        case 4:
            selectedType = .other
        default:
            selectedType = nil
        }
        
        applyFilter()
    }
    
    // MARK: - Actions
    
    @objc private func refreshFiles() {
        fetchFiles()
    }
    
    // MARK: - File Operations
    
    private func deleteFile(at indexPath: IndexPath) {
        let file = filteredFiles[indexPath.row]
        
        activityIndicator.startAnimating()
        
        apiService.deleteFile(fileId: file.id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success:
                    if let index = self.files.firstIndex(where: { $0.id == file.id }) {
                        self.files.remove(at: index)
                    }
                    self.filteredFiles.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateNoFilesView()
                case .failure:
                    self.showAlert(title: "Error", message: "Failed to delete file.")
                }
            }
        }
    }
    
    private func downloadAndPreviewFile(_ file: FileItem) {
        activityIndicator.startAnimating()
        
        apiService.downloadFile(fileId: file.id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let url):
                    self.previewItem = PreviewItem(url: url, title: file.name)
                    self.showPreview()
                case .failure:
                    self.showAlert(title: "Error", message: "Failed to download file.")
                }
            }
        }
    }
    
    private func showPreview() {
        guard let previewItem = previewItem else { return }
        
        previewController = QLPreviewController()
        previewController?.dataSource = self
        previewController?.delegate = self
        
        present(previewController!, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension FileBrowserViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FileCell.identifier, for: indexPath) as? FileCell else {
            return UITableViewCell()
        }
        
        let file = filteredFiles[indexPath.row]
        cell.configure(with: file)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let file = filteredFiles[indexPath.row]
        downloadAndPreviewFile(file)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.deleteFile(at: indexPath)
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}

// MARK: - UISearchResultsUpdating

extension FileBrowserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}

// MARK: - QLPreviewControllerDelegate, QLPreviewControllerDataSource

extension FileBrowserViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return previewItem != nil ? 1 : 0
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        previewController = nil
    }
}

// MARK: - PreviewItem

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL, title: String) {
        self.previewItemURL = url
        self.previewItemTitle = title
        super.init()
    }
}
