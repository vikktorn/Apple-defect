//
//  Measure.swift
//  AppleDefectDetector
//
//  Created by Viktor Nesic on 16.5.21..
//

import UIKit

protocol MeasureDelegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int)
}
// Performance Measurement
class Measure {
    
    var delegate: MeasureDelegate?
    
    var index: Int = -1
    var measurements: [Dictionary<String, Double>]
    
    init() {
        let measurement = [
            "start": CACurrentMediaTime(),
            "end": CACurrentMediaTime()
        ]
        measurements = Array<Dictionary<String, Double>>(repeating: measurement, count: 30)
    }
    
    // start
    func start() {
        index += 1
        index %= 30
        measurements[index] = [:]
        
        labelingFor(for: index, with: "start")
    }
    
    // stop
    func stop() {
        labelingFor(for: index, with: "end")
        
        let beforeMeasurement = getBeforeMeasurment(for: index)
        let currentMeasurement = measurements[index]
        if let startTime = currentMeasurement["start"],
            let endInferenceTime = currentMeasurement["endInference"],
            let endTime = currentMeasurement["end"],
            let beforeStartTime = beforeMeasurement["start"] {
            delegate?.updateMeasure(inferenceTime: endInferenceTime - startTime,
                                    executionTime: endTime - startTime,
                                    fps: Int(1/(startTime - beforeStartTime)))
        }
        
    }
    
    // labeling with
    func labeling(with msg: String? = "") {
        labelingFor(for: index, with: msg)
    }
    
    private func labelingFor(for index: Int, with msg: String? = "") {
        if let message = msg {
            measurements[index][message] = CACurrentMediaTime()
        }
    }
    
    private func getBeforeMeasurment(for index: Int) -> Dictionary<String, Double> {
        return measurements[(index + 30 - 1) % 30]
    }
    
    // log
    func print() {
        
    }
}

class MeasureLogView: UIView {
    let etimeLabel = UILabel(frame: .zero)
    let fpsLabel = UILabel(frame: .zero)
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
