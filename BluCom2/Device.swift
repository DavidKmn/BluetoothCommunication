//
//  Device.swift
//  BluCom2
//
//  Created by David on 14/11/2017.
//  Copyright © 2017 David. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Device {
    
    //UUIDs
    static let TransferService = CBUUID(string: "B981CB4C-08AF-48FC-A03C-E6F7BDEB2A14")
    static let TransferCharacteristic = CBUUID(string: "F1A31D66-C841-4B51-8023-D0EEB09ABCA7")
    
    //max transfer 20 bytes per data chunk
    static let notifyMTU = 20

    // End Of Message Tag (EOM)
    static let EOM = "{{{EOM}}}"
    
    static let centralRestoreIdentifier = "io.applinco.BlueCom2.CentralManager"
    static let peripheralRestoreIdentifier = "io.cloudcity.BlueCom2.PeripheralManager"
}
