//
//  ppgMetricsType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/5/24.
//

import Foundation
import Combine

public class ppgMetricsType: ObservableObject {
	@Published public var status = ""
	@Published public var hr: Float?
	@Published public var hrv: Float?
	@Published public var rr: Float?
	//@Published public var spo2 = Float(0.0)
	
	init(_ jsonPacket: String) {
		do {
			if let jsonData = jsonPacket.data(using: .utf8) {
				let packet  = try JSONDecoder().decode(biostrapDataPacket.self, from: jsonData)
				
				status = packet.ppg_metrics_status.title
				
				if (packet.hr_valid) { hr = packet.hr_result }
				if (packet.hrv_valid) { hrv = packet.hrv_result }
				if (packet.rr_valid) { rr = packet.rr_result }
				//if (packet.spo2_valid) { spo2	= packet.spo2_result }
			}
			else {
				globals.log.e ("Cannot get PPG Metrics data from json String")
				status = "Cannot get PPG Metrics data from json String"
			}
		}
		catch {
			globals.log.e ("\(error.localizedDescription)")
			status = error.localizedDescription
		}
	}
    
    init() {
        status = ""
        hr = 0.0
        hrv = 0.0
        rr = 0.0
    }
}

