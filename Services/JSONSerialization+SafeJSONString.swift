// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import Foundation

extension JSONSerialization {
    static func safeJSONString(_ value: Any) -> String {
        if value is NSNull {
            return "null"
        }

        if let string = value as? String {
            return safeJSONString([string]).dropFirst().dropLast().description
        }

        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }

        if let number = value as? NSNumber {
            return number.stringValue
        }

        let object = isValidJSONObject(value) ? value : NSNull()
        guard let data = try? data(withJSONObject: object),
              let string = String(data: data, encoding: .utf8) else {
            return "null"
        }
        return string
    }
}
