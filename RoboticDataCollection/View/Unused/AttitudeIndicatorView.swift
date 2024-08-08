////
////  AttitudeIndicatorView.swift
////  talkWithRpi
////
////  Created by Tianyu on 7/19/24.
////
//import SwiftUI
//
//struct AttitudeIndicatorView: View {
//    @ObservedObject var motionManager: MotionManager
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//    @Binding var showCharts: Bool
//    let textWidth = CGFloat(50)
//    
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        if verticalSizeClass == .regular {
//            VStack() {
//                QuaternionVisualizer(x: $motionManager.motionData.quaternion.x, y: $motionManager.motionData.quaternion.y, z: $motionManager.motionData.quaternion.z, w: $motionManager.motionData.quaternion.w, showCharts: $showCharts)
//                    .frame(height: height * 0.2)
////                    .border(.red)
//                
//                AttitudeVisualizer(
//                    pitch: motionManager.motionData.attitude.pitchDegrees,
//                    roll: motionManager.motionData.attitude.rollDegrees,
//                    yaw: motionManager.motionData.attitude.yawDegrees
//                )
//                .aspectRatio(1, contentMode: .fit)
//                .frame(width: width * 0.15)
//                .padding(.top, 30)
////                .border(.green)
//                
//                
//                
//                Button(action: {
//                    self.motionManager.resetReferenceFrame()
//                }) {
//                    Text("Reset Reference")
//                }
//                .buttonStyle(.bordered)
//            }
////            .padding()
//            
//        } else {
//            QuaternionVisualizer(x: $motionManager.motionData.quaternion.x, y: $motionManager.motionData.quaternion.y, z: $motionManager.motionData.quaternion.z, w: $motionManager.motionData.quaternion.w, showCharts: $showCharts)
//            
//            Spacer()
//            
//            VStack(alignment: .center) {
//                AttitudeVisualizer(
//                    pitch: motionManager.motionData.attitude.pitchDegrees,
//                    roll: motionManager.motionData.attitude.rollDegrees,
//                    yaw: motionManager.motionData.attitude.yawDegrees
//                )
//                .aspectRatio(1, contentMode: .fit)
//                .offset(y: 10)
//                
//                Button(action: {
//                    self.motionManager.resetReferenceFrame()
//                }) {
//                    Text("Reset Reference")
//                }
//                .padding(.horizontal)
//            }
//            .frame(width: width * 0.25)
//            //            .border(.purple)
//            Spacer()
//            
//            AccelerationView(x:$motionManager.motionData.acceleration.x , y: $motionManager.motionData.acceleration.y, z: $motionManager.motionData.acceleration.z, showCharts: $showCharts)
//        }
//        //: HStack
//        //        .padding()
////            .frame(width: width, height: height * 0.3)
//    }
//}
//
//
//struct QuaternionVisualizer: View {
//    @Binding var x: Double
//    @Binding var y: Double
//    @Binding var z: Double
//    @Binding var w: Double
//    @Binding var showCharts: Bool
//    var body: some View {
//        HStack(alignment: .top) {
//            VStack {
//                Spacer()
//                Text("Quaternion")
//                    .font(.headline)
//                Divider()
//                //                        GeometryReader { geometry in
//                HStack(spacing: 0) {
//                    Text("x:\(self.x, specifier: "%.1f")")
//                        .foregroundStyle(.red)
//                    Spacer()
//                    Text("y:\(self.y, specifier: "%.1f")")
//                        .foregroundStyle(.green)
//                    Spacer()
//                    Text("z:\(self.z, specifier: "%.1f")")
//                        .foregroundStyle(.blue)
//                    Spacer()
//                    Text("w:\(self.w, specifier: "%.1f")")
//                    
//                }
//                Spacer()
//            }
//            .padding()
//            .background(Color(UIColor.systemGray6))
//            .cornerRadius(15)
//            .shadow(radius: 1)
//            .onTapGesture {
//                showCharts.toggle()
//            }
//        }
//    }
//}
//
//struct AttitudeVisualizer: View {
//    var pitch: Double
//    var roll: Double
//    var yaw: Double
//    
//    var body: some View {
//        GeometryReader { geometry in
//            let size = min(geometry.size.width, geometry.size.height)
//            let halfSize = size / 2
//            ZStack {
//                Path { path in
//                    path.move(to: CGPoint(x: halfSize, y: 0))
//                    path.addLine(to: CGPoint(x: halfSize, y: size))
//                    path.move(to: CGPoint(x: 0, y: halfSize))
//                    path.addLine(to: CGPoint(x: size, y: halfSize))
//                }
//                .stroke(Color.gray, lineWidth: 1.5)
//                
//                Circle()
//                    .fill(Color.red)
//                    .frame(width: size * 0.1, height: size * 0.1)
//                    .offset(x: CGFloat(pitch * halfSize / 90), y: 0)
//                
//                Circle()
//                    .fill(Color.green)
//                    .frame(width: size * 0.1, height: size * 0.1)
//                    .offset(x: 0, y: CGFloat(-roll * halfSize / 90))
//                
//                Path { path in
//                    let startAngle = Angle(degrees: 180)
//                    let endAngle = Angle(degrees: 0)
//                    path.addArc(center: CGPoint(x: halfSize, y: halfSize - 10), radius: halfSize, startAngle: startAngle, endAngle: endAngle, clockwise: false)
//                }
//                .stroke(Color.gray, lineWidth: 1.5)
//                
//                let angle = Angle(degrees: yaw)
//                let radius = halfSize
//                let yOffset = -cos(angle.radians) * radius - 10
//                let xOffset = -sin(angle.radians) * radius
//                
//                Circle()
//                    .fill(Color.blue)
//                    .frame(width: size * 0.1, height: size * 0.1)
//                    .offset(x: CGFloat(xOffset), y: CGFloat(yOffset))
//            }
//            .frame(width: geometry.size.width, height: geometry.size.height)
//            .aspectRatio(1, contentMode: .fit)
//            
//        }
//    }
//}
//
//#Preview() {
//    AttitudeIndicatorView(motionManager: MotionManager.shared, showCharts: .constant(false), width: 734, height: 372)
//}
//
//
//
//
//struct AccelerationView: View {
//    @Binding var x: Double
//    @Binding var y: Double
//    @Binding var z: Double
//    @Binding var showCharts: Bool
//    var body: some View {
//        VStack {
//            Spacer()
//            Text("Acceleration (0.1g)")
//                .font(.headline)
//            Divider()
//            //                        GeometryReader { geometry in
//            HStack(spacing: 0) {
//                Text("x:\(x * 10, specifier: "%.1f")")
//                    .foregroundStyle(.red)
//                Spacer()
//                Text("y:\(y * 10, specifier: "%.1f")")
//                    .foregroundStyle(.green)
//                Spacer()
//                Text("z:\(z * 10, specifier: "%.1f")")
//                    .foregroundStyle(.blue)
//                
//                //                            }
//                //                            .frame(width: geometry.size.width)
//            }
//            Spacer()
//        }
//        .padding()
//        .background(Color(UIColor.systemGray6))
//        .cornerRadius(15)
//        .shadow(radius: 1)
//        .onTapGesture {
//            showCharts.toggle()
//        }
//    }
//}
