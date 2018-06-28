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
}

class ViewController: UIViewController, MultiPeerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MultiPeer.instance.initialize(serviceType: "demo-app")
        MultiPeer.instance.autoConnect()
        MultiPeer.instance.delegate = self
    }
    
    @IBAction func sendData() {
        MultiPeer.instance.send(object: "Hello World!", type: DataType.string.rawValue)
    }
    
    func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
        switch type {
        case DataType.string.rawValue:
            let string = data.convert() as! String
            // do something with the received string
            break;
            
        case DataType.image.rawValue:
            let image = UIImage(data: data)
            // do something with the received UIImage
            break;
            
        default:
            break;
        }
    }
    
    func multiPeer(connectedDevicesChanged devices: [String]) {
    }
}

