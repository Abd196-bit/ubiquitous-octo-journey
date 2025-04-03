import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private let fileUploadService = FileUploadService()
    
    // MARK: - UI Components
    
    private let capturePreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let flashButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        stopCaptureSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(capturePreviewView)
        view.addSubview(captureButton)
        view.addSubview(switchCameraButton)
        view.addSubview(flashButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            capturePreviewView.topAnchor.constraint(equalTo: view.topAnchor),
            capturePreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            capturePreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            capturePreviewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            switchCameraButton.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -30),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 40),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 40),
            
            flashButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            flashButton.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -30),
            flashButton.widthAnchor.constraint(equalToConstant: 40),
            flashButton.heightAnchor.constraint(equalToConstant: 40),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        
        // Add tap gesture to return to previous screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(_:)))
        tapGesture.cancelsTouchesInView = false
        capturePreviewView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Camera Setup
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self, granted else { return }
                DispatchQueue.main.async {
                    self.setupCaptureSession()
                }
            }
        case .denied, .restricted:
            showAlert(title: "Camera Access Required", message: "Please enable camera access in settings to use this feature.")
        @unknown default:
            showAlert(title: "Error", message: "Unknown camera access status.")
        }
    }
    
    private func setupCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession = AVCaptureSession()
            self.captureSession?.sessionPreset = .high
            
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: backCamera) else {
                self.showAlert(title: "Error", message: "Could not access the camera.")
                return
            }
            
            if self.captureSession?.canAddInput(input) == true {
                self.captureSession?.addInput(input)
            }
            
            self.photoOutput = AVCapturePhotoOutput()
            if let photoOutput = self.photoOutput, self.captureSession?.canAddOutput(photoOutput) == true {
                self.captureSession?.addOutput(photoOutput)
            }
            
            DispatchQueue.main.async {
                self.setupPreviewLayer()
                self.startCaptureSession()
            }
        }
    }
    
    private func setupPreviewLayer() {
        guard let captureSession = captureSession else { return }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = capturePreviewView.bounds
        
        if let videoPreviewLayer = videoPreviewLayer {
            capturePreviewView.layer.addSublayer(videoPreviewLayer)
        }
    }
    
    private func startCaptureSession() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    private func stopCaptureSession() {
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func captureButtonTapped() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func switchCameraButtonTapped() {
        guard let captureSession = captureSession else { return }
        
        // Remove existing input
        captureSession.beginConfiguration()
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        // Determine new camera position
        let currentPosition: AVCaptureDevice.Position = captureSession.inputs.first?.device.position ?? .back
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        // Add new input
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        
        captureSession.commitConfiguration()
    }
    
    @objc private func flashButtonTapped() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .on {
                    device.torchMode = .off
                    flashButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
                } else {
                    try device.setTorchModeOn(level: 1.0)
                    flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
                }
                
                device.unlockForConfiguration()
            } catch {
                showAlert(title: "Error", message: "Could not toggle flash.")
            }
        }
    }
    
    @objc private func handleTapToFocus(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let previewLayer = videoPreviewLayer,
              let device = AVCaptureDevice.default(for: .video) else { return }
        
        let touchPoint = gestureRecognizer.location(in: capturePreviewView)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            // Show focus indicator
            showFocusIndicator(at: touchPoint)
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }
    
    private func showFocusIndicator(at point: CGPoint) {
        let focusIndicator = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusIndicator.center = point
        focusIndicator.layer.borderColor = UIColor.white.cgColor
        focusIndicator.layer.borderWidth = 2
        focusIndicator.backgroundColor = .clear
        capturePreviewView.addSubview(focusIndicator)
        
        UIView.animate(withDuration: 0.5, animations: {
            focusIndicator.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                focusIndicator.alpha = 0
            }) { _ in
                focusIndicator.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alertController, animated: true)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            activityIndicator.stopAnimating()
            showAlert(title: "Error", message: "Failed to capture photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            activityIndicator.stopAnimating()
            showAlert(title: "Error", message: "Failed to process photo")
            return
        }
        
        // Show captured preview
        previewAndUploadPhoto(image)
    }
    
    private func previewAndUploadPhoto(_ image: UIImage) {
        let previewVC = CapturedPhotoViewController(image: image, delegate: self)
        present(previewVC, animated: true) {
            self.activityIndicator.stopAnimating()
        }
    }
}

// MARK: - CapturedPhotoViewControllerDelegate

extension CameraViewController: CapturedPhotoViewControllerDelegate {
    func didFinishWithImage(_ image: UIImage, uploadAction: Bool) {
        if uploadAction {
            uploadPhoto(image)
        }
    }
    
    private func uploadPhoto(_ image: UIImage) {
        activityIndicator.startAnimating()
        
        let fileName = "photo_\(UUID().uuidString).jpg"
        fileUploadService.uploadImage(image: image, fileName: fileName) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success:
                    self.showAlert(title: "Success", message: "Photo uploaded successfully.")
                case .failure:
                    self.showAlert(title: "Upload Failed", message: "Failed to upload the photo. Please try again.")
                }
            }
        }
    }
}

// MARK: - CapturedPhotoViewController

protocol CapturedPhotoViewControllerDelegate: AnyObject {
    func didFinishWithImage(_ image: UIImage, uploadAction: Bool)
}

class CapturedPhotoViewController: UIViewController {
    
    private let capturedImage: UIImage
    private weak var delegate: CapturedPhotoViewControllerDelegate?
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload", for: .normal)
        button.setImage(UIImage(systemName: "icloud.and.arrow.up"), for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retake", for: .normal)
        button.setImage(UIImage(systemName: "camera"), for: .normal)
        button.backgroundColor = .systemGray4
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(image: UIImage, delegate: CapturedPhotoViewControllerDelegate) {
        self.capturedImage = image
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        imageView.image = capturedImage
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(imageView)
        view.addSubview(uploadButton)
        view.addSubview(retakeButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            uploadButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            retakeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            retakeButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            retakeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            retakeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        retakeButton.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func uploadButtonTapped() {
        dismiss(animated: true) {
            self.delegate?.didFinishWithImage(self.capturedImage, uploadAction: true)
        }
    }
    
    @objc private func retakeButtonTapped() {
        dismiss(animated: true) {
            self.delegate?.didFinishWithImage(self.capturedImage, uploadAction: false)
        }
    }
}
