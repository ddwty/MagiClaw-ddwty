//
//  Extensions.swift
//  MagiClaw
//
//  Created by Tianyu on 9/11/24.
//

import Foundation

extension Date
{
    func toString(dateFormat format: String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

}
