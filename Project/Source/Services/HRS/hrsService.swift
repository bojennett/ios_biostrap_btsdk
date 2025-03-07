//
//  hrsService.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/6/24.
//

import Foundation
import CoreBluetooth
import Combine

class hrsService: ServiceTemplate {
    
    internal var mHeartRateMeasurementCharacteristic: heartRateMeasurementCharacteristic
    internal var mBodySensorLocationCharacteristic: bodySensorLocationCharacteristic

    @Published var bodySensorLocation: BodySensorLocation?
    let updated = PassthroughSubject<(Int, Int, [Double]), Never>()
    
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override class var scan_services: [ CBUUID ] {
        return [ org_bluetooth_service.heart_rate.UUID ]
    }
        
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID: return true
        case org_bluetooth_characteristic.body_sensor_location.UUID: return true
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
    override init() {
		mHeartRateMeasurementCharacteristic = heartRateMeasurementCharacteristic()
		mBodySensorLocationCharacteristic = bodySensorLocationCharacteristic()
		super.init()
		
		mHeartRateMeasurementCharacteristic.updated
			.sink { [weak self] (epoch, hr, rr) in
				self?.updated.send((epoch, hr, rr))
			}
			.store(in: &subscriptions)
        
        mBodySensorLocationCharacteristic.$location.sink { [weak self] location in self?.bodySensorLocation = location }.store(in: &subscriptions)            
		
        Publishers.CombineLatest(
			mHeartRateMeasurementCharacteristic.$configured,
			mBodySensorLocationCharacteristic.$configured)
            .sink { [weak self] hrmConfigured, bslConfigured in
                self?.configured = hrmConfigured && bslConfigured
            }
            .store(in: &subscriptions)
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID:
			mHeartRateMeasurementCharacteristic.didDiscover(characteristic, commandQ: commandQ)
        case org_bluetooth_characteristic.body_sensor_location.UUID:
			mBodySensorLocationCharacteristic.didDiscover(characteristic, commandQ: commandQ)
        default: return
        }
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverDescriptor(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID:
            mHeartRateMeasurementCharacteristic.didDiscoverDescriptor()
        default: globals.log.e ("\(id): Unhandled: \(characteristic.uuid)");
        }
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didUpdateNotificationState(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID:
            mHeartRateMeasurementCharacteristic.didUpdateNotificationState()
        default: globals.log.e ("\(id): Unhandled: \(characteristic.uuid)");
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
        case org_bluetooth_characteristic.heart_rate_measurement.UUID: mHeartRateMeasurementCharacteristic.didUpdateValue()
        case org_bluetooth_characteristic.body_sensor_location.UUID: mBodySensorLocationCharacteristic.didUpdateValue()
        default: globals.log.e ("\(id): Unhandled: \(characteristic.uuid)");
        }
    }
}
