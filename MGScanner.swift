//
//  Scanner.swift
//  PriceFinder
//
//  Created by Marc Giroux on 2014-12-01.
//  Copyright (c) 2014 QuatreCentCinq. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import QuartzCore

protocol MGScannerDelegate
{
    func scannerDidFinishWithCode(code: String, type: String)
}

class MGScanner: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
    private var sessionCapture: AVCaptureSession         = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureDevice: AVCaptureDevice           = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    private var gesture: UITapGestureRecognizer          = UITapGestureRecognizer()
    
    internal var showScanHelper: Bool       = true
    internal var scanHelperColor: UIColor   = UIColor.whiteColor()
    internal var cancelButtonString: String = "Cancel"
    internal var closeImage: String         = ""
    internal var useQR: Bool                = false
    internal var delegate: MGScannerDelegate?
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.sessionCapture = AVCaptureSession()
        self.captureDevice  = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var error: NSError?
        
        var videoInput: AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: &error) as AVCaptureDeviceInput!
        
        if self.sessionCapture.canAddInput(videoInput) == true {
            self.sessionCapture.addInput(videoInput)
        }
        
        var captureMetaData: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
        
        if self.sessionCapture.canAddOutput(captureMetaData) == true {
            self.sessionCapture.addOutput(captureMetaData)
            
            captureMetaData.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
            var codes: [String] = [
                AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code,
                AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeEAN13Code,
                AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeUPCECode
            ]
            
            if self.useQR == true {
                codes.append(AVMetadataObjectTypeQRCode)
            }
            
            captureMetaData.metadataObjectTypes = codes
        }
        
        self.previewLayer  = AVCaptureVideoPreviewLayer(session: self.sessionCapture)
        self.previewLayer.frame = self.view.layer.bounds
        self.view.layer.addSublayer(self.previewLayer)
        
        var button: UIButton = UIButton()
        
        if self.closeImage != "" {
            /* Custom close button */
            var image: UIImage = UIImage(named: self.closeImage)!
            button.setImage(image, forState: UIControlState.Normal)
            
            var width: CGFloat  = image.size.width
            var height: CGFloat = image.size.height
            
            button.frame = CGRect(x: (self.view.frame.size.width / 2) - (width / 2), y: (self.view.frame.size.height) - (height / 2 + 40), width: width, height: height)
        } else {
            /* Standard close button */
            button.setTitle(self.cancelButtonString, forState: UIControlState.Normal)
            
            var width: CGFloat  = button.frame.size.width
            var height: CGFloat = button.frame.size.height
            
            button.frame = CGRect(x: (self.view.frame.size.width / 2) - width / 2, y: self.view.frame.size.height - height / 2, width: width, height: height)
        }
        
        button.addTarget(self, action: "cancelScan:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(button)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
                
        if self.showScanHelper == true {
            var feedbackLayer: CALayer = CALayer()
            feedbackLayer.borderWidth  = 2.0
            feedbackLayer.cornerRadius = 4.0
            feedbackLayer.borderColor  = self.scanHelperColor.CGColor
            feedbackLayer.zPosition    = 1000
            feedbackLayer.frame        = CGRect(x: (self.view.bounds.size.width / 2) - 120, y: (self.view.bounds.size.height / 2) - 60, width: 240, height: 120)
            
            self.view.layer.addSublayer(feedbackLayer)
        }
        
        self.sessionCapture.startRunning()
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    
    internal func cancelScan(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true, completion: { [unowned self] in
            self.previewLayer.removeFromSuperlayer()
            self.view.removeGestureRecognizer(self.gesture)
        })
    }
    
    internal func start(controller: UIViewController)
    {
        self.view.backgroundColor   = UIColor.blackColor()
        self.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
        controller.presentViewController(self, animated: true) { [unowned self] () -> Void in
            /* Tap to focus */
            self.gesture                         = UITapGestureRecognizer(target: self, action: "tapToFocus:")
            self.gesture.numberOfTapsRequired    = 1
            self.gesture.numberOfTouchesRequired = 1
            self.view.addGestureRecognizer(self.gesture)
        }
    }
    
    internal func tapToFocus(gesture: UIGestureRecognizer)
    {
        var touchPoint: CGPoint = gesture.locationInView(self.view)
        var convertedPoint: CGPoint = self.previewLayer.captureDevicePointOfInterestForPoint(touchPoint)
        
        if self.captureDevice.focusPointOfInterestSupported == true && self.captureDevice.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) == true {
            var error: NSError?
            
            self.captureDevice.lockForConfiguration(&error)
            if error == nil {
                self.captureDevice.focusPointOfInterest = convertedPoint
                self.captureDevice.focusMode            = AVCaptureFocusMode.AutoFocus
                self.captureDevice.unlockForConfiguration()
            }
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!)
    {
        var code: String = ""
        
        for object: AnyObject in metadataObjects {
            if let metadata: AVMetadataMachineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                code = metadata.stringValue
                
                self.sessionCapture.stopRunning()
                
                self.dismissViewControllerAnimated(true, completion: { [unowned self] in
                    self.previewLayer.removeFromSuperlayer()
                    self.view.removeGestureRecognizer(self.gesture)
                    self.delegate?.scannerDidFinishWithCode(code, type: metadata.type)
                })
            }
        }
    }
}
