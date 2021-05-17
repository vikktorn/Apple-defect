//
//  ViewController.swift
//  AppleDefectDetector
//
//  Created by Viktor Nesic on 16.5.21..
//

import UIKit
import Vision
import CoreMedia
import AVFoundation

class ViewController: UIViewController , PerformanceMonitorDelegate{
    func performanceMonitor(didReport performanceReport: PerformanceReport) {
        self.cpuUsageLBL.text = String(format: "Cpu Usage: %.1f%%, Refresh Frame Rate: %d", performanceReport.cpuUsage, performanceReport.fps)
        let bytesInMegabyte = 1024.0 * 1024.0
        let usedMemory = Double(performanceReport.memoryUsage.used) / bytesInMegabyte
        let totalMemory = Double(performanceReport.memoryUsage.total) / bytesInMegabyte
        self.ramUsageLBL.text = String(format: "%.1f of %.0f MB used", usedMemory, totalMemory)
    }
    
    
    
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var boxesView: DrawingBoundingBoxView!
    @IBOutlet weak var recordBTN: UIButton!
    @IBOutlet weak var underRecordBTN: UIButton!
    
    @IBOutlet weak var cpuUsageLBL: UILabel!
    @IBOutlet weak var ramUsageLBL: UILabel!
    @IBOutlet weak var numberOfObjectsLBL: UILabel!
    @IBOutlet weak var interferenceLBL: UILabel!
     @IBOutlet weak var flashBTN: UIButton!
   
    var isFlashTap = false
    var usingFrontCamera = false
    
    let objectDectectionModel = Model()
    let performanceMonitor = PerformanceMonitor()
    let performanceView = PerformanceView()

    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var isInferencing = false
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!
    let semaphore = DispatchSemaphore(value: 1)
    var lastExecution = Date()
    
    // MARK: - TableView Data
    var predictions: [VNRecognizedObjectObservation] = []
    
    // MARK - Performance Measurement Property
    private let measure = Measure()
    
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpModel()
        setUpView()
        measure.delegate = self
        PerformanceMonitor.shared().start()
        
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PerformanceMonitor.shared().delegate = self
        
      
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    func setUpView(){
        videoCapture = VideoCapture()
   //     videoCapture.toggleTorch(on: true, button: flashBTN)
        askForCameraPermissions()
        recordBTN.layer.cornerRadius = recordBTN.frame.height/2
        recordBTN.backgroundColor = .red
        
        underRecordBTN.layer.cornerRadius = underRecordBTN.frame.height/2
        underRecordBTN.layer.borderColor = UIColor.red.cgColor
        underRecordBTN.layer.borderWidth = 3
        
        
        
        
  }
   func askForCameraPermissions() {
        videoCapture.askUserForCameraPermission { permissionGranted in
             if permissionGranted {
               self.setUpCamera()
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: objectDectectionModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("fail to create vision model")
        }
    }

    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // start video preview when setup is done
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    @IBAction func recordBtnTap(_ sender: UIButton) {
        videoCapture.takePicture = true
        
    }
    
    @IBAction func flashBtnTap(_ sender: UIButton) {
        if(isFlashTap){
        videoCapture.toggleTorch(on: true, button: sender)
         sender.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            isFlashTap = false
            
        } else {
            videoCapture.toggleTorch(on: false, button: sender)
            sender.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
            isFlashTap = true
        }
    }
    
    @IBAction func flipCameraTap(_ sender: Any) {
        usingFrontCamera = !usingFrontCamera
            do{
                videoCapture.captureSession.removeInput(videoCapture.captureSession.inputs.first!)

                if(usingFrontCamera){
                    videoCapture.capturDevice = videoCapture.getFrontCamera()
                }else{
                    videoCapture.capturDevice =  videoCapture.getBackCamera()
                }
                let captureDeviceInput1 = try AVCaptureDeviceInput(device: videoCapture.capturDevice!)
                videoCapture.captureSession.addInput(captureDeviceInput1)
            }catch{
                print(error.localizedDescription)
            }
        
    }
    
    
    
}




// MARK: - VideoCaptureDelegate
extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if !self.isInferencing, let pixelBuffer = pixelBuffer {
            self.isInferencing = true
            
            // start of measure
            self.measure.start()
            
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
            
            
        }
    }
}

extension ViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        // vision framework configures the input size of image following our model's input configuration automatically
        self.semaphore.wait()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    // MARK: - Post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.measure.labeling(with: "endInference")
        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            print(predictions.first?.labels.first?.identifier ?? "nil")
            print(predictions.first?.labels.first?.confidence ?? -1)
           
            self.predictions = predictions
            DispatchQueue.main.async {
                self.boxesView.predictedObjects = predictions
                self.numberOfObjectsLBL.text = "Number of detected apples: " + String(predictions.count)
                self.measure.stop()
                self.isInferencing = false
            }
        } else {
            // end of measure
            self.measure.stop()
            
            self.isInferencing = false
        }
        self.semaphore.signal()
    }
    
    
    
}


// MARK: - 📏(Performance Measurement) Delegate
extension ViewController: MeasureDelegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        //print(executionTime, fps)
        DispatchQueue.main.async {
            self.maf1.append(element: Int(inferenceTime*1000.0))
            self.maf2.append(element: Int(executionTime*1000.0))
            self.maf3.append(element: fps)
            
            self.interferenceLBL.text = "Inference: \(self.maf1.averageValue) ms; Execution: \(self.maf2.averageValue) ms"
           
            
        }
    }
}

class MovingAverageFilter {
    private var arr: [Int] = []
    private let maxCount = 10
    
    public func append(element: Int) {
        arr.append(element)
        if arr.count > maxCount {
            arr.removeFirst()
        }
    }
    
    public var averageValue: Int {
        guard !arr.isEmpty else { return 0 }
        let sum = arr.reduce(0) { $0 + $1 }
        return Int(Double(sum) / Double(arr.count))
    }
}


