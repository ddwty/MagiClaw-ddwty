//
//  extension.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/6/24.
//

import Foundation
import SwiftUI
extension View {
    func printSizeInfo(_ label: String = "") -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .task(id: proxy.size) {
                        print(label, proxy.size)
                    }
            }
        )
    }
}
