import UIKit

protocol FileDetailsViewDelegate: AnyObject {
    func deleteFileTapped(_ file: FileItem)
    func downloadFileTapped(_ file: FileItem)
    func shareFileTapped(_ file: FileItem)
}

class FileDetailsView: UIView {
    
    // MARK: - Properties
    
    private var file: FileItem?
    weak var delegate: FileDetailsViewDelegate?
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fileIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionButtonsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = createActionButton(title: "Download", imageName: "arrow.down.circle")
        button.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = createActionButton(title: "Delete", imageName: "trash")
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shareButton: UIButton = {
        let button = createActionButton(title: "Share", imageName: "square.and.arrow.up")
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(fileIconImageView)
        headerView.addSubview(fileNameLabel)
        
        contentView.addSubview(detailsView)
        detailsView.addSubview(fileSizeLabel)
        detailsView.addSubview(fileDateLabel)
        detailsView.addSubview(fileTypeLabel)
        
        contentView.addSubview(actionButtonsStack)
        actionButtonsStack.addArrangedSubview(downloadButton)
        actionButtonsStack.addArrangedSubview(shareButton)
        actionButtonsStack.addArrangedSubview(deleteButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            fileIconImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            fileIconImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            fileIconImageView.widthAnchor.constraint(equalToConstant: 80),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            fileNameLabel.topAnchor.constraint(equalTo: fileIconImageView.bottomAnchor, constant: 16),
            fileNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            fileNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            fileNameLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20),
            
            detailsView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            detailsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            detailsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            fileSizeLabel.topAnchor.constraint(equalTo: detailsView.topAnchor, constant: 16),
            fileSizeLabel.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            fileSizeLabel.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            
            fileDateLabel.topAnchor.constraint(equalTo: fileSizeLabel.bottomAnchor, constant: 12),
            fileDateLabel.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            fileDateLabel.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            
            fileTypeLabel.topAnchor.constraint(equalTo: fileDateLabel.bottomAnchor, constant: 12),
            fileTypeLabel.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            fileTypeLabel.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            fileTypeLabel.bottomAnchor.constraint(equalTo: detailsView.bottomAnchor, constant: -16),
            
            actionButtonsStack.topAnchor.constraint(equalTo: detailsView.bottomAnchor, constant: 20),
            actionButtonsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionButtonsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionButtonsStack.heightAnchor.constraint(equalToConstant: 100),
            actionButtonsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createActionButton(title: String, imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: imageName))
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        button.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 30),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    // MARK: - Configuration
    
    func configure(with file: FileItem) {
        self.file = file
        
        fileNameLabel.text = file.name
        fileSizeLabel.text = "Size: \(file.formattedSize)"
        fileDateLabel.text = "Modified: \(file.formattedDate)"
        fileTypeLabel.text = "Type: \(file.type.rawValue.capitalized)"
        fileIconImageView.image = UIImage(systemName: file.type.icon)
    }
    
    // MARK: - Actions
    
    @objc private func downloadButtonTapped() {
        guard let file = file else { return }
        delegate?.downloadFileTapped(file)
    }
    
    @objc private func deleteButtonTapped() {
        guard let file = file else { return }
        delegate?.deleteFileTapped(file)
    }
    
    @objc private func shareButtonTapped() {
        guard let file = file else { return }
        delegate?.shareFileTapped(file)
    }
}
