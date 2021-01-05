//
//  ViewController.swift
//  HeartrateTransmitter
//
//  Created by Kasra Rahjerdi on 1/5/21.
//

import UIKit
import HealthKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {
    
    @IBOutlet var hkLabel: UILabel!
    @IBOutlet var rateLabel: UILabel!
    
    var hkStore: HKHealthStore?

    override func viewDidLoad() {
        super.viewDidLoad()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        hkStore = HKHealthStore()
        hkLabel.text = "HealthKit Store: DISABLED"

        initHealthStore()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // activated
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // inactivated
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // deactivated
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let rate = message["bpm"] as! String

        DispatchQueue.main.async {
            self.rateLabel.text = rate
        }
    }

    private func initHealthStore() {
        let sampleTypes = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        hkStore!.requestAuthorization(toShare: [sampleTypes], read: [sampleTypes]) {
            (success: Bool, error: Error?) -> Void in
            if (!success || error != nil) {
                let alertController = UIAlertController(title: "Error initializing HealthKit", message: error == nil ? "Unknown error :(" : error!.localizedDescription, preferredStyle: .alert)
                let action = UIAlertAction(title: "Try again?", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    self.hkLabel.text = "HealthKit Store: ENABLED"
                }
            }
        }
    }

}

