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
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fileIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        // Create a circular background for the icon
        imageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.tintColor = .systemBlue
        
        // Add subtle glow effect
        imageView.layer.shadowColor = UIColor.systemBlue.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowOpacity = 0.2
        imageView.layer.shadowRadius = 4
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Create an attributed string with icon
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "arrow.down.doc.fill")?.withTintColor(.systemBlue)
        let attributedString = NSMutableAttributedString(attachment: attachment)
        attributedString.append(NSAttributedString(string: "  Size: "))
        label.attributedText = attributedString
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Create an attributed string with icon
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "calendar")?.withTintColor(.systemBlue)
        let attributedString = NSMutableAttributedString(attachment: attachment)
        attributedString.append(NSAttributedString(string: "  Modified: "))
        label.attributedText = attributedString
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Create an attributed string with icon
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "doc.text.fill")?.withTintColor(.systemBlue)
        let attributedString = NSMutableAttributedString(attachment: attachment)
        attributedString.append(NSAttributedString(string: "  Type: "))
        label.attributedText = attributedString
        
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
        
        // Modern button appearance
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        if title == "Delete" {
            gradientLayer.colors = [
                UIColor.systemRed.withAlphaComponent(0.2).cgColor,
                UIColor.systemRed.withAlphaComponent(0.1).cgColor
            ]
        } else {
            gradientLayer.colors = [
                UIColor.systemBlue.withAlphaComponent(0.15).cgColor,
                UIColor.systemBlue.withAlphaComponent(0.05).cgColor
            ]
        }
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 16
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add styling
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
        button.layer.borderWidth = 0.5
        button.layer.borderColor = title == "Delete" ? 
            UIColor.systemRed.withAlphaComponent(0.3).cgColor : 
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Use filled version of SF Symbols if available
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let filledImageName = imageName + ".fill"
        let image = UIImage(systemName: filledImageName, withConfiguration: config) ?? 
                  UIImage(systemName: imageName, withConfiguration: config)
                  
        let imageView = UIImageView(image: image)
        imageView.tintColor = title == "Delete" ? .systemRed : .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = title == "Delete" ? .systemRed : .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        button.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 32),
            imageView.widthAnchor.constraint(equalToConstant: 32),
            
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
    
    // MARK: - Configuration
    
    func configure(with file: FileItem) {
        self.file = file
        
        fileNameLabel.text = file.name
        
        // Update size label with icon
        let sizeAttachment = NSTextAttachment()
        sizeAttachment.image = UIImage(systemName: "arrow.down.doc.fill")?.withTintColor(.systemBlue)
        let sizeAttributedString = NSMutableAttributedString(attachment: sizeAttachment)
        sizeAttributedString.append(NSAttributedString(string: "  Size: \(file.formattedSize)"))
        fileSizeLabel.attributedText = sizeAttributedString
        
        // Update date label with icon
        let dateAttachment = NSTextAttachment()
        dateAttachment.image = UIImage(systemName: "calendar")?.withTintColor(.systemBlue)
        let dateAttributedString = NSMutableAttributedString(attachment: dateAttachment)
        dateAttributedString.append(NSAttributedString(string: "  Modified: \(file.formattedDate)"))
        fileDateLabel.attributedText = dateAttributedString
        
        // Update type label with icon
        let typeAttachment = NSTextAttachment()
        let typeIcon = getFileTypeIcon(for: file.type)
        typeAttachment.image = UIImage(systemName: typeIcon)?.withTintColor(.systemBlue)
        let typeAttributedString = NSMutableAttributedString(attachment: typeAttachment)
        typeAttributedString.append(NSAttributedString(string: "  Type: \(file.type.rawValue.capitalized)"))
        fileTypeLabel.attributedText = typeAttributedString
        
        // Set appropriate icon with a larger size
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        let filledIcon = file.type.icon + ".fill"
        fileIconImageView.image = UIImage(systemName: filledIcon, withConfiguration: config) ?? 
                                 UIImage(systemName: file.type.icon, withConfiguration: config)
                                 
        // Set icon color based on file type
        switch file.type {
        case .image:
            fileIconImageView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.15)
            fileIconImageView.tintColor = .systemPink
        case .video:
            fileIconImageView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.15)
            fileIconImageView.tintColor = .systemPurple
        case .document:
            fileIconImageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            fileIconImageView.tintColor = .systemBlue
        case .audio:
            fileIconImageView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
            fileIconImageView.tintColor = .systemOrange
        case .other:
            fileIconImageView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
            fileIconImageView.tintColor = .systemGray
        }
    }
    
    private func getFileTypeIcon(for type: FileType) -> String {
        switch type {
        case .image:
            return "photo.fill"
        case .video:
            return "video.fill"
        case .document:
            return "doc.text.fill"
        case .audio:
            return "music.note"
        case .other:
            return "doc.fill"
        }
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
