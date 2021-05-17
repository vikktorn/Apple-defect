//
//  RappleAIPrivate.swift
//  AppleDefectDetector
//
//  Created by Viktor Nesic on 16.5.21..
//

import UIKit

extension RappleActivityIndicatorView {
    
    /** get color attribute values for key */
    @objc func getColor(key: String) -> UIColor {
        if let color = attributes[key] as? UIColor {
            return color
        }
        switch key {
        case RappleTintColorKey:
            return UIColor.white.withAlphaComponent(0.8)
        case RappleScreenBGColorKey:
            return UIColor.black.withAlphaComponent(0.4)
        case RappleProgressBGColorKey:
            return UIColor.black.withAlphaComponent(0.7)
        case RappleProgressBarColorKey:
            return UIColor.lightGray.withAlphaComponent(0.8)
        case RappleProgressBarFillColorKey:
            return UIColor.white.withAlphaComponent(0.9)
        default:
            return UIColor.white.withAlphaComponent(0.8)
        }
    }
    
    @objc func getThickness(adjustment: CGFloat = 0) -> CGFloat {
        if let thick = attributes[RappleIndicatorThicknessKey] as? CGFloat {
            if thick > adjustment {
                return thick - adjustment
            } else {
                return 1
            }
        }
        return 4.0 - adjustment
    }
    
    
    /** get completion indicator string value */
    func getCompletion(indicator: RappleCompletion) -> (String, UIFont) {
        switch indicator {
        case .success:
            return ("✓", .boldSystemFont(ofSize: 25))
        case .failed:
            return ("✕", .systemFont(ofSize: 25))
        case .incomplete:
            return ("!", .boldSystemFont(ofSize: 27))
        case .unknown:
            return ("?", .boldSystemFont(ofSize: 25))
        case .none:
            return ("", .systemFont(ofSize: 22))
        }
        
    }
    
    /** re-create after orientation change */
    @objc internal func orientationChanged() {
        RappleActivityIndicatorView.sharedInstance.createActivityIndicator()
    }
    
    /** clear all UIs */
    @objc func clearUIs() {
        if let bgview = RappleActivityIndicatorView.sharedInstance.backgroundView {
            for v in bgview.subviews {
                v.removeFromSuperview()
            }
            if let layers = bgview.layer.sublayers {
                for l in layers {
                    l.removeFromSuperlayer()
                }
            }
            progressLayer = nil
            progressLayerBG = nil
            progressLabel = nil
        }
    }
    
    /** get key window */
    @objc var keyWindow: UIWindow {
        return UIApplication.shared.keyWindow!
    }
}

