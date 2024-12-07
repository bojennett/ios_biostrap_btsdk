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
    
    @Published private var hrmConfigured: Bool = false
    @Published private var bslConfigured: Bool = false

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
    override init(_ commandQ: CommandQ?) {
        super.init(commandQ)
        
        Publishers.CombineLatest($hrmConfigured, $bslConfigured)
            .sink { [weak self] hrmConfigured, bslConfigured in
                self?.pConfigured = hrmConfigured && bslConfigured
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
    override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case org_bluetooth_characteristic.heart_rate_measurement.UUID:
            mHeartRateMeasurementCharacteristic = heartRateMeasurementCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mHeartRateMeasurementCharacteristic?.updated
                .sink { [weak self] (epoch, hr, rr) in
                    self?.updated.send((epoch, hr, rr))
                }
                .store(in: &pSubscriptions)
            
            mHeartRateMeasurementCharacteristic?.$configured
                .sink { [weak self] in
                    self?.hrmConfigured = $0
                }
                .store(in: &pSubscriptions)

            mHeartRateMeasurementCharacteristic?.lambdaUpdated    = { id, epoch, hr, rr in
                self.lambdaUpdated?(id, epoch, hr, rr)
            }

            mHeartRateMeasurementCharacteristic?.didDiscover()
        case org_bluetooth_characteristic.body_sensor_location.UUID:
            mBodySensorLocationCharacteristic = bodySensorLocationCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mBodySensorLocationCharacteristic?.$configured
                .sink { [weak self] in
                    self?.bslConfigured = $0
                }
                .store(in: &pSubscriptions)

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
