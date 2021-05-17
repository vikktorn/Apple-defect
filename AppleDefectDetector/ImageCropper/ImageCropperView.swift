//
//  ImageCropperView.swift
//  AppleDefectDetector
//
//  Created by Viktor Nesic on 16.5.21..
//

import UIKit

class ImageCropperView: UIImageView {
    //Update this to enable/disable cropping
    public var isCropEnabled = true

    //Update this for path line color
    public var strokeColor:UIColor = UIColor.black
    
    //Update this for path line width
    public var lineWidth:CGFloat = 4.0
    
    private var path = UIBezierPath()
    private var shapeLayer = CAShapeLayer()
    
    //Get recently cropped image anytime
    var croppedImage: UIImage?
    
    var isLogEnabled = true
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        isUserInteractionEnabled = isCropEnabled
    }
    
    //MARK:- Public methods

    /**
     Crop selection layer
     
     - Returns: Cropped image
     */
    public func cropImage() -> UIImage? {
        shapeLayer.fillColor = UIColor.black.cgColor
        layer.mask = shapeLayer
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 1)
        
        if let currentContext = UIGraphicsGetCurrentContext() {
            layer.render(in: currentContext)
            
            if let croppedImageFromContext = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                croppedImage = croppedImageFromContext
                RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Proceed !", completionTimeout: 2.5)
            }
        }
        
        return croppedImage
    }
    
    /**
     Reset cropping
     */
    public func resetCrop() {
        path = UIBezierPath()
        shapeLayer = CAShapeLayer()
        layer.mask = nil
        croppedImage = nil
    }
    
    //MARK:- Private methods
    /**
     This methods is adding CAShapeLayer line to tempImageView
     */
    private func addNewPathToImage(){
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        layer.addSublayer(shapeLayer)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first as UITouch?{
            let touchPoint = touch.location(in: self)
            if isLogEnabled {
                debugPrint("touch begin to : \(touchPoint)")
            }
            path.move(to: touchPoint)
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first as UITouch?{
            let touchPoint = touch.location(in: self)
            if isLogEnabled {
                print("touch moved to : \(touchPoint)")
            }
            path.addLine(to: touchPoint)
            addNewPathToImage()
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first as UITouch?{
            let touchPoint = touch.location(in: self)
            if isLogEnabled {
                print("touch ended at : \(touchPoint)")
            }
            path.addLine(to: touchPoint)
            addNewPathToImage()
            path.close()
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first as UITouch?{
            let touchPoint = touch.location(in: self)
            if isLogEnabled {
                print("touch canceled at : \(touchPoint)")
            }
            path.close()
        }
    }
}
