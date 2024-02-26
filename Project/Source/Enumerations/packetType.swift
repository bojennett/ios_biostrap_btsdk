//
//  packetType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/21/22.
//

import Foundation

@objc public enum packetType: UInt8, Codable {
	case unknown						= 0x00
	case steps							= 0x81
	case activity						= 0x83
	case temp							= 0x84
	case worn							= 0x85
	case sleep							= 0x86
	case diagnostic						= 0x87
	case ppg_failed						= 0x88
	case battery						= 0x89
	case charger						= 0x8a
	case ppg_metrics					= 0x8b
	case continuous_hr					= 0x8c
	case steps_active					= 0x8d
	case bbi							= 0x8e
	case cadence						= 0x8f
	case event							= 0x90
	case bookend						= 0x91
	case algorithmData					= 0x92
	case rawAccelXADC					= 0xc0
	case rawAccelYADC					= 0xc1
	case rawAccelZADC					= 0xc2
	case rawAccelCompressedXADC			= 0xc3
	case rawAccelCompressedYADC			= 0xc4
	case rawAccelCompressedZADC			= 0xc5
	case rawGyroXADC					= 0xc8
	case rawGyroYADC					= 0xc9
	case rawGyroZADC					= 0xca
	case rawGyroCompressedXADC			= 0xcb
	case rawGyroCompressedYADC			= 0xcc
	case rawGyroCompressedZADC			= 0xcd

	case ppgCalibrationStart			= 0xe0
	case ppgCalibrationDone				= 0xd0

	case motionLevel					= 0xd1

	case rawPPGCompressedGreen			= 0xd3
	case rawPPGCompressedRed			= 0xd4
	case rawPPGCompressedIR				= 0xd5

	case rawAccelFifoCount				= 0xe1
	case rawPPGProximity				= 0xe2
	case rawPPGGreen					= 0xe3
	case rawPPGRed						= 0xe4
	case rawPPGIR						= 0xe5
	case rawPPGFifoCount				= 0xe6
		
	case milestone						= 0xf0
	case settings						= 0xf1
	case caughtUp						= 0xfe
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"								: self	= .unknown
		case "Steps"								: self	= .steps
		case "PPG Failed"							: self	= .ppg_failed
		case "Activity"								: self	= .activity
		case "Temperature"							: self	= .temp
		case "Worn"									: self	= .worn
		case "Battery"								: self	= .battery
		case "Charger"								: self	= .charger
		case "Sleep"								: self	= .sleep
		case "Diagnostic"							: self	= .diagnostic
		case "PPG Metrics"							: self	= .ppg_metrics
		
		case "Continuous Heart Rate"				: self	= .continuous_hr
			
		case "Steps with Active Seconds"			: self	= .steps_active
			
		case "Beat-to-Beat Interval"				: self = .bbi
		case "Cadence"								: self = .cadence
		case "Event"								: self = .event
		case "Bookend"								: self = .bookend
			
		case "Algorithm Data"						: self = .algorithmData

		case "Raw Accel FIFO Count"					: self	= .rawAccelFifoCount
		case "Raw PPG Proximity"					: self	= .rawPPGProximity
			
		case "Raw Accel X ADC"						: self	= .rawAccelXADC
		case "Raw Accel Y ADC"						: self	= .rawAccelYADC
		case "Raw Accel Z ADC"						: self	= .rawAccelZADC
		case "Raw Accel Compressed X ADC"			: self	= .rawAccelCompressedXADC
		case "Raw Accel Compressed Y ADC"			: self	= .rawAccelCompressedYADC
		case "Raw Accel Compressed Z ADC"			: self	= .rawAccelCompressedZADC

		case "Raw Gyro X ADC"						: self	= .rawGyroXADC
		case "Raw Gyro Y ADC"						: self	= .rawGyroYADC
		case "Raw Gyro Z ADC"						: self	= .rawGyroZADC
		case "Raw Gyro Compressed X ADC"			: self	= .rawGyroCompressedXADC
		case "Raw Gyro Compressed Y ADC"			: self	= .rawGyroCompressedYADC
		case "Raw Gyro Compressed Z ADC"			: self	= .rawGyroCompressedZADC

		case "PPG Calibration Start"				: self	= .ppgCalibrationStart
		case "PPG Calibration Done"					: self	= .ppgCalibrationDone

		case "Motion Level"							: self	= .motionLevel

		case "Raw PPG Compressed Green"				: self	= .rawPPGCompressedGreen
		case "Raw PPG Compressed Red"				: self	= .rawPPGCompressedRed
		case "Raw PPG Compressed IR"				: self	= .rawPPGCompressedIR

		case "Raw PPG Green Sample"					: self	= .rawPPGGreen
		case "Raw PPG Red Sample"					: self	= .rawPPGRed
		case "Raw PPG IR Sample"					: self	= .rawPPGIR
		case "Raw PPG FIFO Count"					: self	= .rawPPGFifoCount
			
