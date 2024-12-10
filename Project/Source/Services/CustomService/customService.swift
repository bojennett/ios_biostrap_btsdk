//
//  customService.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/9/24.
//

import Foundation
import CoreBluetooth
import Combine

class customService: ServiceTemplate {
    
    internal var dataCharacteristic: customDataCharacteristic
    internal var strmCharacteristic: customStreamingCharacteristic

    @Published private(set) var worn: Bool?
    @Published private(set) var charging: Bool?
    @Published private(set) var on_charger: Bool?
    @Published private(set) var charge_error: Bool?
    @Published private(set) var buttonTaps: Int?
    @Published private(set) var ppgMetrics: ppgMetricsType?

    let dataPackets = PassthroughSubject<(Int, String), Never>()
    let dataComplete = PassthroughSubject<(Int, Int, Int, Int, Bool), Never>()
    
    let ppgFailed = PassthroughSubject<Int, Never>()
    let manufacturingTestResult = PassthroughSubject<(Bool, String), Never>()
    let streamingPacket = PassthroughSubject<String, Never>()
    let dataAvailable = PassthroughSubject<Void, Never>()

    let endSleepStatus = PassthroughSubject<Bool, Never>()

    enum services: String {
        #if UNIVERSAL || ALTER
        case alter            = "883BBA2C-8E31-40BB-A859-D59A2FB38EC0"
        #endif
        
        #if UNIVERSAL || KAIROS
        case kairos            = "140BB753-9845-4C0E-B61A-E6BAE41712F0"
        #endif

        var UUID: CBUUID {
            return CBUUID(string: self.rawValue)
        }
        
        var title: String {
            switch (self) {
            #if UNIVERSAL || ALTER
            case .alter        : return "Alter Service"
            #endif

            #if UNIVERSAL || KAIROS
            case .kairos    : return "Kairos Service"
            #endif
            }
        }
    }

    enum characteristics: String {
        #if UNIVERSAL || ALTER
        case alterMainCharacteristic    = "883BBA2C-8E31-40BB-A859-D59A2FB38EC1"
        case alterDataCharacteristic    = "883BBA2C-8E31-40BB-A859-D59A2FB38EC2"
        case alterStrmCharacteristic    = "883BBA2C-8E31-40BB-A859-D59A2FB38EC3"
        #endif

        #if UNIVERSAL || KAIROS
        case kairosMainCharacteristic    = "140BB753-9845-4C0E-B61A-E6BAE41712F1"
        case kairosDataCharacteristic    = "140BB753-9845-4C0E-B61A-E6BAE41712F2"
        case kairosStrmCharacteristic    = "140BB753-9845-4C0E-B61A-E6BAE41712F3"
        #endif

        var UUID: CBUUID {
            return CBUUID(string: self.rawValue)
        }
        
        var title: String {
            switch (self) {
            #if UNIVERSAL || ALTER
            case .alterMainCharacteristic    : return "Alter Command Characteristic"
            case .alterDataCharacteristic    : return "Alter Data Characteristic"
            case .alterStrmCharacteristic    : return "Alter Streaming Characteristic"
            #endif

            #if UNIVERSAL || KAIROS
            case .kairosMainCharacteristic    : return "Kairos Command Characteristic"
            case .kairosDataCharacteristic    : return "Kairos Data Characteristic"
            case .kairosStrmCharacteristic    : return "Kairos Streaming Characteristic"
            #endif
            }
        }
    }
    
