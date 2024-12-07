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
    
    internal var mHeartRateMeasurementCharacteristic: heartRateMeasurementCharacteristic?
    internal var mBodySensorLocationCharacteristic: bodySensorLocationCharacteristic?

    @Published var batteryLevel: Int?
    var lambdaUpdated: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
    let updated = PassthroughSubject<(Int, Int, [Double]), Never>()

    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override class var scan_service: CBUUID {
        return org_bluetooth_service.heart_rate.UUID
    }
    
    override class func discover_characteristics() -> [ CBUUID ] {
        return [ org_bluetooth_characteristic.heart_rate_measurement.UUID ]
    }
    
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID: return true
        case org_bluetooth_characteristic.body_sensor_location.UUID: return true
        default: return false
        }
    }
    
    override var configured: Bool {
        return mHeartRateMeasurementCharacteristic?.configured ?? false
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID:
            mHeartRateMeasurementCharacteristic = heartRateMeasurementCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mHeartRateMeasurementCharacteristic?.updated
                .sink { [weak self] (epoch, hr, rr) in
                    self?.updated.send((epoch, hr, rr))
                }
                .store(in: &pSubscriptions)

            mHeartRateMeasurementCharacteristic?.lambdaUpdated    = { id, epoch, hr, rr in
                self.lambdaUpdated?(id, epoch, hr, rr)
            }

            mHeartRateMeasurementCharacteristic?.didDiscover()
        case org_bluetooth_characteristic.body_sensor_location.UUID:
            mBodySensorLocationCharacteristic = bodySensorLocationCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mBodySensorLocationCharacteristic?.didDiscover()
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
            mHeartRateMeasurementCharacteristic?.didDiscoverDescriptor()
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
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
            mHeartRateMeasurementCharacteristic?.didUpdateNotificationState()
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
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
        case org_bluetooth_characteristic.heart_rate_measurement.UUID: mHeartRateMeasurementCharacteristic?.didUpdateValue()
        case org_bluetooth_characteristic.body_sensor_location.UUID: mBodySensorLocationCharacteristic?.didUpdateValue()
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
        }
    }
}
