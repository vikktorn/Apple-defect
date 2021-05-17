//
//  VideoCapture.swift
//  AppleDefectDetector
//
//  Created by Viktor Nesic on 16.5.21..
//

import UIKit
import AVFoundation
import CoreVideo
public protocol VideoCaptureDelegate: class {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
}
public enum CameraState {
    case ready, accessDenied, noDeviceFound, notDetermined
}

public class VideoCapture: NSObject {
 
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
    public var fps = 15
    public var showErrorsToUsers = false
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "com.tucan9389.camera-queue")
    public var capturDevice: AVCaptureDevice?
    var takePicture = false
    var capturedImageView: UIImage?
    
    var lastTimestamp = CMTime()
    
    public func setUp(sessionPreset: AVCaptureSession.Preset = .vga640x480,
                      completion: @escaping (Bool) -> Void) {
        self.setUpCamera(sessionPreset: sessionPreset, completion: { success in
            completion(success)
        })
    }
    
    func setUpCamera(sessionPreset: AVCaptureSession.Preset, completion: @escaping (_ success: Bool) -> Void) {
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video,
                                                          position: .back) else {
            
            print("Error: no video devices available")
            return
        }
        self.capturDevice = captureDevice
        
        guard let videoInput = try? AVCaptureDeviceInput(device: self.capturDevice!) else {
            print("Error: could not create AVCaptureDeviceInput")
            return
        }
       
        
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
        ]
        
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        captureSession.commitConfiguration()
        
        let success = true
        completion(success)
    }
    
    public func start() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    public func askUserForCameraPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (allowedAccess) -> Void in
           AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (allowedAccess) -> Void in
                    DispatchQueue.main.async { () -> Void in
                        completion(allowedAccess)
                    }
                })
          })
    }
    fileprivate func _checkIfCameraIsAvailable() -> CameraState {
        let deviceHasCamera = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.rear) || UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.front)
        if deviceHasCamera {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            let userAgreedToUseIt = authorizationStatus == .authorized
            if userAgreedToUseIt {
                return .ready
            } else if authorizationStatus == AVAuthorizationStatus.notDetermined {
                return .notDetermined
            } else {
                _show(NSLocalizedString("Camera access denied", comment: ""), message: NSLocalizedString("You need to go to settings app and grant acces to the camera device to use it.", comment: ""))
                return .accessDenied
            }
        } else {
            _show(NSLocalizedString("Camera unavailable", comment: ""), message: NSLocalizedString("The device does not have a camera.", comment: ""))
            return .noDeviceFound
        }
    }
    fileprivate func _show(_ title: String, message: String) {
        if showErrorsToUsers {
            DispatchQueue.main.async { () -> Void in
                self.showErrorBlock(title, message)
            }
        }
    }
    public var showErrorBlock: (_ erTitle: String, _ erMessage: String) -> Void = { (erTitle: String, erMessage: String) -> Void in
        
        var alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) -> Void in }))
        
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alertController, animated: true, completion: nil)
        }
    }
    open func currentCameraStatus() -> CameraState {
        return _checkIfCameraIsAvailable()
    }
    public func toggleTorch(on: Bool, button: UIButton) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else {
            print("Torch isn't available")
            button.isEnabled = false
            button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
            return }
        button.isEnabled = true
        button.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            // Optional thing you may want when the torch it's on, is to manipulate the level of the torch
            if on { try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel.significand) }
            device.unlockForConfiguration()
            
            
        } catch {
            print("Torch can't be used")
            button.isEnabled = false
            
        }
    }
    
    func getFrontCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
        
    }

    func getBackCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
        
    }
    
    
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp
        if deltaTime >= CMTimeMake(value: 1, timescale: Int32(fps)) {
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate?.videoCapture(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
        }
        if !takePicture {
                    return //we have nothing to do with the image buffer
                }
                
                //try and get a CVImageBuffer out of the sample buffer
                guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    return
                }
                
                //get a CIImage out of the CVImageBuffer
                let ciImage = CIImage(cvImageBuffer: cvBuffer)
                
                //get UIImage out of CIImage
                let uiImage = UIImage(ciImage: ciImage)
        print("TAT")
        DispatchQueue.main.async {
                    self.capturedImageView = uiImage
                    self.takePicture = false
            let imageVC =  UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ImageViewController") as! ImageViewController
            imageVC.modalTransitionStyle = .crossDissolve
            imageVC.modalPresentationStyle = .fullScreen
            imageVC.image = uiImage
            UIApplication.topViewController()?.present(imageVC, animated: true, completion: nil)
            }
  }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("dropped frame")
    }
}
extension UIApplication {

    static func topViewController() -> UIViewController? {
        guard var top = shared.windows.first(where: { $0.isKeyWindow })!.rootViewController else {
            return nil
        }
        while let next = top.presentedViewController {
            top = next
        }
        return top
    }
}
