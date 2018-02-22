//
//  Camera.swift
//  TeeSnap
//
//  Created by Mike Kavouras on 5/1/16.
//  Copyright © 2016 Mike Kavouras. All rights reserved.
//

import AVFoundation
import UIKit

protocol CameraDelegate: class {
    func didReceiveFilteredImage(_ image: UIImage)
}

class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    weak var delegate: CameraDelegate?
    
    var hasCamera: Bool {
        return AVCaptureDevice.devices().count > 0
    }
    
    open func device() -> AVCaptureDevice? {
        return input?.device
    }
    
    var gravity = AVLayerVideoGravity.resizeAspect {
        didSet {
            previewLayer.videoGravity = gravity
        }
    }
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.backgroundColor = UIColor.clear.cgColor
        layer.videoGravity = self.gravity
        return layer
    }()
    
    private lazy var sessionQueue: DispatchQueue = {
        return DispatchQueue(label: "com.mikekavouras.LiveCameraView.capture_session")
    }()
    
    private let output = AVCaptureVideoDataOutput()
    
    private let session = AVCaptureSession()
    
    private var position: AVCaptureDevice.Position? {
        guard let input = input else { return nil }
        return input.device.position
    }
    
    private var input: AVCaptureDeviceInput? {
        guard let inputs = session.inputs as? [AVCaptureDeviceInput] else { return nil }
        return inputs.filter { $0.device.hasMediaType(AVMediaType.video) }.first
    }
    
    override init() {
        super.init()
        
        session.sessionPreset = AVCaptureSession.Preset.photo
        let queue = DispatchQueue(label: "example serial queue")
        
        output.setSampleBufferDelegate(self, queue: queue)
        checkPermissions()
    }
    
    func startStreaming() {
        showDeviceForPosition(.front)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        let connection = output.connection(with: AVFoundation.AVMediaType.video)
        connection?.videoOrientation = .portrait
        
        sessionQueue.async { 
            self.session.startRunning()
        }
    }
    
    func flip() {
        guard let input = self.input,
            let position = self.position else { return }
        
        session.beginConfiguration()
        session.removeInput(input)
        showDeviceForPosition(position == .front ? .back : .front)
        session.commitConfiguration()
    }
    
    func capturePreview(_ completion: @escaping (UIImage?) -> Void) {
        var image: UIImage?
        
        defer {
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        captureImage { (buffer, error) in
            
            guard error == nil else {
                return
            }
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!)
            
            guard let capturedImage = UIImage(data: imageData!),
                let position = self.position else {
                    return
            }

            if position == .front {
                guard let cgImage = capturedImage.cgImage else {
                    return
                }
                image = UIImage(cgImage: cgImage, scale: capturedImage.scale, orientation: .leftMirrored)
            } else {
                image = capturedImage
            }
        }
        
    }
    
    private func captureImage(_ completion: @escaping (CMSampleBuffer?, Error?) -> Void) {
        let connection = self.output.connection(with: AVMediaType.video)
        connection?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDeviceOrientation.portrait.rawValue)!
        
//        sessionQueue.async { () -> Void in
//            self.output.captureStillImageAsynchronously(from: connection!) { (buffer, error) -> Void in
//                completion(buffer, error)
//            }
//        }
    }
    
    private func showDeviceForPosition(_ position: AVCaptureDevice.Position) {
        guard let device = deviceForPosition(position),
            let input = try? AVCaptureDeviceInput(device: device) else {
                return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    
    private func deviceForPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let allDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        let relevantDevices = allDevices.filter { $0.position == position }
        
        return relevantDevices.first
    }
    
    private func checkPermissions(_ completion: (() -> Void)? = nil) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                                      completionHandler: { (granted:Bool) -> Void in
                                                        completion?()
            })
        case .authorized:
            completion?()
        default: return
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension Camera {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        if #available(iOS 9.0, *) {
            let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
            
            let comicEffect = CIFilter(name: "CIComicEffect")
            comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
        
            let filteredImage = UIImage(ciImage: comicEffect!.value(forKey: kCIOutputImageKey) as! CIImage!)
        
            delegate?.didReceiveFilteredImage(filteredImage)
        }
    }
}
