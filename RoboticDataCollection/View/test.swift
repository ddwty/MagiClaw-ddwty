//
//  test.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/8/14.
//

import SwiftUI

struct test: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    var body: some View {
        if verticalSizeClass == .regular {
            VStack {
                MyARView()
            }
        } else {
            HStack {
                MyARView()
            }
        }
            
    }
}

#Preview {
    test()
}