		case "Milestone"							: self	= .milestone
		case "Settings"								: self	= .settings
		case "Caught Up"							: self	= .caughtUp
		default										: self	= .unknown
		}
	}
		
	public var title: String {
		switch (self) {
		case .unknown								: return "Unknown"
		case .steps									: return "Steps"
		case .ppg_failed							: return "PPG Failed"
		case .activity								: return "Activity"
		case .temp									: return "Temperature"
		case .worn									: return "Worn"
		case .battery								: return "Battery"
		case .charger								: return "Charger"
		case .sleep									: return "Sleep"
		case .diagnostic							: return "Diagnostic"
		case .ppg_metrics							: return "PPG Metrics"
			
		case .continuous_hr							: return "Continuous Heart Rate"
			
		case .steps_active							: return "Steps with Active Seconds"

		case .bbi									: return "Beat-to-Beat Interval"
		case .cadence								: return "Cadence"
		case .event									: return "Event"
		case .bookend								: return "Bookend"
			
		case .algorithmData							: return "Algorithm Data"

		case .rawAccelFifoCount						: return "Raw Accel FIFO Count"
		case .rawPPGProximity						: return "Raw PPG Proximity"
			
		case .rawAccelXADC							: return "Raw Accel X ADC"
		case .rawAccelYADC							: return "Raw Accel Y ADC"
		case .rawAccelZADC							: return "Raw Accel Z ADC"
		case .rawAccelCompressedXADC				: return "Raw Accel Compressed X ADC"
		case .rawAccelCompressedYADC				: return "Raw Accel Compressed Y ADC"
		case .rawAccelCompressedZADC				: return "Raw Accel Compressed Z ADC"

		case .rawGyroXADC							: return "Raw Gyro X ADC"
		case .rawGyroYADC							: return "Raw Gyro Y ADC"
		case .rawGyroZADC							: return "Raw Gyro Z ADC"
		case .rawGyroCompressedXADC					: return "Raw Gyro Compressed X ADC"
		case .rawGyroCompressedYADC					: return "Raw Gyro Compressed Y ADC"
		case .rawGyroCompressedZADC					: return "Raw Gyro Compressed Z ADC"

		case .ppgCalibrationStart					: return "PPG Calibration Start"
		case .ppgCalibrationDone					: return "PPG Calibration Done"

		case .motionLevel							: return "Motion Level"

		case .rawPPGCompressedGreen					: return "Raw PPG Compressed Green"
		case .rawPPGCompressedRed					: return "Raw PPG Compressed Red"
		case .rawPPGCompressedIR					: return "Raw PPG Compressed IR"
			
		case .rawPPGGreen							: return "Raw PPG Green Sample"
		case .rawPPGRed								: return "Raw PPG Red Sample"
		case .rawPPGIR								: return "Raw PPG IR Sample"
		case .rawPPGFifoCount						: return "Raw PPG FIFO Count"
			
		case .milestone								: return "Milestone"
		case .settings								: return "Settings"
			
		case .caughtUp								: return "Caught Up"
		}
	}
	
	var length: Int {
		switch (self) {
		case .unknown								: return 300
		case .steps									: return 7
		case .ppg_failed							: return 6
		case .activity								: return 10
		case .temp									: return 9
		case .worn									: return 6
		case .battery								: return 8
		case .charger								: return 7
		case .sleep									: return 9
		case .diagnostic							: return 0 	// Done by calculation
		case .ppg_metrics							: return 19
			
		case .continuous_hr							: return 19
		case .steps_active							: return 7

		case .bbi									: return 0 // Done by calculation
		case .event									: return 10
		case .cadence								: return 0 // Done by calculation
		case .bookend								: return 15
			
		case .algorithmData							: return 0

		case .rawAccelFifoCount						: return 10
		case .rawPPGProximity						: return 5

		case .rawAccelXADC							: return 3
		case .rawAccelYADC							: return 3
		case .rawAccelZADC							: return 3
		case .rawAccelCompressedXADC				: return 0	// Done by calculation
		case .rawAccelCompressedYADC				: return 0	// Done by calculation
		case .rawAccelCompressedZADC				: return 0	// Done by calculation

		case .rawGyroXADC							: return 3
		case .rawGyroYADC							: return 3
		case .rawGyroZADC							: return 3
		case .rawGyroCompressedXADC					: return 0	// Done by calculation
		case .rawGyroCompressedYADC					: return 0	// Done by calculation
		case .rawGyroCompressedZADC					: return 0	// Done by calculation

		case .ppgCalibrationStart					: return 9
		case .ppgCalibrationDone					: return 14

		case .motionLevel							: return 10

		case .rawPPGCompressedGreen					: return 0	// Done by calculation
		case .rawPPGCompressedRed					: return 0	// Done by calculation
		case .rawPPGCompressedIR					: return 0	// Done by calculation

		case .rawPPGGreen							: return 5
		case .rawPPGRed								: return 5
		case .rawPPGIR								: return 5
		case .rawPPGFifoCount						: return 10

		case .milestone								: return 7
		case .settings								: return 6

		case .caughtUp								: return 7
		}
	}
}

