//
//  Date+Formatting.swift
//  foundit
//
//  Created by Divya Panthi on 17/03/2026.
//

import Foundation

extension Date {
    var formatted_MMM_d_yyyy: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
}
