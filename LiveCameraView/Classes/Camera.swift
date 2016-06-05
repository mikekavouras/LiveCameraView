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
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        return layer
    }()
    
    private lazy var sessionQueue: dispatch_queue_t = {
      return dispatch_queue_create("com.mikekavouras.TeeSnap.capture_session", DISPATCH_QUEUE_SERIAL)
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
        showDeviceForPosition(.Front)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        dispatch_async(sessionQueue) { 
            self.session.startRunning()
        }
    }
    
    func flip() {
        guard let input = self.input,
            position = self.position else { return }
        
        session.beginConfiguration()
        session.removeInput(input)
        showDeviceForPosition(position == .Front ? .Back : .Front)
        session.commitConfiguration()
    }
    
    func capturePreview(completion: (UIImage?) -> Void) {
        
        let done = { (image: UIImage?) in
            dispatch_async(dispatch_get_main_queue(), {
                completion(image)
            })
        }
        
        captureImage { (buffer, error) in
            
            guard error == nil else {
                done(nil)
                return
            }
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            
            guard let image = UIImage(data: imageData),
                position = self.position else {
                    done(nil)
                    return
            }

            if position == .Front {
                guard let cgImage = image.CGImage else {
                    done(nil)
                    return
                }
                let flipped = UIImage(CGImage: cgImage, scale: image.scale, orientation: .LeftMirrored)
                done(flipped)
            } else {
                done(image)
            }
        }
        
    }
    
    private func captureImage(completion: (CMSampleBuffer!, NSError!) -> Void) {
        let connection = self.output.connectionWithMediaType(AVMediaTypeVideo)
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDeviceOrientation.Portrait.rawValue)!
        
        dispatch_async(sessionQueue) { () -> Void in
            self.output.captureStillImageAsynchronouslyFromConnection(connection) { (buffer, error) -> Void in
                completion(buffer, error)
            }
        }
    }
    
    private func showDeviceForPosition(position: AVCaptureDevicePosition) {
        guard let device = deviceForPosition(position),
            input = try? AVCaptureDeviceInput(device: device) else {
                return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    
    private func deviceForPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let availableCameraDevices: [AVCaptureDevice] = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice],
            device = (availableCameraDevices.filter { $0.position == position }.first) else {
                return nil
        }
        
        return device
    }
    
    private func checkPermissions(completion: (() -> Void)? = nil) {
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch authorizationStatus {
        case .NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
                                                      completionHandler: { (granted:Bool) -> Void in
                                                        completion?()
            })
        case .Authorized:
            completion?()
        default: return
        }
    }
    
}