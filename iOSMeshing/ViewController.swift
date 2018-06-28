//
//  ViewController.swift
//  iOSMeshing
//
//  Created by Matthieu LEFEBVRE on 23/06/2018.
//  Copyright © 2018 Matthieu LEFEBVRE. All rights reserved.
//

import UIKit
import MultipeerConnectivity

enum DataType: UInt32 {
    case string = 1
    case image = 2
}

class ViewController: UIViewController, UITextFieldDelegate, MultiPeerDelegate {

    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var receivedDataLabel: UILabel!
    @IBOutlet weak var connectedDevicesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MultiPeer.instance.initialize(serviceType: "demo-app")
        MultiPeer.instance.autoConnect()
        MultiPeer.instance.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextField.delegate = self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func sendData() {
        MultiPeer.instance.send(object: "Hello World!", type: DataType.string.rawValue)
    }
    
    func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
        switch type {
        case DataType.string.rawValue:
            let string = data.convert() as! String
            // do something with the received string
            print("received \(string)")
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
        for deviceName in devices {
            DispatchQueue.main.async {
                self.connectedDevicesLabel.text = deviceName
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("should return \(textField.text)")
        MultiPeer.instance.send(object: textField.text ?? "zut", type: DataType.string.rawValue)
        return true
    }
}

