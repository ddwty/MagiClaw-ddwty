//
//  DescriptionModel.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/8/14.
//

import Foundation

class DescriptionModel: ObservableObject {
    static let shared = DescriptionModel()
    @Published var description: String
    
    init(description: String = "No description") {
        self.description = description
    }
}
