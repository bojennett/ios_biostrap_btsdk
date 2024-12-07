//
//  disService.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/7/24.
//

import Foundation
import CoreBluetooth
import Combine

class disService: ServiceTemplate {
    
    internal var mModelNumberCharacteristic : disStringCharacteristic?
    internal var mFirmwareRevisionCharacteristic : disFirmwareVersionCharacteristic?
    internal var mSoftwareRevisionCharacteristic : disSoftwareRevisionCharacteristic?
    internal var mHardwareRevisionCharacteristic : disStringCharacteristic?
    internal var mManufacturerNameCharacteristic : disStringCharacteristic?
    internal var mSerialNumberCharacteristic : disStringCharacteristic?
    internal var mDISCharacteristicCount : Int = 0
    internal var mDISCharacteristicsDiscovered : Bool = false

    @Published var modelNumber: String?
    @Published var hardwareRevision: String?
    @Published var manufacturerName: String?
    @Published var serialNumber: String?
    @Published var firmwareRevision: String?
    @Published var bluetoothSoftwareRevision: String?
    @Published var algorithmsSoftwareRevision: String?
    @Published var sleepSoftwareRevision: String?
    
	#if UNIVERSAL
    var type = biostrapDeviceSDK.biostrapDeviceType.unknown
    #endif

    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override class var scan_service: CBUUID {
        return org_bluetooth_service.heart_rate.UUID
    }
    
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.model_number_string.UUID: return true
        case org_bluetooth_characteristic.hardware_revision_string.UUID: return true
        case org_bluetooth_characteristic.manufacturer_name_string.UUID: return true
        case org_bluetooth_characteristic.serial_number_string.UUID: return true
        case org_bluetooth_characteristic.firmware_revision_string.UUID: return true
        case org_bluetooth_characteristic.software_revision_string.UUID: return true
        default: return false
        }
    }
    
    override var isConfigured: Bool {
        //globals.log.w ("\(mDISCharacteristicsDiscovered) - \(mDISCharacteristicCount) \(mModelNumberCharacteristic?.configured):\(mHardwareRevisionCharacteristic?.configured):\(mManufacturerNameCharacteristic?.configured):\(mSerialNumberCharacteristic?.configured):\(mFirmwareRevisionCharacteristic?.configured)")
        
        if mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 {
            if let mModelNumberCharacteristic,
               let mHardwareRevisionCharacteristic,
               let mManufacturerNameCharacteristic,
               let mSerialNumberCharacteristic,
               let mFirmwareRevisionCharacteristic,
               let mSoftwareRevisionCharacteristic {
                return mModelNumberCharacteristic.configured &&
                       mHardwareRevisionCharacteristic.configured &&
                       mManufacturerNameCharacteristic.configured &&
                       mSerialNumberCharacteristic.configured &&
                       mFirmwareRevisionCharacteristic.configured &&
                       mSoftwareRevisionCharacteristic.configured
            }
        }
        
        return false
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	#if UNIVERSAL
    init(_ commandQ: CommandQ?, type: biostrapDeviceSDK.biostrapDeviceType) {
        super .init(commandQ)
    }
    #endif

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.model_number_string.UUID:
            mDISCharacteristicsDiscovered = true
            mDISCharacteristicCount += 1
            
            mModelNumberCharacteristic = disStringCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mModelNumberCharacteristic?.$value
                .sink { [weak self] in
                    self?.modelNumber = $0
                }
                .store(in: &pSubscriptions)

            mModelNumberCharacteristic?.didDiscover()
            
        case org_bluetooth_characteristic.hardware_revision_string.UUID:
            mDISCharacteristicsDiscovered = true
            mDISCharacteristicCount += 1
            
            mHardwareRevisionCharacteristic = disStringCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mHardwareRevisionCharacteristic?.$value
                .sink { [weak self] in
                    self?.hardwareRevision = $0
                }
                .store(in: &pSubscriptions)
            
            mHardwareRevisionCharacteristic?.didDiscover()
            
        case org_bluetooth_characteristic.manufacturer_name_string.UUID:
            mDISCharacteristicsDiscovered = true
            mDISCharacteristicCount += 1
            
            mManufacturerNameCharacteristic = disStringCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mManufacturerNameCharacteristic?.$value
                .sink { [weak self] in
                    self?.manufacturerName = $0
                }
                .store(in: &pSubscriptions)
            
            mManufacturerNameCharacteristic?.didDiscover()
            
        case org_bluetooth_characteristic.serial_number_string.UUID:
            mDISCharacteristicsDiscovered = true
            mDISCharacteristicCount += 1
            
            mSerialNumberCharacteristic = disStringCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mSerialNumberCharacteristic?.$value
                .sink { [weak self] in
                    self?.serialNumber = $0
                }
                .store(in: &pSubscriptions)
            
            mSerialNumberCharacteristic?.didDiscover()
            
        case org_bluetooth_characteristic.firmware_revision_string.UUID:
            mDISCharacteristicsDiscovered    = true
            mDISCharacteristicCount += 1
            mFirmwareRevisionCharacteristic = disFirmwareVersionCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mFirmwareRevisionCharacteristic?.$value
                .sink { [weak self] in
                    self?.firmwareRevision = $0
                }
                .store(in: &pSubscriptions)

            mFirmwareRevisionCharacteristic?.didDiscover()
            
        case org_bluetooth_characteristic.software_revision_string.UUID:
            mDISCharacteristicsDiscovered    = true
            mDISCharacteristicCount += 1
            #if UNIVERSAL
            mSoftwareRevisionCharacteristic = disSoftwareRevisionCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ, type: type)
            #else
            mSoftwareRevisionCharacteristic = disSoftwareRevisionCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            #endif
            
            mSoftwareRevisionCharacteristic?.$bluetooth
                .sink { [weak self] in
                    self?.bluetoothSoftwareRevision = $0
                }
                .store(in: &pSubscriptions)

            mSoftwareRevisionCharacteristic?.$algorithms
                .sink { [weak self] in
                    self?.algorithmsSoftwareRevision = $0
                }
                .store(in: &pSubscriptions)

            mSoftwareRevisionCharacteristic?.$sleep
                .sink { [weak self] in
                    self?.sleepSoftwareRevision = $0
                }
                .store(in: &pSubscriptions)

            mSoftwareRevisionCharacteristic?.didDiscover()

        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)")
        }
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didUpdateValue(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.model_number_string.UUID:
            mDISCharacteristicCount -= 1
            mModelNumberCharacteristic?.didUpdateValue()

        case org_bluetooth_characteristic.hardware_revision_string.UUID:
            mDISCharacteristicCount -= 1
            mHardwareRevisionCharacteristic?.didUpdateValue()
            
        case org_bluetooth_characteristic.manufacturer_name_string.UUID:
            mDISCharacteristicCount -= 1
            mManufacturerNameCharacteristic?.didUpdateValue()
            
        case org_bluetooth_characteristic.serial_number_string.UUID:
            mDISCharacteristicCount -= 1
            mSerialNumberCharacteristic?.didUpdateValue()
            
        case org_bluetooth_characteristic.firmware_revision_string.UUID:
            mDISCharacteristicCount -= 1
            mFirmwareRevisionCharacteristic?.didUpdateValue()
            
        case org_bluetooth_characteristic.software_revision_string.UUID:
            mDISCharacteristicCount -= 1
            mSoftwareRevisionCharacteristic?.didUpdateValue()

        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)")
        }
    }

}
