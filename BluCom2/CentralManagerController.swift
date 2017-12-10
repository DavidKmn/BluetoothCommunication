//
//  CentralManagerController.swift
//  BluCom2
//
//  Created by David on 14/11/2017.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import CoreBluetooth

class CentralManagerController: UIViewController {
    
    let explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "The text below comes from the connected Peripheral:"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let outputTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.text = ""
        tv.isUserInteractionEnabled = false
        return tv
    }()
    
    let rssiLabel: UILabel = {
        let label = UILabel()
        label.clipsToBounds = true
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.borderWidth = 0.7
        label.layer.cornerRadius = 6
        label.text = "RSSI: "
        label.textAlignment = .left
        return label
    }()
    
    let connectionIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.Color.failureRed
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = 15
        return view
    }()
    
    lazy var startScanningButton: UIButton = {
        let but = UIButton(type: .system)
        but.titleLabel?.textAlignment = .center
        but.isHidden = true
        but.setTitleColor(.white, for: .normal)
        but.titleLabel?.font = Constants.Font.systemButton
        but.titleLabel?.numberOfLines = 0
        but.backgroundColor = Constants.Color.lightSystem
        but.setTitle("Start Scanning", for: .normal)
        but.addTarget(self, action: #selector(startScanning), for: .touchUpInside)
        return but
    }()
    
    var centralManager: CBCentralManager!
    var selectedPeripheral: CBPeripheral?
    
    var dataBuffer: NSMutableData!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dataBuffer = NSMutableData()
        outputTextView.text = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopScanning()
        disconnect()
    }
    
    private func setupUI() {
        
        view.backgroundColor = .white
        navigationItem.title = "Central Mode"
        
        view.addSubview(rssiLabel)
        
        rssiLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: nil, topPadding: 0, leadingPadding: 20, bottomPadding: 0, trailingPadding: 0, width: 100, height: 30)
        
        view.addSubview(connectionIndicatorView)
        
        connectionIndicatorView.anchor(top: rssiLabel.topAnchor, leading: nil, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 20, width: 30, height: 30)
        
        view.addSubview(explanationLabel)
        
         explanationLabel.anchor(top: rssiLabel.bottomAnchor, leading: rssiLabel.leadingAnchor, bottom: nil, trailing: connectionIndicatorView.safeAreaLayoutGuide.trailingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 20, width: 0, height: 60)
        
        view.addSubview(outputTextView)
        
        outputTextView.anchor(top: explanationLabel.bottomAnchor, leading: explanationLabel.leadingAnchor, bottom: nil, trailing: explanationLabel.trailingAnchor, topPadding: 5, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 150)
        
        view.addSubview(startScanningButton)
        
        startScanningButton.anchor(top: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 50)
    }

    private func stopScanning() {
        centralManager?.stopScan()
    }
    
}

extension CentralManagerController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
         let state = central.state
        
        
        if state != .poweredOn {
            self.selectedPeripheral = nil
            return
        }
        
        startScanning()
    }
    
    @objc private func startScanning() {
        guard let centralManager = centralManager else { return }
        if centralManager.isScanning {
            print("Central Manager is already scanning !!!")
            return
        }
        
        centralManager.scanForPeripherals(withServices: [Device.TransferService], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("Started Scanning!")
        startScanningButton.isHidden = true
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Discovered \(peripheral.name ?? "") at \(RSSI)")

        rssiLabel.text = "RSSI: \(RSSI.stringValue)"
        
        // too far away from us
        if RSSI.intValue < -50 {
            rssiLabel.textColor = Constants.Color.failureRed
            return
        }
        
        rssiLabel.textColor = .green
        
        if self.selectedPeripheral != peripheral {
            
            self.selectedPeripheral = peripheral
            
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("Peripheral Connected!!!")
        connectionIndicatorView.backgroundColor = Constants.Color.successGreen
        
        stopScanning()
        print("Scanning Stopped!")
        
        
        // Clear any cached data ...
        dataBuffer.length = 0
        
        peripheral.delegate = self
        
        peripheral.discoverServices([Device.TransferService])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral) (\(String(describing: error?.localizedDescription)))")
        connectionIndicatorView.backgroundColor = Constants.Color.failureRed
        disconnect()
    }
    
    private func disconnect() {
        guard let peripheral = self.selectedPeripheral else {
            return
        }
        
        if peripheral.state != .connected {
            self.selectedPeripheral = nil
            return
        }
        
        guard let services = peripheral.services else {
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        for service in services {
            if let chars = service.characteristics {
                for char in chars {
                    if char.uuid == Device.TransferCharacteristic {
                        // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                        // didUpdateNotificationStateForCharacteristic method will be called automatically
                        peripheral.setNotifyValue(false, for: char)
                        return
                    }
                }
            }
        }
        
        // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Disconnected from Peripheral")
        connectionIndicatorView.backgroundColor = Constants.Color.failureRed
        self.selectedPeripheral = nil

    }
}

extension CentralManagerController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            disconnect()
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service)")
                
                if service.uuid == Device.TransferService {
                    peripheral.discoverCharacteristics([Device.TransferCharacteristic], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        if let chars = service.characteristics {
            for char in chars {
                if char.uuid == Device.TransferCharacteristic {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            print("Error updating value for characteristic: \(characteristic) - \(error.localizedDescription)")
            return
        }
        
        
        guard let value = characteristic.value else {
            return
        }
        
        print("Bytes transferred: \(value.count)")
        
        guard let nextChunk = String(data: value, encoding: String.Encoding.utf8) else {
            print("Next chunk of data is nil.")
            return
        }
        
        print("Next chunk: \(nextChunk)")
        
        // If we get the EOM tag, we fill the text view
        if nextChunk == Device.EOM {
            if let message = String(data: dataBuffer as Data, encoding: String.Encoding.utf8) {
                
                outputTextView.text = message
                
                // truncate our buffer now that we received the EOM signal!
                dataBuffer.length = 0
                
                disconnect()
            }
        } else {
            dataBuffer.append(value)
            if let buffer = self.dataBuffer {
                print("Transfer buffer: \(String(data: buffer as Data, encoding: String.Encoding.utf8) ?? "")")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notification STARTED on characteristic: \(characteristic)")
        } else {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}














