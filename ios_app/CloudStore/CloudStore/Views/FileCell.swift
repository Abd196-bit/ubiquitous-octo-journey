import UIKit

class FileCell: UITableViewCell {
    static let identifier = "FileCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fileIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        // Use a circular background for the icon
        imageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.tintColor = .systemBlue
        
        // Add subtle shadow
        imageView.layer.shadowColor = UIColor.systemBlue.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.layer.shadowOpacity = 0.2
        imageView.layer.shadowRadius = 2
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        
        // Create a pill-shaped badge for file size
        label.backgroundColor = UIColor.systemGray6
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textAlignment = .center
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fileDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        
        // Add calendar icon
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "clock")?.withTintColor(.secondaryLabel)
        let attributedString = NSMutableAttributedString(attachment: attachment)
        attributedString.append(NSAttributedString(string: " "))
        label.attributedText = attributedString
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        fileNameLabel.text = nil
        fileSizeLabel.text = nil
        fileDateLabel.text = nil
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        
        containerView.addSubview(fileIconImageView)
        containerView.addSubview(fileNameLabel)
        containerView.addSubview(fileSizeLabel)
        containerView.addSubview(fileDateLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            fileIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            fileIconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            fileIconImageView.widthAnchor.constraint(equalToConstant: 36),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 36),
            
            fileNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            fileNameLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor, constant: 12),
            fileNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 4),
            fileSizeLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor, constant: 12),
            
            fileDateLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 4),
            fileDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            fileDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with file: FileItem) {
        fileNameLabel.text = file.name
        
        // Set size with padding for the pill-shaped badge
        fileSizeLabel.text = "  \(file.formattedSize)  "
        
        // Create attributed string with clock icon
        let attachment = NSTextAttachment()
        let clockImage = UIImage(systemName: "clock")?.withTintColor(.secondaryLabel)
        attachment.image = clockImage
        let attributedString = NSMutableAttributedString(attachment: attachment)
        attributedString.append(NSAttributedString(string: " \(file.formattedDate)"))
        fileDateLabel.attributedText = attributedString
        
        // Set appropriate icon - try to use filled version if available
        let filledIcon = file.type.icon + ".fill"
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        fileIconImageView.image = UIImage(systemName: filledIcon, withConfiguration: config) ?? 
                                  UIImage(systemName: file.type.icon, withConfiguration: config)
        
        // Set icon background color based on file type
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
}
