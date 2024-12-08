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
    
	internal var mModelNumberCharacteristic: disStringCharacteristic
	internal var mFirmwareRevisionCharacteristic: disFirmwareVersionCharacteristic
	internal var mSoftwareRevisionCharacteristic: disSoftwareRevisionCharacteristic
	internal var mHardwareRevisionCharacteristic: disStringCharacteristic
	internal var mManufacturerNameCharacteristic: disStringCharacteristic
	internal var mSerialNumberCharacteristic: disStringCharacteristic

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
    
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func setupSubscribers() {
		mModelNumberCharacteristic.$value
			.sink { [weak self] in self?.modelNumber = $0 }
			.store(in: &pSubscriptions)

		mHardwareRevisionCharacteristic.$value
			.sink { [weak self] in self?.hardwareRevision = $0 }
			.store(in: &pSubscriptions)

		mManufacturerNameCharacteristic.$value
			.sink { [weak self] in self?.manufacturerName = $0 }
			.store(in: &pSubscriptions)

		mSerialNumberCharacteristic.$value
			.sink { [weak self] in self?.serialNumber = $0 }
			.store(in: &pSubscriptions)

		mFirmwareRevisionCharacteristic.$value
			.sink { [weak self] in self?.firmwareRevision = $0 }
			.store(in: &pSubscriptions)
		
		mSoftwareRevisionCharacteristic.$bluetooth
			.sink { [weak self] in self?.bluetoothSoftwareRevision = $0 }
			.store(in: &pSubscriptions)

		mSoftwareRevisionCharacteristic.$algorithms
			.sink { [weak self] in self?.algorithmsSoftwareRevision = $0 }
			.store(in: &pSubscriptions)

		mSoftwareRevisionCharacteristic.$sleep
			.sink { [weak self] in self?.sleepSoftwareRevision = $0 }
			.store(in: &pSubscriptions)
		
		// Get Configured - 2 step process as so many characteristics
		let partialConfigured1 = Publishers.CombineLatest3(
			mModelNumberCharacteristic.$configured,
			mHardwareRevisionCharacteristic.$configured,
			mManufacturerNameCharacteristic.$configured
		).map { $0 && $1 && $2 }
		
		let partialConfigured2 = Publishers.CombineLatest3(
			mSerialNumberCharacteristic.$configured,
			mFirmwareRevisionCharacteristic.$configured,
			mFirmwareRevisionCharacteristic.$configured
		).map { $0 && $1 && $2 }

		Publishers.CombineLatest(partialConfigured1, partialConfigured2)
			.sink { [weak self] in
				self?.pConfigured = $0 && $1
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
	#if UNIVERSAL
    init(_ type: biostrapDeviceSDK.biostrapDeviceType) {
		mModelNumberCharacteristic = disStringCharacteristic()
		mFirmwareRevisionCharacteristic = disFirmwareVersionCharacteristic()
		mSoftwareRevisionCharacteristic = disSoftwareRevisionCharacteristic(type)
		mHardwareRevisionCharacteristic = disStringCharacteristic()
		mManufacturerNameCharacteristic = disStringCharacteristic()
		mSerialNumberCharacteristic = disStringCharacteristic()
        super.init()
		
		setupSubscribers()
    }
    #endif
	
	#if ALTER || KAIROS
	init() {
		mModelNumberCharacteristic = disStringCharacteristic()
		mFirmwareRevisionCharacteristic = disFirmwareVersionCharacteristic()
		mSoftwareRevisionCharacteristic = disSoftwareRevisionCharacteristic()
		mHardwareRevisionCharacteristic = disStringCharacteristic()
		mManufacturerNameCharacteristic = disStringCharacteristic()
		mSerialNumberCharacteristic = disStringCharacteristic()
		
		super.init()
		setupSubscribers()
	}
	#endif

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.model_number_string.UUID:
			mModelNumberCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
        case org_bluetooth_characteristic.hardware_revision_string.UUID:
			mHardwareRevisionCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
        case org_bluetooth_characteristic.manufacturer_name_string.UUID:
			mManufacturerNameCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
        case org_bluetooth_characteristic.serial_number_string.UUID:
			mSerialNumberCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
        case org_bluetooth_characteristic.firmware_revision_string.UUID:
			mFirmwareRevisionCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
        case org_bluetooth_characteristic.software_revision_string.UUID:
			mSoftwareRevisionCharacteristic.didDiscover(characteristic, commandQ: commandQ)

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
            mModelNumberCharacteristic.didUpdateValue()

        case org_bluetooth_characteristic.hardware_revision_string.UUID:
            mHardwareRevisionCharacteristic.didUpdateValue()
            
        case org_bluetooth_characteristic.manufacturer_name_string.UUID:
            mManufacturerNameCharacteristic.didUpdateValue()
            
        case org_bluetooth_characteristic.serial_number_string.UUID:
            mSerialNumberCharacteristic.didUpdateValue()
            
        case org_bluetooth_characteristic.firmware_revision_string.UUID:
            mFirmwareRevisionCharacteristic.didUpdateValue()
            
        case org_bluetooth_characteristic.software_revision_string.UUID:
            mSoftwareRevisionCharacteristic.didUpdateValue()

        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)")
        }
    }
}
