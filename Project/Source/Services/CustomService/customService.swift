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
    
    internal var mainCharacteristic: customMainCharacteristic
    internal var dataCharacteristic: customDataCharacteristic
    internal var strmCharacteristic: customStreamingCharacteristic

    // Main Characteristic
    @Published private(set) var epoch: Int?
    @Published private(set) var canLogDiagnostics: Bool?
    @Published private(set) var wornCheckResult: DeviceWornCheckResultType?

    @Published private(set) var advertisingInterval: Int?
    @Published private(set) var chargeCycles: Float?
    @Published private(set) var advertiseAsHRM: Bool?
    @Published private(set) var rawLogging: Bool?
    @Published private(set) var wornOverridden: Bool?
    @Published private(set) var buttonResponseEnabled: Bool?
    
    @Published private(set) var singleButtonPressAction: buttonCommandType?
    @Published private(set) var doubleButtonPressAction: buttonCommandType?
    @Published private(set) var tripleButtonPressAction: buttonCommandType?
    @Published private(set) var longButtonPressAction: buttonCommandType?

    @Published private(set) var hrZoneLEDBelow: hrZoneLEDValueType?
    @Published private(set) var hrZoneLEDWithin: hrZoneLEDValueType?
    @Published private(set) var hrZoneLEDAbove: hrZoneLEDValueType?
    @Published private(set) var hrZoneRange: hrZoneRangeValueType?
    
    @Published private(set) var paired: Bool?
    @Published private(set) var advertisingPageThreshold: Int?
    
    @Published private(set) var ppgCapturePeriod: Int?
    @Published private(set) var ppgCaptureDuration: Int?
    @Published private(set) var tag: String?

    // Main and Streaming Characteristic
    @Published private(set) var worn: Bool?
    @Published private(set) var charging: Bool?
    @Published private(set) var on_charger: Bool?
    @Published private(set) var charge_error: Bool?
    @Published private(set) var buttonTaps: Int?
    @Published private(set) var ppgMetrics: ppgMetricsType?

    // Main charcteristic
    let readEpochComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let writeEpochComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let startManualComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let stopManualComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let ledComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let getRawLoggingStatusComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getWornOverrideStatusComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    
    let writeSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readSerialNumberComplete = PassthroughSubject<(DeviceCommandCompletionStatus, String), Never>()
    let deleteSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let writeAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readAdvIntervalComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let deleteAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let clearChargeCyclesComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readChargeCyclesComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Float), Never>()

    let setAdvertiseAsHRMComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getAdvertiseAsHRMComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()

    let setButtonCommandComplete = PassthroughSubject<(DeviceCommandCompletionStatus, buttonTapType, buttonCommandType), Never>()
    let getButtonCommandComplete = PassthroughSubject<(DeviceCommandCompletionStatus, buttonTapType, buttonCommandType), Never>()
    
    let setAskForButtonResponseComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getAskForButtonResponseComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    
    let setHRZoneColorComplete = PassthroughSubject<(DeviceCommandCompletionStatus, hrZoneRangeType), Never>()
    let getHRZoneColorComplete = PassthroughSubject<(DeviceCommandCompletionStatus, hrZoneRangeType, Bool, Bool, Bool, Int, Int), Never>()
    let setHRZoneRangeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let getHRZoneRangeComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool, Int, Int), Never>()
    let getPPGAlgorithmComplete = PassthroughSubject<(DeviceCommandCompletionStatus, ppgAlgorithmConfiguration, eventType), Never>()
    
    let endSleepComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let disableWornDetectComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let enableWornDetectComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let wornCheckResultComplete = PassthroughSubject<(DeviceCommandCompletionStatus, String, Int), Never>()
    
    let setSessionParamComplete = PassthroughSubject<(DeviceCommandCompletionStatus, sessionParameterType), Never>()
    let getSessionParamComplete = PassthroughSubject<(DeviceCommandCompletionStatus, sessionParameterType, Int), Never>()
    let resetSessionParamsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let acceptSessionParamsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let readCanLogDiagnosticsComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let updateCanLogDiagnosticsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let enterShipModeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let resetComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let airplaneModeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let getPacketCountComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let getAllPacketsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let getAllPacketsAcknowledgeComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()

    let manufacturingTestComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let rawLoggingComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let getPairedComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let setPairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let setUnpairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let getPageThresholdComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let setPageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let deletePageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    // Main and Data Characteristic
    let dataPackets = PassthroughSubject<(Int, String), Never>()
    let dataComplete = PassthroughSubject<(Int, Int, Int, Int, Bool), Never>()
    let dataFailure = PassthroughSubject<Void, Never>()
    
    // Main abd Streaming Characteristic
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
        switch characteristic.uuid {
		#if UNIVERSAL || ALTER
        case characteristics.alterMainCharacteristic.UUID: return true
        case characteristics.alterDataCharacteristic.UUID: return true
        case characteristics.alterStrmCharacteristic.UUID: return true
        #endif

		#if UNIVERSAL || KAIROS
        case characteristics.kairosMainCharacteristic.UUID: return true
        case characteristics.kairosDataCharacteristic.UUID: return true
        case characteristics.kairosStrmCharacteristic.UUID: return true
        #endif

        default: return false
        }
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
        Publishers.CombineLatest3(
            mainCharacteristic.$configured,
            dataCharacteristic.$configured,
            strmCharacteristic.$configured)
            .sink { [weak self] mainConfigured, dataConfigured, strmConfigured in
                self?.pConfigured = mainConfigured && dataConfigured && strmConfigured
            }
            .store(in: &pSubscriptions)

        // Main characteristic
        mainCharacteristic.$worn.sink { [weak self] in self?.worn = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$epoch.sink { [weak self] in self?.epoch = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$canLogDiagnostics.sink { [weak self] in self?.canLogDiagnostics = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$wornCheckResult.sink { [weak self] in self?.wornCheckResult = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$charging.sink { self.charging = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$on_charger.sink { self.on_charger = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$charge_error.sink { self.charge_error = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$buttonTaps.sink { self.buttonTaps = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$hrZoneLEDBelow.sink { [weak self] in self?.hrZoneLEDBelow = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$hrZoneLEDWithin.sink { [weak self] in self?.hrZoneLEDWithin = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$hrZoneLEDAbove.sink { [weak self] in self?.hrZoneLEDAbove = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$hrZoneRange.sink { [weak self] in self?.hrZoneRange = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$ppgCapturePeriod.sink { [weak self] in self?.ppgCapturePeriod = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$ppgCaptureDuration.sink { [weak self] in self?.ppgCaptureDuration = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$tag.sink { [weak self] in self?.tag = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$paired.sink { [weak self] in self?.paired = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$buttonResponseEnabled.sink { [weak self] in self?.buttonResponseEnabled = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$singleButtonPressAction.sink { [weak self] in self?.singleButtonPressAction = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$doubleButtonPressAction.sink { [weak self] in self?.doubleButtonPressAction = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$tripleButtonPressAction.sink { [weak self] in self?.tripleButtonPressAction = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$longButtonPressAction.sink { [weak self] in self?.longButtonPressAction = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$rawLogging.sink { [weak self] in self?.rawLogging = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$wornOverridden.sink { [weak self] in self?.wornOverridden = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$advertisingInterval.sink { [weak self] in self?.advertisingInterval = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$chargeCycles.sink { [weak self] in self?.chargeCycles = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$advertiseAsHRM.sink { [weak self] in self?.advertiseAsHRM = $0 }.store(in: &pSubscriptions)
        mainCharacteristic.$ppgMetrics.sink { self.ppgMetrics = $0 }.store(in: &pSubscriptions)
        
        mainCharacteristic.writeEpochComplete.sink { self.writeEpochComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.readEpochComplete
            .sink { status, value in
                self.readEpochComplete.send((status, value))
            }
            .store(in: &pSubscriptions)
                
        mainCharacteristic.startManualComplete.sink { self.startManualComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.stopManualComplete.sink { self.stopManualComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.ledComplete.sink { self.ledComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.getRawLoggingStatusComplete
            .sink { status, enabled in
                self.getRawLoggingStatusComplete.send((status, enabled))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getWornOverrideStatusComplete
            .sink { status, overridden in
                self.getWornOverrideStatusComplete.send((status, overridden))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.writeSerialNumberComplete.sink { self.writeSerialNumberComplete.send($0) }.store(in: &pSubscriptions)

        mainCharacteristic.readSerialNumberComplete
            .sink { status, partID in
                self.readSerialNumberComplete.send((status, partID))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.deleteSerialNumberComplete.sink { self.deleteSerialNumberComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.writeAdvIntervalComplete.sink { self.writeAdvIntervalComplete.send($0) }.store(in: &pSubscriptions)

        mainCharacteristic.readAdvIntervalComplete
            .sink { status, seconds in
                self.readAdvIntervalComplete.send((status, seconds))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.deleteAdvIntervalComplete.sink { self.deleteAdvIntervalComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.clearChargeCyclesComplete.sink { self.clearChargeCyclesComplete.send($0) }.store(in: &pSubscriptions)

        mainCharacteristic.readChargeCyclesComplete
            .sink { status, cycles in
                self.readChargeCyclesComplete.send((status, cycles))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.setAdvertiseAsHRMComplete
            .sink { status, asHRM in
                self.setAdvertiseAsHRMComplete.send((status, asHRM))
            }
            .store(in: &pSubscriptions)
    
        mainCharacteristic.getAdvertiseAsHRMComplete
            .sink { status, asHRM in
                self.getAdvertiseAsHRMComplete.send((status, asHRM))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.setButtonCommandComplete
            .sink { status, tap, command in
                self.setButtonCommandComplete.send((status, tap, command))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getButtonCommandComplete
            .sink { status, tap, command in
                self.getButtonCommandComplete.send((status, tap, command))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.setAskForButtonResponseComplete
            .sink { status, enable in
                self.setAskForButtonResponseComplete.send((status, enable))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getAskForButtonResponseComplete
            .sink { status, enable in
                self.getAskForButtonResponseComplete.send((status, enable))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.setHRZoneColorComplete
            .sink { status, type in
                self.setHRZoneColorComplete.send((status, type))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getHRZoneColorComplete
            .sink { status, type, red, green, blue, on_ms, off_ms in
                self.getHRZoneColorComplete.send((status, type, red, green, blue, on_ms, off_ms))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.setHRZoneRangeComplete
            .sink { self.setHRZoneRangeComplete.send($0) }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getHRZoneRangeComplete
            .sink { status, enabled, high_value, low_value in
                self.getHRZoneRangeComplete.send((status, enabled, high_value, low_value))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getPPGAlgorithmComplete
            .sink { status, algorithm, state in
                self.getPPGAlgorithmComplete.send((status, algorithm, state))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.endSleepComplete.sink { self.endSleepComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.endSleepStatus.sink { self.endSleepStatus.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.disableWornDetectComplete.sink { self.disableWornDetectComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.enableWornDetectComplete.sink { self.enableWornDetectComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.wornCheckComplete
            .sink { status, code, value in
                self.wornCheckResultComplete.send((status, code, value))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.setSessionParamComplete
            .sink { status, parameter in
                self.setSessionParamComplete.send((status, parameter))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getSessionParamComplete
            .sink { status, parameter, value in
                self.getSessionParamComplete.send((status, parameter, value))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.acceptSessionParamsComplete.sink { self.acceptSessionParamsComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.resetSessionParamsComplete.sink { self.resetSessionParamsComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.readCanLogDiagnosticsComplete
            .sink { status, allow in
                self.readCanLogDiagnosticsComplete.send((status, allow))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.updateCanLogDiagnosticsComplete.sink { self.updateCanLogDiagnosticsComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.getPacketCountComplete
            .sink { status, count in
                self.getPacketCountComplete.send((status, count))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.getAllPacketsComplete.sink { self.getAllPacketsComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.getAllPacketsAcknowledgeComplete
            .sink { status, ack in
                self.getAllPacketsAcknowledgeComplete.send((status, ack))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.setPairedComplete.sink { self.setPairedComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.setUnpairedComplete.sink { self.setUnpairedComplete.send($0) }.store(in: &pSubscriptions)

        mainCharacteristic.getPairedComplete
            .sink { status, paired in
                self.getPairedComplete.send((status, paired))
            }
            .store(in: &pSubscriptions)
        
        mainCharacteristic.setPageThresholdComplete.sink { self.setPageThresholdComplete.send($0) }.store(in: &pSubscriptions)

        mainCharacteristic.getPageThresholdComplete
            .sink { status, threshold in
                self.getPageThresholdComplete.send((status, threshold))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.deletePageThresholdComplete.sink { self.deletePageThresholdComplete.send($0) }.store(in: &pSubscriptions)

        mainCharacteristic.enterShipModeComplete.sink { self.enterShipModeComplete.send($0)}.store(in: &pSubscriptions)
        mainCharacteristic.resetComplete.sink { self.resetComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.airplaneModeComplete.sink { self.airplaneModeComplete.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.manufacturingTestComplete.sink { self.manufacturingTestComplete.send($0) }.store(in: &pSubscriptions)
        mainCharacteristic.rawLoggingComplete.sink { self.rawLoggingComplete.send($0) }.store(in: &pSubscriptions)
        
        // MARK: Notifications
        mainCharacteristic.manufacturingTestResult
            .sink { valid, result in
                self.manufacturingTestResult.send((valid, result))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.ppgFailed.sink { self.ppgFailed.send($0) }.store(in: &pSubscriptions)
        
        mainCharacteristic.dataPackets
            .sink { sequence_number, packets in
                self.dataPackets.send((sequence_number, packets))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.dataComplete
            .sink { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in
                self.dataComplete.send((bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate))
            }
            .store(in: &pSubscriptions)

        mainCharacteristic.dataFailure
            .sink { self.dataFailure.send() }
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
        mainCharacteristic = customMainCharacteristic()
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
        
        switch characteristic.uuid {
		#if UNIVERSAL || ALTER
        case characteristics.alterMainCharacteristic.UUID:
            mainCharacteristic.didDiscover(characteristic, commandQ: commandQ)
			#if UNIVERSAL
            mainCharacteristic.type = .alter
            #endif
            mainCharacteristic.discoverDescriptors()

        case characteristics.alterDataCharacteristic.UUID:
            dataCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            dataCharacteristic.discoverDescriptors()

        case characteristics.alterStrmCharacteristic.UUID:
            strmCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            #if UNIVERSAL
            strmCharacteristic.type = .alter
            #endif
            strmCharacteristic.discoverDescriptors()
        #endif

        #if UNIVERSAL || KAIROS
        case characteristics.kairosMainCharacteristic.UUID:
            mainCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            #if UNIVERSAL
            mainCharacteristic.type = .kairos
            #endif
            mainCharacteristic.discoverDescriptors()
            break
            
        case characteristics.kairosDataCharacteristic.UUID:
            dataCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            dataCharacteristic.discoverDescriptors()

        case characteristics.kairosStrmCharacteristic.UUID:
            strmCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            #if UNIVERSAL
            strmCharacteristic.type = .kairos
            #endif
            strmCharacteristic.discoverDescriptors()
		#endif

        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
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
		#if UNIVERSAL || ALTER
        case characteristics.alterMainCharacteristic.UUID: mainCharacteristic.didDiscoverDescriptor()
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didDiscoverDescriptor()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didDiscoverDescriptor()
        #endif
            
        #if UNIVERAL || KAIROS
        case characteristics.kairosMainCharacteristic.UUID: mainCharacteristic.didDiscoverDescriptor()
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didDiscoverDescriptor()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didDiscoverDescriptor()
		#endif
            
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
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
		#if UNIVERSAL || ALTER
        case characteristics.alterMainCharacteristic.UUID: mainCharacteristic.didUpdateNotificationState()
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didUpdateNotificationState()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didUpdateNotificationState()
        #endif
            
        #if UNIVERAL || KAIROS
        case characteristics.kairosMainCharacteristic.UUID: mainCharacteristic.didUpdateNotificationState()
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didUpdateNotificationState()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didUpdateNotificationState()
        #endif
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
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
		#if UNIVERSAL || ALTER
        case characteristics.alterMainCharacteristic.UUID: mainCharacteristic.didUpdateValue()
        case characteristics.alterDataCharacteristic.UUID: dataCharacteristic.didUpdateValue()
        case characteristics.alterStrmCharacteristic.UUID: strmCharacteristic.didUpdateValue()
        #endif
            
        #if UNIVERAL || KAIROS
        case characteristics.kairosMainCharacteristic.UUID: mainCharacteristic.didUpdateValue()
        case characteristics.kairosDataCharacteristic.UUID: dataCharacteristic.didUpdateValue()
        case characteristics.kairosStrmCharacteristic.UUID: strmCharacteristic.didUpdateValue()
		#endif
            
        default: globals.log.e ("Unhandled: \(characteristic.uuid)")
        }
    }

    // MARK: Commands
    func writeEpoch(_ newEpoch: Int) { mainCharacteristic.writeEpoch(newEpoch) }
    func readEpoch() { mainCharacteristic.readEpoch() }
    
    func endSleep() { mainCharacteristic.endSleep() }

    func getAllPackets(pages: Int, delay: Int, newStyle: Bool) { mainCharacteristic.getAllPackets(pages: pages, delay: delay, newStyle: newStyle) }
    func getAllPacketsAcknowledge(_ ack: Bool) { mainCharacteristic.getAllPacketsAcknowledge(ack) }
    func getPacketCount() { mainCharacteristic.getPacketCount() }
    
    func disableWornDetect() { mainCharacteristic.disableWornDetect() }
    func enableWornDetect() { mainCharacteristic.enableWornDetect() }
    
    func startManual(_ algorithms: ppgAlgorithmConfiguration) { mainCharacteristic.startManual(algorithms) }
    func stopManual() { mainCharacteristic.stopManual() }
    
    func userLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
        mainCharacteristic.userLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
    }
    
    func enterShipMode() { mainCharacteristic.enterShipMode() }
    func reset() { mainCharacteristic.reset() }
    func airplaneMode() { mainCharacteristic.airplaneMode() }

    func writeSerialNumber(_ partID: String) {mainCharacteristic.writeSerialNumber(partID) }
    func readSerialNumber() { mainCharacteristic.readSerialNumber() }
    func deleteSerialNumber() { mainCharacteristic.deleteSerialNumber() }

    func writeAdvInterval(_ seconds: Int) { mainCharacteristic.writeAdvInterval(seconds) }
    func readAdvInterval() { mainCharacteristic.readAdvInterval() }
    func deleteAdvInterval() { mainCharacteristic.deleteAdvInterval() }

    func clearChargeCycles() { mainCharacteristic.clearChargeCycles() }
    func readChargeCycles() { mainCharacteristic.readChargeCycles() }

    func readCanLogDiagnostics() { mainCharacteristic.readCanLogDiagnostics() }
    func updateCanLogDiagnostics(_ allow: Bool) { mainCharacteristic.updateCanLogDiagnostics(allow) }
        
    #if UNIVERSAL || ALTER
    func alterManufacturingTest(_ test: alterManufacturingTestType) { mainCharacteristic.alterManufacturingTest(test) }
    #endif

    #if UNIVERSAL || KAIROS
    func kairosManufacturingTest(_ test: kairosManufacturingTestType) { mainCharacteristic.kairosManufacturingTest(test) }
    #endif

    func setAskForButtonResponse(_ enable: Bool) { mainCharacteristic.setAskForButtonResponse(enable) }
    func getAskForButtonResponse() { mainCharacteristic.getAskForButtonResponse() }
    
    func setHRZoneColor(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
        mainCharacteristic.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
    }
    func getHRZoneColor(_ type: hrZoneRangeType) { mainCharacteristic.getHRZoneColor(type) }
    
    func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
        mainCharacteristic.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
    }
    func getHRZoneRange() { mainCharacteristic.getHRZoneRange() }
    
    func getPPGAlgorithm() { mainCharacteristic.getPPGAlgorithm() }

    func setAdvertiseAsHRM(_ asHRM: Bool) { mainCharacteristic.setAdvertiseAsHRM(asHRM) }
    func getAdvertiseAsHRM() { mainCharacteristic.getAdvertiseAsHRM() }

    func setButtonCommand(_ tap: buttonTapType, command: buttonCommandType) { mainCharacteristic.setButtonCommand(tap, command: command) }
    func getButtonCommand(_ tap: buttonTapType) { mainCharacteristic.getButtonCommand(tap) }
    
    func setPaired() { mainCharacteristic.setPaired() }
    func setUnpaired() { mainCharacteristic.setUnpaired() }
    func getPaired() { mainCharacteristic.getPaired() }
    
    func setPageThreshold(_ threshold: Int) { mainCharacteristic.setPageThreshold(threshold) }
    func getPageThreshold() { mainCharacteristic.getPageThreshold() }
    func deletePageThreshold() { mainCharacteristic.deletePageThreshold() }

    func rawLogging(_ enable: Bool) { mainCharacteristic.rawLogging(enable) }
    func wornCheck() { mainCharacteristic.wornCheck() }
    func getRawLoggingStatus() { mainCharacteristic.getRawLoggingStatus() }
    func getWornOverrideStatus() { mainCharacteristic.getWornOverrideStatus() }
    
    func setSessionParam(_ parameter: sessionParameterType, value: Int) { mainCharacteristic.setSessionParam(parameter, value: value) }
    func getSessionParam(_ parameter: sessionParameterType) { mainCharacteristic.getSessionParam(parameter) }
    func resetSessionParams() { mainCharacteristic.resetSessionParams() }
    func acceptSessionParams() { mainCharacteristic.acceptSessionParams() }

}
