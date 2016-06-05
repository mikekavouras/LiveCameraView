//
//  CameraView.swift
//  MaskScrollView
//
//  Created by Mike Kavouras on 6/5/16.
//  Copyright © 2016 Mike Kavouras. All rights reserved.
//

import UIKit

public class LiveCameraView: UIView {
    
    public var gesturesEnabled: Bool = true {
        didSet {
            if gesturesEnabled {
                addGestureRecognizer(doubleTapGesture)
            } else {
                removeGestureRecognizer(doubleTapGesture)
            }
        }
    }
    
    private let camera = Camera()
    
    lazy private var doubleTapGesture: UITapGestureRecognizer = {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(LiveCameraView.handleDoubleTapGesture))
        doubleTap.numberOfTapsRequired = 2
        return doubleTap
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public func captureStill(completion: (UIImage?) -> Void) {
        camera.capturePreview { (image) in
            completion(image)
        }
    }
    
    private func setup() {
        backgroundColor = UIColor.clearColor()
        
        gesturesEnabled = true
        setupCamera()
    }
    
    private func setupCamera() {
        layer.addSublayer(camera.previewLayer)
        
        alpha = 0.0
        camera.startStreaming()
        UIView.animateWithDuration(0.2, delay: 0.5, options: .CurveLinear, animations: {
                self.alpha = 1.0
            }, completion: nil)
    }
    
    @objc private func handleDoubleTapGesture() {
        self.camera.flip()
    }
    
    override public func layoutSubviews() {
        camera.previewLayer.frame = bounds
        super.layoutSubviews()
    }
    

}
