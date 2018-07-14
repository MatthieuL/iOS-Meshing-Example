//
//  ViewController.swift
//  iOSMeshing
//
//  Created by Matthieu LEFEBVRE on 05/07/2018.
//  Copyright © 2018 Matthieu LEFEBVRE. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreNFC

enum DataType: UInt32 {
    case string = 1
    case image = 2
}

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var receivedDataLabel: UILabel!
    @IBOutlet weak var connectedDevicesLabel: UILabel!
    
    private var scanner: NFCReaderSession?
    private var thingyManager: ThingyManager?
    private var connectedIOSDevicesNames: [String] = [] {
        didSet {
            var resultString = ""
            for s in connectedIOSDevicesNames {
                resultString += s + "\n"
            }
            for p in targetPeripherals {
                resultString += p.name + "\n"
            }
            DispatchQueue.main.async {
                self.connectedDevicesLabel.text = resultString
            }
        }
    }
    private var targetPeripherals: [ThingyPeripheral] = [] {
        didSet {
            // When a new peripheral has been added, set it as a current one and update its state
            for p in targetPeripherals {
                p.delegate = self
                p.discoverServices()
                p.state = .connected
            }
            
            // Update display
            
            var resultString = ""
            for s in connectedIOSDevicesNames {
                resultString += s + "\n"
            }
            for p in targetPeripherals {
                resultString += p.name + "\n"
            }
            DispatchQueue.main.async {
                self.connectedDevicesLabel.text = resultString
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MultiPeer.instance.initialize(serviceType: "demo-app")
        MultiPeer.instance.autoConnect()
        MultiPeer.instance.delegate = self
        
        thingyManager = ThingyManager(withDelegate: self)
        thingyManager!.delegate = self
//        startNFCScan()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextField.delegate = self
        thingyManager!.discoverDevices()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func sendData() {
        MultiPeer.instance.send(object: "Hello World!", type: DataType.string.rawValue)
    }
}

extension ViewController: ThingyManagerDelegate, ThingyPeripheralDelegate, NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
    }
    
    func startNFCScan() {
        scanner = NFCNDEFReaderSession(delegate: self as! NFCNDEFReaderSessionDelegate, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
        scanner!.alertMessage = "Touch your Thingy:52"
        scanner!.begin()
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        print("did discover \(peripheral)")
        thingyManager!.connect(toDevice: peripheral)
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode: String?) {
        print("did discover \(peripheral) with pairing code \(withPairingCode)")
        thingyManager!.connect(toDevice: peripheral)
        targetPeripherals.append(peripheral)
    }
    
    
    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        print("Thingy Manager state changed to: \(state)")
        //TODO: handle turning OFF Bluetooth
    }
    
    private func assignSelfAsPeripheralsDelegate() {
        let storedPeripherals = thingyManager!.storedPeripherals()
        if storedPeripherals != nil {
            for peripheral in storedPeripherals! {
                peripheral.delegate = self
            }
        }
    }
    
    private func reloadPeripherals(activeOnly: Bool) {
        guard thingyManager != nil else {
            print("No manager set")
            return
        }
        
//        menuPeripherals.removeAll()
        if activeOnly {
            if let activePeripherals = thingyManager!.activePeripherals() {
                print(activePeripherals)
            }
        } else {
            if let storedPeripherals = thingyManager!.storedPeripherals() {
                print(storedPeripherals)
            }
        }
    }
    
    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        if state == .ready {
            peripheral.beginBatteryLevelNotifications(withCompletionHandler: { (success) -> (Void) in
                if success {
                    print("Battery notifications enabled")
                } else {
                    print("Battery notifications failed to start")
                }
            }, andNotificationHandler: { (level) -> (Void) in
                
            })
        }
    }
}

extension ViewController: MultiPeerDelegate {
    
    func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
        switch type {
        case DataType.string.rawValue:
            let string = data.convert() as! String
            // do something with the received string
            print("received \(string)")
            parseStringForThingy(string)
            DispatchQueue.main.async {
                self.receivedDataLabel.text = string
            }
            break;
            
        case DataType.image.rawValue:
            _ = UIImage(data: data)
            // do something with the received UIImage
            break;
            
        default:
            break;
        }
    }
    
    func multiPeer(connectedDevicesChanged devices: [String]) {
        print("Connected to: \(devices)")
        connectedDevicesLabel.text = ""
        connectedIOSDevicesNames = devices
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("should return \(textField.text)")
        MultiPeer.instance.send(object: textField.text ?? "zut", type: DataType.string.rawValue)
        parseStringForThingy(textField.text ?? "")
        
        return true
    }
    
    func parseStringForThingy(_ value: String) {
        if value == "red" {
            for targetPeripheral in targetPeripherals {
                print()
                print(targetPeripheral.readLEDState())
                print("\(targetPeripheral.state))")
                targetPeripheral.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
                    print("Constant LED on \(success) with color: \(UIColor.red)")
                }, andColor: .red)
            }
        } else if value == "blue" {
                for targetPeripheral in targetPeripherals {
                    print()
                    print(targetPeripheral.readLEDState())
                    print("\(targetPeripheral.state))")
                    targetPeripheral.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
                        print("Constant LED on \(success) with color: \(UIColor.red)")
                    }, andColor: .blue)
                }
        } else if value == "purple" {
            for targetPeripheral in targetPeripherals {
                print()
                print(targetPeripheral.readLEDState())
                print("\(targetPeripheral.state))")
                targetPeripheral.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
                    print("Constant LED on \(success) with color: \(UIColor.red)")
                }, andColor: .purple)
            }
        } else if value == "white" {
            for targetPeripheral in targetPeripherals {
                print()
                print(targetPeripheral.readLEDState())
                print("\(targetPeripheral.state))")
                targetPeripheral.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
                    print("Constant LED on \(success) with color: \(UIColor.red)")
                }, andColor: .white)
            }
        } else if value == "yellow" {
            for targetPeripheral in targetPeripherals {
                print()
                print(targetPeripheral.readLEDState())
                print("\(targetPeripheral.state))")
                targetPeripheral.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
                    print("Constant LED on \(success) with color: \(UIColor.red)")
                }, andColor: .yellow)
            }
        } else {
            for targetPeripheral in targetPeripherals {
                print()
                print(targetPeripheral.readLEDState())
                print("\(targetPeripheral.state))")
                targetPeripheral.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
                    print("Constant LED on \(success) with color: \(UIColor.red)")
                }, andColor: .cyan)
            }
        }
    }
    
    @IBAction func scanThingys() {
        thingyManager!.discoverDevices()
    }
}

