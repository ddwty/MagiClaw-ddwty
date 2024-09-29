//
//  UserDoc.swift
//  MagiClaw
//
//  Created by Tianyu on 9/14/24.
//

import Foundation

struct UserDoc: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let description: String?
    let docSection: [DocSection]
}

struct DocSection {
    let numPoints: String?
    let bullist: [String]?
}


let documentationSections: [UserDoc] = [
    //    DocumentationSection(
    //        title: "Introduction",
    //        imageName: "doc.text",
    //        description: "MagiClaw is a tool designed for collecting, recording, and transmitting sensor data from iOS devices.",
    //        numPoints: [
    //            "It can record and transmit the following sensor data in real-time:",
    //            "• 6D pose data of your device;",
    //            "• Video recorded by the rear camera;",
    //            "• Depth data collected by the LiDAR sensor;",
    //            "• Data from external hardware devices (e.g., Raspberry Pi)."
    //        ],
    //        bullist: []
    //    ),
    
    //    DocumentationSection(
    //        title: "Installation and Hardware Requirements",
    //        imageName: "square.and.arrow.down",
    //
    //        points: [
    //            "Software: Requires iOS 17 or later.",
    //            "Devices: iPhone 8 or newer models. Depth data recording requires a device with a LiDAR sensor.",
    //            "Download link:"
    //        ],
    //
    //    ),
    UserDoc(
        title: "Introduction",
        imageName: "hand.wave",
        description:
            """
        MagiClaw is a tool designed for collecting, recording, and transmitting sensor data from iOS devices. It can record and transmit the following sensor data in real-time:
        """,
        docSection: [
            DocSection(numPoints: nil,
                       bullist: [
                   "6D pose data of your device;",
                   "Video recorded by the rear camera;",
                   "Depth data collected by the LiDAR sensor;",
                    "Data from external hardware devices (e.g., Raspberry Pi)."
                ])]
    ),
    
    UserDoc(
        title: "Connecting to a Raspberry Pi",
        imageName: "wifi.router.fill",
        description: nil,
        docSection: [
            DocSection(numPoints: "Ensure your device and the Raspberry Pi are on the same local network (e.g., the same Wi-Fi).", bullist: nil),
            DocSection(numPoints: "Open the “Settings” page at the bottom of the app.", bullist: nil),
            DocSection(numPoints: "Enter your Raspberry Pi’s IP address or hostname in the Hostname input box. Format: 192.168.x.x or hostname.local.",
                       bullist: ["Run `ifconfig` on the Raspberry Pi to find its local IP address (format: 192.168.x.x).",
                                 "Run `hostname` to retrieve the Raspberry Pi’s hostname."
                                ]
                      )
        ]
    ),
    
    
    UserDoc(
        title: "Recording Data",
        imageName: "tray.and.arrow.down.fill",
        description: nil,
        docSection: [
            DocSection(numPoints: "Open the “Panel” page at the bottom of the app, then select “Record.”", bullist: nil),
            DocSection(numPoints: "Check the connection status with the Raspberry Pi and ensure the status shows “Connected.”", bullist: nil),
            DocSection(numPoints: "Select the task scenario and enter a description.", bullist: nil),
            DocSection(numPoints: "Tap the “Start recording” button to begin recording. Tap the same button again to stop.", bullist: nil)
        ]
    ),
    
    UserDoc(
        title: "Viewing and Sharing Data",
        imageName: "tray.and.arrow.up.fill",
        description: nil,
        docSection: [
            DocSection(numPoints: nil, bullist:
                        ["You can view all previous recordings in the “History” page of the app.",
                         "To access saved data, go to the system’s “Files” app, navigate to “My iPhone”，and open the “MagiClaw” folder.",
                         "Here, you can select and share recordings via AirDrop.",
                         "To save files in a single .magiclaw format, enable the “Zip data files” option in the app’s settings."
                        ]
                      )
        ]
    ),
    
    
    UserDoc(
        title: "Real-time Data Transmission",
        imageName: "dot.radiowaves.left.and.right",
        description: nil,
        docSection: [
            DocSection(numPoints: "Open the “Panel” page at the tab bar and select “Stream”.", bullist: nil),
            DocSection(numPoints: "Tap the “Enable sending data” button. The device will start a WebSocket server and transmit binary data, including the device’s 6D pose and RGB images from the rear camera.", bullist: nil),
            DocSection(numPoints: "To receive the data elsewhere:",
                       bullist: ["Go to the app’s “Settings” page to find the iPhone’s IP address.",
                                 "Create a WebSocket client on the receiving end and connect to `ws://<IP-address>:8080` (replace `<IP-address>` with the iPhone's IP address)."])
        ]
        
        
    )
]
