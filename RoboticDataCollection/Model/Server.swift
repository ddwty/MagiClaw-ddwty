////
////  TCPServer.swift
////  RoboticDataCollection
////
////  Created by 吴天禹 on 2024/8/19.
////
//
//import Foundation
//import Network
//
//class TCPServerManager: ObservableObject {
//    private var listener: NWListener?
//    private var connections = [Int: NWConnection]()
//    private var nextConnectionID = 0
//    
//    init(port: UInt16) {
//        startServer(port: port)
//    }
//    
//    // Start the TCP server
//    private func startServer(port: UInt16) {
//        do {
//            let params = NWParameters.tcp
//            listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: port))
//            
//            listener?.stateUpdateHandler = { state in
//                switch state {
//                case .ready:
//                    print("Server is ready on port \(port)")
//                case .failed(let error):
//                    print("Server failed with error: \(error)")
//                default:
//                    break
//                }
//            }
//            
//            listener?.newConnectionHandler = { [weak self] connection in
//                self?.setupConnection(connection)
//            }
//            
//            listener?.start(queue: .main)
//        } catch {
//            print("Failed to start server: \(error)")
//        }
//    }
//    
//    // Setup a new incoming connection
//    private func setupConnection(_ connection: NWConnection) {
//        let connectionID = nextConnectionID
//        nextConnectionID += 1
//        connections[connectionID] = connection
//        
//        connection.stateUpdateHandler = { state in
//            switch state {
//            case .ready:
//                print("Connection \(connectionID) is ready")
//                self.receiveMessage(connection, connectionID: connectionID)
//            case .failed(let error):
//                print("Connection \(connectionID) failed with error: \(error)")
//                self.connections.removeValue(forKey: connectionID)
//            case .cancelled:
//                print("Connection \(connectionID) cancelled")
//                self.connections.removeValue(forKey: connectionID)
//            default:
//                break
//            }
//        }
//        
//        connection.start(queue: .main)
//    }
//    
//    // Receive messages from the client
//    private func receiveMessage(_ connection: NWConnection, connectionID: Int) {
//        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
//            if let data = data, !data.isEmpty {
//                let message = String(data: data, encoding: .utf8) ?? "Invalid data"
//                print("Received from connection \(connectionID): \(message)")
//                
//                // Echo the message back to the client or process it
//                self.sendMessage("Echo: \(message)", to: connection)
//            }
//            
//            if isComplete {
//                connection.cancel()
//                self.connections.removeValue(forKey: connectionID)
//            } else if let error = error {
//                print("Receive error on connection \(connectionID): \(error)")
//                connection.cancel()
//                self.connections.removeValue(forKey: connectionID)
//            } else {
//                self.receiveMessage(connection, connectionID: connectionID)
//            }
//        }
//    }
//    
//    // Send a message to a client
//    func sendMessage(_ message: String, to connection: NWConnection) {
//        let data = message.data(using: .utf8)
//        connection.send(content: data, completion: .contentProcessed({ error in
//            if let error = error {
//                print("Send error: \(error)")
//            }
//        }))
//    }
//    
//    // Broadcast a message to all connected clients
//    func broadcastMessage(_ message: String) {
//        for connection in connections.values {
//            sendMessage(message, to: connection)
//        }
//    }
//}
//
//import Foundation
//import Network
//
////class WebSocketServerManager: ObservableObject {
////    private var listener: NWListener?
////    private var connections = [Int: NWConnection]()
////    private var nextConnectionID = 0
////    
////    init(port: UInt16) {
////        startServer(port: port)
////    }
////    
////    private func startServer(port: UInt16) {
////        do {
////            let websocketOptions = NWProtocolWebSocket.Options()
////            websocketOptions.autoReplyPing = true
////            let params = NWParameters(tls: nil, tcp: NWProtocolTCP.Options())
////            params.defaultProtocolStack.applicationProtocols.insert(websocketOptions, at: 0)
////            
////            listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: port))
////            
////            listener?.stateUpdateHandler = { state in
////                switch state {
////                case .ready:
////                    print("WebSocket Server is ready on port \(port)")
////                case .failed(let error):
////                    print("WebSocket Server failed with error: \(error)")
////                default:
////                    break
////                }
////            }
////            
////            listener?.newConnectionHandler = { [weak self] connection in
////                self?.setupConnection(connection)
////            }
////            
////            listener?.start(queue: .main)
////        } catch {
////            print("Failed to start WebSocket server: \(error)")
////        }
////    }
////    
////    // Setup a new incoming WebSocket connection
////    private func setupConnection(_ connection: NWConnection) {
////        let connectionID = nextConnectionID
////        nextConnectionID += 1
////        connections[connectionID] = connection
////        
////        connection.stateUpdateHandler = { state in
////            switch state {
////            case .ready:
////                print("WebSocket Connection \(connectionID) is ready")
////                self.receiveMessage(connection, connectionID: connectionID)
////            case .failed(let error):
////                print("WebSocket Connection \(connectionID) failed with error: \(error)")
////                self.connections.removeValue(forKey: connectionID)
////            case .cancelled:
////                print("WebSocket Connection \(connectionID) cancelled")
////                self.connections.removeValue(forKey: connectionID)
////            default:
////                break
////            }
////        }
////        
////        connection.start(queue: .main)
////    }
////    
////    // Receive messages from the client over WebSocket
////    private func receiveMessage(_ connection: NWConnection, connectionID: Int) {
////        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
////            if let data = data, !data.isEmpty {
////                let message = String(data: data, encoding: .utf8) ?? "Invalid data"
////                print("Received from WebSocket connection \(connectionID): \(message)")
////                
////                // Echo the message back to the client or process it
//////                self.sendMessage("Echo: \(message)", to: connection)
////            }
////            
////           
////                self.receiveMessage(connection, connectionID: connectionID)
////            
////        }
////    }
////    
////    // Send a message to a client over WebSocket
////    func sendMessage(_ message: String, to connection: NWConnection) {
////        guard connection.state == .ready else {
////            print("Connection is not ready: \(connection.state)")
////            return
////        }
////
////        let data = message.data(using: .utf8)
////        connection.send(content: data, completion: .contentProcessed({ error in
////            if let error = error {
////                print("Send error: \(error.localizedDescription)")
////                // Optional: Check if the connection state is still `.ready` before closing it
////                if connection.state != .ready {
////                    print("Connection state before cancel: \(connection.state)")
////                    connection.cancel()
////                }
////            } else {
////                print("Message sent successfully")
////            }
////        }))
////    }
////
////
////    
////    // Broadcast a message to all connected WebSocket clients
////    func broadcastMessage(_ message: String) {
////        for connection in connections.values {
////            sendMessage(message, to: connection)
////        }
////    }
////}
