//
//  ImageViewController.swift
//  AppleDefectDetector
//
//  Created by Viktor Nesic on 16.5.21..
//

import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var imageView: ImageCropperView!
    @IBOutlet weak var previewImage: UIImageView!
    
    
    @IBOutlet weak var cropObjectBTN: UIButton!
    @IBOutlet weak var cropObjectLBL: UILabel!
   
    @IBOutlet weak var eraseBackBTN: UIButton!
    @IBOutlet weak var eraseBackLBL: UILabel!
    
    @IBOutlet weak var eraseObjectBTN: UIButton!
    @IBOutlet weak var eraseObjectLBL: UILabel!
    
    
    @IBOutlet weak var saveBTN: UIButton!
    
    
    var image: UIImage!
    var croppedImage: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        guard let validImage = image else {
            return
        }
      imageView.image = validImage
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
    func setUp(){
        imageView.enableZoom()
        previewImage.layer.borderWidth = 3
        previewImage.layer.borderColor = UIColor.white.cgColor
        previewImage.backgroundColor = .black
        previewImage.layer.cornerRadius = 20
        
        saveBTN.layer.cornerRadius = 12
        saveBTN.layer.borderWidth = 2
        saveBTN.layer.borderColor = UIColor.systemYellow.cgColor
        
        previewImage.alpha = 0
        saveBTN.alpha = 0
        
        let cropGesture = UITapGestureRecognizer(target: self, action: #selector(cropAction))
        cropObjectLBL.isUserInteractionEnabled = true
        cropObjectLBL.addGestureRecognizer(cropGesture)
        
        let eraseBackGesture = UITapGestureRecognizer(target: self, action: #selector(eraseBackgroundAction))
        eraseBackLBL.isUserInteractionEnabled = true
        eraseBackLBL.addGestureRecognizer(eraseBackGesture)
        
        let eraseObjectGesture = UITapGestureRecognizer(target: self, action: #selector(eraseObjectAction))
        eraseObjectLBL.isUserInteractionEnabled = true
        eraseObjectLBL.addGestureRecognizer(eraseObjectGesture)
        
       
   }
    
    @objc func cropAction() {
        let attribute = RappleActivityIndicatorView.attribute(style: .apple, tintColor: .red,screenBG: .darkGray, progressBG: .black, progressBarBG: .orange, progreeBarFill: .red, thickness: 4)
        RappleActivityIndicatorView.startAnimatingWithLabel("Processing ....", attributes: attribute)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.croppedImage = self.imageView.cropImage()
            self.previewImage.image = self.croppedImage
            self.previewImage.alpha = 1
            self.saveBTN.alpha = 1
        }
    }
    
    @IBAction func cropBtnTap(_ sender: Any) {
      cropAction()
     }
    @objc func eraseBackgroundAction() {
        let attribute = RappleActivityIndicatorView.attribute(style: .apple, tintColor: .red,screenBG: .darkGray, progressBG: .black, progressBarBG: .orange, progreeBarFill: .red, thickness: 4)
        RappleActivityIndicatorView.startAnimatingWithLabel("Processing ....", attributes: attribute)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.previewImage.image = self.imageView.image!.removeBackground(returnResult: .finalImage, imageView: self.previewImage, button: self.saveBTN)
        }
    }
    
    @IBAction func eraseBckBtnTap(_ sender: Any) {
        eraseBackgroundAction()
        
    }
    
    @objc func eraseObjectAction() {
        let attribute = RappleActivityIndicatorView.attribute(style: .apple, tintColor: .red,screenBG: .darkGray, progressBG: .black, progressBarBG: .orange, progreeBarFill: .red, thickness: 4)
        RappleActivityIndicatorView.startAnimatingWithLabel("Processing ....", attributes: attribute)
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.previewImage.image = self.imageView.image!.removeBackground(returnResult: .background, imageView: self.previewImage, button: self.saveBTN)
        }
        
    }
    
    @IBAction func eraseObjTap(_ sender: Any) {
        eraseObjectAction()
        
    }
    
 override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func closeButtonTapped(_: Any) {
        let vc: ViewController? = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(vc!, animated: true, completion: nil)
    }
    
    
     
    @IBAction func saveBtnTap(_ sender: Any) {
        let attribute = RappleActivityIndicatorView.attribute(style: .apple, tintColor: .red,screenBG: .darkGray, progressBG: .black, progressBarBG: .orange, progreeBarFill: .red, thickness: 4)
        RappleActivityIndicatorView.startAnimatingWithLabel("Saving ....", attributes: attribute)
        if let pickedImage = previewImage.image {
                UIImageWriteToSavedPhotosAlbum(pickedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
    }
    @objc func image (_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .failed, completionLabel: "Error !", completionTimeout: 2.5)
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Saved !", completionTimeout: 2.5)
            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
  
    
}

