/*
Copyright 2018 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation

import GenericJSON



enum Converters {
	
	struct ConversionFailed : Error {}
	
	static func convertJSONToString(_ json: JSON) throws -> String {
		guard let ret = json.stringValue else {
			throw ConversionFailed()
		}
		return ret
	}
	
	static func convertJSONToURL(_ json: JSON) throws -> URL {
		guard let str = json.stringValue, let ret = URL(string: str) else {
			throw ConversionFailed()
		}
		return ret
	}
	
	static func convertJSONToInt(_ json: JSON) throws -> Int {
		guard let num = json.doubleValue else {
			throw ConversionFailed()
		}
		/* We should check whether the double has a fractional part. */
		return Int(num)
	}
	
	static func convertJSONToDate(_ json: JSON) throws -> Date {
		guard let str = json.stringValue, let ret = ISO8601DateFormatter().date(from: str) else {
			throw ConversionFailed()
		}
		return ret
	}
	
}
