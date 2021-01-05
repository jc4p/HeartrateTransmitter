//
//  InterfaceController.swift
//  HeartrateTransmitter WatchKit Extension
//
//  Created by Kasra Rahjerdi on 1/5/21.
//

import WatchKit
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    var hkStore: HKHealthStore?
    var isRunning = false

    var workoutSession: HKWorkoutSession?
    var startDate: Date?
    let heartRateUnit = HKUnit(from: "count/min")
    var hkQuery: HKAnchoredObjectQuery?
    
    @IBOutlet var rateLabel: WKInterfaceLabel!
    @IBOutlet var toggleButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        hkStore = HKHealthStore()
        initHealthStore()
        
        self.rateLabel.setText("")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // stage changed toState at date
        if (toState == .running) {
            startDate = date
            isRunning = true
            self.toggleButton.setTitle("Stop")
        } else {
            isRunning = false
            self.toggleButton.setTitle("Start")
            self.rateLabel.setText("")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        rateLabel.setText(error.localizedDescription)
    }
    
    func setRate(bpm: Int) {
        self.rateLabel.setText(String(bpm))
        
        // also send to phone?
    }
    
    
    @IBAction func toggleButtonPressed() {
        if (isRunning) {
            workoutSession?.end()
            hkStore?.stop(hkQuery!)
            self.isRunning = false
            self.startDate = nil
            return
        }
        
        let config = HKWorkoutConfiguration()
        config.activityType = HKWorkoutActivityType.other
        config.locationType = HKWorkoutSessionLocationType.indoor
        
        do {
            self.workoutSession = try HKWorkoutSession(healthStore: hkStore!, configuration: config)
            self.workoutSession!.delegate = self
            
            self.workoutSession?.startActivity(with: startDate)
            
            let heartrateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [])
            
            self.hkQuery = HKAnchoredObjectQuery(type: heartrateType!,
                predicate: predicate,
                anchor: nil,
                limit: Int(HKObjectQueryNoLimit)) { (query, newSamples, deletedSamples, newAnchor, error) -> Void in
                    if(error != nil) {
                        print(error!.localizedDescription)
                        return
                    }
                    if (newSamples == nil) {
                        return
                    }
                
                    let lastSample = newSamples!.last as? HKQuantitySample
                    let bpm = Int(lastSample!.quantity.doubleValue(for: self.heartRateUnit))
                        
                    self.setRate(bpm: bpm)
            }
            
            self.hkQuery!.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in
                if(error != nil) {
                    self.rateLabel.setText(error?.localizedDescription)
                    return
                }
                if (samples == nil) {
                    return
                }
                let lastSample = samples!.last as? HKQuantitySample
                let bpm = Int(lastSample!.quantity.doubleValue(for: self.heartRateUnit))
                
                self.setRate(bpm: bpm)
            }
            
            self.hkStore?.execute(hkQuery!)
        } catch {
            self.isRunning = false
            self.rateLabel.setText(error.localizedDescription)
        }
    }
    
    private func initHealthStore() {
        let sampleTypes = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
            
        hkStore?.requestAuthorization(toShare: [sampleTypes], read: [sampleTypes]) {
            (success: Bool, error: Error?) -> Void in
            if (error != nil) {
                self.rateLabel.setText(error!.localizedDescription)
            }
        }
    }

}
