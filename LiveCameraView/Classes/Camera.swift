//
//  Camera.swift
//  TeeSnap
//
//  Created by Mike Kavouras on 5/1/16.
//  Copyright © 2016 Mike Kavouras. All rights reserved.
//

import AVFoundation
import UIKit

class Camera {
    
    var gravity = AVLayerVideoGravityResizeAspect {
        didSet {
            previewLayer.videoGravity = gravity
        }
    }
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer?.backgroundColor = UIColor.clear.cgColor
        layer?.videoGravity = self.gravity
        return layer!
    }()
    
    private lazy var sessionQueue: DispatchQueue = {
        return DispatchQueue(label: "com.mikekavouras.LiveCameraView.capture_session")
    }()
    
    private let output = AVCaptureStillImageOutput()
    
    private let session = AVCaptureSession()
    
    private var position: AVCaptureDevicePosition? {
        guard let input = input else { return nil }
        return input.device.position
    }
    
    private var input: AVCaptureDeviceInput? {
        guard let inputs = session.inputs as? [AVCaptureDeviceInput] else { return nil }
        return inputs.filter { $0.device.hasMediaType(AVMediaTypeVideo) }.first
    }
    
    init() {
        session.sessionPreset = AVCaptureSessionPresetPhoto
        checkPermissions()
    }
    
    func startStreaming() {
        showDeviceForPosition(.front)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        sessionQueue.async { 
            self.session.startRunning()
        }
    }
    
    func flip() {
        guard let input = self.input,
            position = self.position else { return }
        
        session.beginConfiguration()
        session.removeInput(input)
        showDeviceForPosition(position == .front ? .back : .front)
        session.commitConfiguration()
    }
    
    func capturePreview(_ completion: (UIImage?) -> Void) {
        
        let done = { (image: UIImage?) in
            DispatchQueue.main.async(execute: {
                completion(image)
            })
        }
        
        captureImage { (buffer, error) in
            
            guard error == nil else {
                done(nil)
                return
            }
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            
            guard let image = UIImage(data: imageData!),
                position = self.position else {
                    done(nil)
                    return
            }

            if position == .front {
                guard let cgImage = image.cgImage else {
                    done(nil)
                    return
                }
                let flipped = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
                done(flipped)
            } else {
                done(image)
            }
        }
        
    }
    
    private func captureImage(_ completion: (CMSampleBuffer?, NSError?) -> Void) {
        let connection = self.output.connection(withMediaType: AVMediaTypeVideo)
        connection?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDeviceOrientation.portrait.rawValue)!
        
        sessionQueue.async { () -> Void in
            self.output.captureStillImageAsynchronously(from: connection) { (buffer, error) -> Void in
                completion(buffer, error)
            }
        }
    }
    
    private func showDeviceForPosition(_ position: AVCaptureDevicePosition) {
        guard let device = deviceForPosition(position),
            input = try? AVCaptureDeviceInput(device: device) else {
                return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    
    private func deviceForPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let availableCameraDevices: [AVCaptureDevice] = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice],
            device = (availableCameraDevices.filter { $0.position == position }.first) else {
                return nil
        }
        
        return device
    }
    
    private func checkPermissions(_ completion: (() -> Void)? = nil) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
                                                      completionHandler: { (granted:Bool) -> Void in
                                                        completion?()
            })
        case .authorized:
            completion?()
        default: return
        }
    }
    
}
