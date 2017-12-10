//
//  PeripheralManagerController.swift
//  BluCom2
//
//  Created by David on 14/11/2017.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralManagerController: UIViewController {
    
    lazy var advertisingSwitch: UISwitch = {
        let adSwitch = UISwitch()
        adSwitch.setOn(true, animated: true)
        adSwitch.onTintColor = Constants.Color.successGreen
        adSwitch.translatesAutoresizingMaskIntoConstraints = false
        adSwitch.addTarget(self, action: #selector(handleAdvertisingSwitchValueChange), for: .touchUpInside)
        return adSwitch
    }()
    
    lazy var sendDataButton: UIButton = {
        let but = UIButton(type: .system)
        but.setTitle("Send", for: .normal)
        but.backgroundColor = Constants.Color.lightSystem
        but.translatesAutoresizingMaskIntoConstraints = false
        but.layer.cornerRadius = 5
        but.titleLabel?.font = Constants.Font.systemButton
        but.layer.masksToBounds = true
        but.isHidden = false
        but.addTarget(self, action: #selector(captureCurrentText), for: .touchUpInside)
        return but
    }()
    
    let explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter the text to transfer to the Central below: "
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let inputTextView: UITextView = {
        let tv = UITextView()
        tv.text = "Hello World from David!!!"
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.lightGray.cgColor
        return tv
    }()
    
    
    var peripheralManager: CBPeripheralManager?
    var transferCharacteristic: CBMutableCharacteristic?
    
    var dataToSend: Data?
    var sendDataIndex = 0
    let notifyMTU = 20
    var sendingEOM = false
    var contentUpdated = false
    var currentTextSnapshot = ""
    var sendingTextData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.peripheralManager?.stopAdvertising()
        self.peripheralManager = nil
        super.viewWillDisappear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.title = "Peripheral Mode"
        
        view.addSubview(explanationLabel)
        
        explanationLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, topPadding: 0, leadingPadding: 20, bottomPadding: 0, trailingPadding: 20, width: 0, height: 60)
        
        view.addSubview(inputTextView)
        
        inputTextView.anchor(top: explanationLabel.bottomAnchor, leading: explanationLabel.leadingAnchor, bottom: nil, trailing: explanationLabel.trailingAnchor, topPadding: 5, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 150)
        
        view.addSubview(sendDataButton)
        
        sendDataButton.anchor(top: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.leadingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 50)
    }
    
    @objc private func handleAdvertisingSwitchValueChange() {
        if advertisingSwitch.isOn {
            startAdvertisingData()
        } else {
            peripheralManager?.stopAdvertising()
            sendDataButton.isHidden = true
        }
    }
    
    private func setupServices() {
        
        transferCharacteristic = CBMutableCharacteristic(type: Device.TransferCharacteristic, properties: .notify, value: nil, permissions: .readable)
        
        let service = CBMutableService(type: Device.TransferService, primary: true)
        
        service.characteristics = [transferCharacteristic!]
        
        peripheralManager?.add(service)
    }
    
    @objc private func startAdvertisingData() {
        print("Peripheral Manager: Starting Advertising Transfer Service (\(Device.TransferService))")
        let servicesDictionary = [CBAdvertisementDataServiceUUIDsKey : [Device.TransferService]]
        peripheralManager?.startAdvertising(servicesDictionary)
    }
    
    @objc private func captureCurrentText() {
        
        // if we are not sending right now, capture the current state
        if (!sendingTextData) && (currentTextSnapshot != inputTextView.text) {
            print("Not currently sending data. Capturing snapshot and will send it over!")
            currentTextSnapshot = inputTextView.text
            dataToSend = currentTextSnapshot.data(using: .utf8)
            sendDataIndex = 0
            sendTextData()
        } else {
            print("Currently sending data. Will wait to capture in a second ...")
        }
        
    }
    
    private func sendTextData() {
        
        guard let peripheralManager = self.peripheralManager else {
            return
        }
        
        guard let transferCharacteristic = self.transferCharacteristic else {
            return
        }
        
        sendDataButton.isHidden = true
        
        // Is it time to for the EOM tag message?
        if sendingEOM {
            print("Attempting to send EOM ...")
            
            let eomData = Device.EOM.data(using: .utf8)
            let didSend = peripheralManager.updateValue(eomData!, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            if didSend {
                sendingEOM = false
                print("EOM has been Sent !!!")
                sendingTextData = false
                dataEnteredHasBeenSuccessfullySent()
            }
            
            // Return and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendTextData again
            return
        }
        
        
        // Not sending the EOM message, so we are going to send the data
        guard let dataToSend = dataToSend else {
            return
        }
        // no data left to send
        if sendDataIndex >= dataToSend.count {
            return
        }
        
        // Still data left to send, so we will send until the point at which: a) the callback fails or b) we are done
        var didSend = true
        while didSend {
            
            // turn on sending text flag to prevent updating buffer till we finish
            sendingTextData = true
            
            var amountToSend = dataToSend.count - sendDataIndex
            print("Next amount to send: \(amountToSend)")
            
            // have a 20 byte limit, so if amount to send > 20, then clamp it down to 20
            if (amountToSend > Device.notifyMTU) {
                amountToSend = Device.notifyMTU
            }
            
            // extract the data we want to send
            let upToIndex = sendDataIndex + amountToSend
            print("Next Chunk should be \(amountToSend) bytes long and goes from \(sendDataIndex) to \(upToIndex)")
            
            // verify chunk length
            let chunk = dataToSend.subdata(in: sendDataIndex..<upToIndex)
            print("Next Chunk is \(chunk.count) bytes long.")
            
            // output the chunk to see if we got the right block of text
            let chunkText = String(data: chunk, encoding: String.Encoding.utf8)
            print("Next Chunk from data: \(chunkText ?? "")")
            
            // Send the chunk of text...
            // updateValue sends an updated characteristic value to one or more subscribed centrals via a notification.
            // passing nil for the centrals notifies all subscribed centrals
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // if failed to send, drop out and wait for callback
            if !didSend {
                return
            }
            
            // Sent
            
            // update index
            sendDataIndex += amountToSend
            
            // Determine if that was last chunk of data to send, if yes, send EOM tag
            if sendDataIndex >= dataToSend.count {
                
                sendingEOM = true
                
                let eomData = Device.EOM.data(using: .utf8)
                let eomSend = peripheralManager.updateValue(eomData!, for: transferCharacteristic, onSubscribedCentrals: nil)
                if eomSend {
                    // we are done
                    sendingEOM = false
                    print("EOM has been Sent !!!")
                    sendingTextData = false
                    dataEnteredHasBeenSuccessfullySent()
                }
                return
            }
        }
    }
    
    
    private func dataEnteredHasBeenSuccessfullySent() {
        
        sendDataButton.isHidden = false
        
        let alertViewFrame = CGRect(x: 0, y: 0, width: 180, height: 100)
        let alertView = UITextView(frame: alertViewFrame)
        alertView.textAlignment  = .center
        alertView.font = UIFont.boldSystemFont(ofSize: 18)
        alertView.textColor = .white
        alertView.text = "Data Sent"
        
        alertView.center.y = view.center.y
        alertView.center.x = view.center.x
        alertView.backgroundColor = .darkGray
        alertView.alpha = 0
        
        view.addSubview(alertView)

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.alpha = 0.3
            alertView.alpha = 1
        }) { (completed) in
            if completed {
                UIView.animate(withDuration: 0.5, delay: 3, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.view.alpha = 1
                    alertView.alpha = 0
                }, completion: {(completed) in
                    if completed {
                        alertView.removeFromSuperview()
                    }
                })
            }
        }
    }
}

extension PeripheralManagerController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        let state = peripheral.state
        
        if state != .poweredOn {
            return
        }
        
        print("Bluetooth is Powerd Up !!!")
        
        setupServices()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central \(central.identifier.description) has subbed to characteristic")
        sendDataButton.isHidden = false
    }
 
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // This callback comes in when the PeripheralManager is ready to send the next chunk of data.
        // This is to ensure that packets will arrive in the order they are sent
        sendTextData()
    }
}


