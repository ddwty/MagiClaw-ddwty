//
//  TestView.swift
//  MagiClaw
//
//  Created by Tianyu on 9/13/24.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        Text("Create With Swift")
            .bold()
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10.0))
            .foregroundStyle(.secondary)
    }
}


#Preview {
    TestView()
}