    override class var scan_services: [CBUUID] {
        #if UNIVERSAL
        return [ services.alter.UUID, services.kairos.UUID ]
        #endif
        
        #if ALTER
        return [ services.alter.UUID]
        #endif
        
        #if KAIROS
        return [ services.kairos.UUID]
        #endif
    }
    
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
		#if UNIVERSAL
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: return true
        case characteristics.alterStrmCharacteristic.UUID: return true
        case characteristics.kairosDataCharacteristic.UUID: return true
        case characteristics.kairosStrmCharacteristic.UUID: return true
        default: return false
        }
		#endif
        
		#if ALTER
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: return true
        case characteristics.alterStrmCharacteristic.UUID: return true
        default: return false
        }
		#endif

		#if KAIROS
        switch characteristic.uuid {
        case characteristics.kairosDataCharacteristic.UUID: return true
        case characteristics.kairosStrmCharacteristic.UUID: return true
        default: return false
        }
		#endif
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    // This is for updating from a file
    //
    //--------------------------------------------------------------------------------
    func didUpdateValue(_ data: Data, offset: Int) {
        dataCharacteristic.didUpdateValue(true, data: data, offset: offset)
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    private func setupSubscribers() {

        // Configured
        Publishers.CombineLatest(
            dataCharacteristic.$configured,
            strmCharacteristic.$configured)
            .sink { [weak self] dataConfigured, strmConfigured in
                self?.pConfigured = dataConfigured && strmConfigured
            }
            .store(in: &pSubscriptions)

        // Data characteristic
        dataCharacteristic.dataPackets
            .sink { sequence_number, packets in
                self.dataPackets.send((sequence_number, packets))
            }
            .store(in: &pSubscriptions)
        
        dataCharacteristic.dataComplete
            .sink {bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in
                self.dataComplete.send((bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate))
            }
            .store(in: &pSubscriptions)
        
        // Streaming Characteristic
        strmCharacteristic.$worn.sink { self.worn = $0 }.store(in: &pSubscriptions)
        strmCharacteristic.$charging.sink { self.charging = $0 }.store(in: &pSubscriptions)
        strmCharacteristic.$on_charger.sink { self.on_charger = $0 }.store(in: &pSubscriptions)
        strmCharacteristic.$charge_error.sink { self.charge_error = $0 }.store(in: &pSubscriptions)
        strmCharacteristic.$buttonTaps.sink { self.buttonTaps = $0 }.store(in: &pSubscriptions)
        strmCharacteristic.$ppgMetrics.sink { self.ppgMetrics = $0 }.store(in: &pSubscriptions)

        strmCharacteristic.endSleepStatus.sink { self.endSleepStatus.send($0) }.store(in: &pSubscriptions)
        strmCharacteristic.ppgFailed.sink { self.ppgFailed.send($0) }.store(in: &pSubscriptions)
        strmCharacteristic.streamingPacket.sink { self.streamingPacket.send($0) }.store(in: &pSubscriptions)
        strmCharacteristic.dataAvailable.sink { self.dataAvailable.send() }.store(in: &pSubscriptions)
        strmCharacteristic.manufacturingTestResult
            .sink { valid, result in
                self.manufacturingTestResult.send((valid, result))
            }
            .store(in: &pSubscriptions)
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override init() {
        dataCharacteristic = customDataCharacteristic()
        strmCharacteristic = customStreamingCharacteristic()
        super.init()
        
        setupSubscribers()
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        
        #if UNIVERSAL
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID:
            dataCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            dataCharacteristic.discoverDescriptors()

        case characteristics.alterStrmCharacteristic.UUID:
            strmCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            #if UNIVERSAL
            strmCharacteristic.type = .alter
            #endif
            strmCharacteristic.discoverDescriptors()

        case characteristics.kairosDataCharacteristic.UUID:
            dataCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            dataCharacteristic.discoverDescriptors()

        case characteristics.kairosStrmCharacteristic.UUID:
            strmCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            #if UNIVERSAL
            strmCharacteristic.type = .kairos
            #endif
            strmCharacteristic.discoverDescriptors()

        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
        #endif
        
        #if ALTER
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID:
            dataCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            dataCharacteristic.discoverDescriptors()

        case characteristics.alterStrmCharacteristic.UUID:
            strmCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            strmCharacteristic.discoverDescriptors()

        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
        #endif
        
        #if KAIROS
        switch characteristic.uuid {
        case characteristics.kairosDataCharacteristic.UUID:
            dataCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            dataCharacteristic.discoverDescriptors()

        case characteristics.kairosStrmCharacteristic.UUID:
            strmCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            strmCharacteristic.discoverDescriptors()

        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
        #endif
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverDescriptor(_ characteristic: CBCharacteristic) {
        #if UNIVERSAL
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didDiscoverDescriptor()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didDiscoverDescriptor()
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didDiscoverDescriptor()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didDiscoverDescriptor()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
        #endif
        
        #if ALTER
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didDiscoverDescriptor()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didDiscoverDescriptor()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
        #endif
        
        #if KAIROS
        switch characteristic.uuid {
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didDiscoverDescriptor()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didDiscoverDescriptor()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
        #endif
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didUpdateNotificationState(_ characteristic: CBCharacteristic) {
		#if UNIVERSAL
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didUpdateNotificationState()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didUpdateNotificationState()
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didUpdateNotificationState()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didUpdateNotificationState()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
		#endif
        
		#if ALTER
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didUpdateNotificationState()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didUpdateNotificationState()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
		#endif
        
		#if KAIROS
        switch characteristic.uuid {
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didUpdateNotificationState()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didUpdateNotificationState()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
		#endif
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didUpdateValue(_ characteristic: CBCharacteristic) {
		#if UNIVERSAL
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didUpdateValue()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didUpdateValue()
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didUpdateValue()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didUpdateValue()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
		#endif
        
		#if ALTER
        switch characteristic.uuid {
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didUpdateValue()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didUpdateValue()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
		#endif
        
		#if KAIROS
        switch characteristic.uuid {
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didUpdateValue()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didUpdateValue()
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
		#endif
    }

}
