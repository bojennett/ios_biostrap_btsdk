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
	#if UNIVERSAL || LIVOTAL
	case ppg							= 0x82
	#endif
	case activity						= 0x83
	case temp							= 0x84
	case worn							= 0x85
	case sleep							= 0x86
	case diagnostic						= 0x87
	case ppg_failed						= 0x88
	case battery						= 0x89
	case charger						= 0x8a
	#if UNIVERSAL || ETHOS || ALTER
	case ppg_metrics					= 0x8b
	case continuous_hr					= 0x8c
	#endif
	
	case rawAccelXADC					= 0xc0
	case rawAccelYADC					= 0xc1
	case rawAccelZADC					= 0xc2
	case rawAccelCompressedXADC			= 0xc3
	case rawAccelCompressedYADC			= 0xc4
	case rawAccelCompressedZADC			= 0xc5
	
	#if UNIVERSAL || ETHOS || ALTER
	case rawGyroXADC					= 0xc8
	case rawGyroYADC					= 0xc9
	case rawGyroZADC					= 0xca
	case rawGyroCompressedXADC			= 0xcb
	case rawGyroCompressedYADC			= 0xcc
	case rawGyroCompressedZADC			= 0xcd
	#endif

	case ppgCalibrationStart			= 0xe0
	case ppgCalibrationDone				= 0xd0

	case motionLevel					= 0xd1

	case rawPPGCompressedGreen			= 0xd3
	case rawPPGCompressedRed			= 0xd4
	case rawPPGCompressedIR				= 0xd5

	#if UNIVERSAL || ETHOS
	case rawPPGCompressedWhiteIRRPD     = 0xd7
	case rawPPGCompressedWhiteWhitePD   = 0xd8
	#endif


	case rawAccelFifoCount				= 0xe1
	case rawPPGProximity				= 0xe2
	case rawPPGGreen					= 0xe3
	case rawPPGRed						= 0xe4
	case rawPPGIR						= 0xe5
	case rawPPGFifoCount				= 0xe6
	
	#if UNIVERSAL || ETHOS
	case rawPPGWhiteIRRPD				= 0xe8
	case rawPPGWhiteWhitePD				= 0xe9
	#endif
		
	case milestone						= 0xf0
	case settings						= 0xf1
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"								: self	= .unknown
		case "Steps"								: self	= .steps
		#if UNIVERSAL || LIVOTAL
		case "PPG Results"							: self	= .ppg
		#endif
		case "PPG Failed"							: self	= .ppg_failed
		case "Activity"								: self	= .activity
		case "Temperature"							: self	= .temp
		case "Worn"									: self	= .worn
		case "Battery"								: self	= .battery
		case "Charger"								: self	= .charger
		case "Sleep"								: self	= .sleep
		case "Diagnostic"							: self	= .diagnostic
		#if UNIVERSAL || ETHOS || ALTER
		case "PPG Metrics"							: self	= .ppg_metrics
		case "Continuous Heart Rate"				: self	= .continuous_hr
		#endif
		case "Raw Accel FIFO Count"					: self	= .rawAccelFifoCount
		case "Raw PPG Proximity"					: self	= .rawPPGProximity
			
		case "Raw Accel X ADC"						: self	= .rawAccelXADC
		case "Raw Accel Y ADC"						: self	= .rawAccelYADC
		case "Raw Accel Z ADC"						: self	= .rawAccelZADC
		case "Raw Accel Compressed X ADC"			: self	= .rawAccelCompressedXADC
		case "Raw Accel Compressed Y ADC"			: self	= .rawAccelCompressedYADC
		case "Raw Accel Compressed Z ADC"			: self	= .rawAccelCompressedZADC

		#if UNIVERSAL || ETHOS || ALTER
		case "Raw Gyro X ADC"						: self	= .rawGyroXADC
		case "Raw Gyro Y ADC"						: self	= .rawGyroYADC
		case "Raw Gyro Z ADC"						: self	= .rawGyroZADC
		case "Raw Gyro Compressed X ADC"			: self	= .rawGyroCompressedXADC
		case "Raw Gyro Compressed Y ADC"			: self	= .rawGyroCompressedYADC
		case "Raw Gyro Compressed Z ADC"			: self	= .rawGyroCompressedZADC
		#endif

		case "PPG Calibration Start"				: self	= .ppgCalibrationStart
		case "PPG Calibration Done"					: self	= .ppgCalibrationDone

		case "Motion Level"							: self	= .motionLevel

		case "Raw PPG Compressed Green"				: self	= .rawPPGCompressedGreen
		case "Raw PPG Compressed Red"				: self	= .rawPPGCompressedRed
		case "Raw PPG Compressed IR"				: self	= .rawPPGCompressedIR

		#if UNIVERSAL || ETHOS
		case "Raw PPG Compressed White IRR PD"		: self	= .rawPPGCompressedWhiteIRRPD
		case "Raw PPG Compressed White White PD"	: self	= .rawPPGCompressedWhiteWhitePD
		#endif

		case "Raw PPG Green Sample"					: self	= .rawPPGGreen
		case "Raw PPG Red Sample"					: self	= .rawPPGRed
		case "Raw PPG IR Sample"					: self	= .rawPPGIR
		case "Raw PPG FIFO Count"					: self	= .rawPPGFifoCount
			
		#if UNIVERSAL || ETHOS
		case "Raw PPG White Sample IRR PD"			: self	= .rawPPGWhiteIRRPD
		case "Raw PPG White Sample White PD"		: self	= .rawPPGWhiteWhitePD
		#endif
	
		case "Milestone"							: self	= .milestone
		case "Settings"								: self	= .settings
		default: self	= .unknown
		}
	}
		
	public var title: String {
		switch (self) {
		case .unknown								: return "Unknown"
		case .steps									: return "Steps"
		#if UNIVERSAL || LIVOTAL
		case .ppg									: return "PPG Results"
		#endif
		case .ppg_failed							: return "PPG Failed"
		case .activity								: return "Activity"
		case .temp									: return "Temperature"
		case .worn									: return "Worn"
		case .battery								: return "Battery"
		case .charger								: return "Charger"
		case .sleep									: return "Sleep"
		case .diagnostic							: return "Diagnostic"
		#if UNIVERSAL || ETHOS || ALTER
		case .ppg_metrics							: return "PPG Metrics"
		case .continuous_hr							: return "Continuous Heart Rate"
		#endif
		case .rawAccelFifoCount						: return "Raw Accel FIFO Count"
		case .rawPPGProximity						: return "Raw PPG Proximity"
			
		case .rawAccelXADC							: return "Raw Accel X ADC"
		case .rawAccelYADC							: return "Raw Accel Y ADC"
		case .rawAccelZADC							: return "Raw Accel Z ADC"
		case .rawAccelCompressedXADC				: return "Raw Accel Compressed X ADC"
		case .rawAccelCompressedYADC				: return "Raw Accel Compressed Y ADC"
		case .rawAccelCompressedZADC				: return "Raw Accel Compressed Z ADC"

		#if UNIVERSAL || ETHOS || ALTER
		case .rawGyroXADC							: return "Raw Gyro X ADC"
		case .rawGyroYADC							: return "Raw Gyro Y ADC"
		case .rawGyroZADC							: return "Raw Gyro Z ADC"
		case .rawGyroCompressedXADC					: return "Raw Gyro Compressed X ADC"
		case .rawGyroCompressedYADC					: return "Raw Gyro Compressed Y ADC"
		case .rawGyroCompressedZADC					: return "Raw Gyro Compressed Z ADC"
		#endif

		case .ppgCalibrationStart					: return "PPG Calibration Start"
		case .ppgCalibrationDone					: return "PPG Calibration Done"

		case .motionLevel							: return "Motion Level"

		case .rawPPGCompressedGreen					: return "Raw PPG Compressed Green"
		case .rawPPGCompressedRed					: return "Raw PPG Compressed Red"
		case .rawPPGCompressedIR					: return "Raw PPG Compressed IR"
			
		#if UNIVERSAL || ETHOS
		case .rawPPGCompressedWhiteIRRPD			: return "Raw PPG Compressed White IRR PD"
		case .rawPPGCompressedWhiteWhitePD			: return "Raw PPG Compressed White White PD"
		#endif

		case .rawPPGGreen							: return "Raw PPG Green Sample"
		case .rawPPGRed								: return "Raw PPG Red Sample"
		case .rawPPGIR								: return "Raw PPG IR Sample"
		case .rawPPGFifoCount						: return "Raw PPG FIFO Count"
			
		#if UNIVERSAL || ETHOS
		case .rawPPGWhiteIRRPD						: return "Raw PPG White Sample IRR PD"
		case .rawPPGWhiteWhitePD					: return "Raw PPG White Sample White PD"
		#endif

		case .milestone								: return "Milestone"
		case .settings								: return "Settings"
		}
	}
	
	var length: Int {
		switch (self) {
		case .unknown								: return 300
		case .steps									: return 7
		#if UNIVERSAL || LIVOTAL
		case .ppg									: return 17
		#endif
		case .ppg_failed							: return 6
		case .activity								: return 10
		case .temp									: return 9
		case .worn									: return 6
		case .battery								: return 8
		case .charger								: return 7
		case .sleep									: return 9
		case .diagnostic							: return 0 	// Done by calculation
		#if UNIVERSAL || ETHOS || ALTER
		case .ppg_metrics							: return 19
		case .continuous_hr							: return 19
		#endif
		case .rawAccelFifoCount						: return 10
		case .rawPPGProximity						: return 5

		case .rawAccelXADC							: return 3
		case .rawAccelYADC							: return 3
		case .rawAccelZADC							: return 3
		case .rawAccelCompressedXADC				: return 0	// Done by calculation
		case .rawAccelCompressedYADC				: return 0	// Done by calculation
		case .rawAccelCompressedZADC				: return 0	// Done by calculation

		#if UNIVERSAL || ETHOS || ALTER
		case .rawGyroXADC							: return 3
		case .rawGyroYADC							: return 3
		case .rawGyroZADC							: return 3
		case .rawGyroCompressedXADC					: return 0	// Done by calculation
		case .rawGyroCompressedYADC					: return 0	// Done by calculation
		case .rawGyroCompressedZADC					: return 0	// Done by calculation
		#endif

		case .ppgCalibrationStart					: return 9
		case .ppgCalibrationDone					: return 14

		case .motionLevel							: return 10

		case .rawPPGCompressedGreen					: return 0	// Done by calculation
		case .rawPPGCompressedRed					: return 0	// Done by calculation
		case .rawPPGCompressedIR					: return 0	// Done by calculation
			
		#if UNIVERSAL || ETHOS
		case .rawPPGCompressedWhiteIRRPD			: return 0	// Done by calculation
		case .rawPPGCompressedWhiteWhitePD			: return 0	// Done by calculation
		#endif

		case .rawPPGGreen							: return 5
		case .rawPPGRed								: return 5
		case .rawPPGIR								: return 5
		case .rawPPGFifoCount						: return 10
			
		#if UNIVERSAL || ETHOS
		case .rawPPGWhiteIRRPD						: return 5
		case .rawPPGWhiteWhitePD					: return 5
		#endif
						
		case .milestone								: return 7
		case .settings								: return 6
		}
	}
}

