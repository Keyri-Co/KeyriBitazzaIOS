//
//  SocketManager.swift
//  Bitazza
//
//  Created by Aditya Malladi on 11/30/22.
//

import Foundation
import keyri_pod

class SocketManager: NSObject, URLSessionWebSocketDelegate {
    let url: URL
    var wsTask: URLSessionWebSocketTask?
    let request: URLRequest
    
    var get2fa: (() -> ())?
    var called2fa = false
    var needAPIKey = true
    
    var shouldSendKeyri = true
    
    public init(url: URL) {
        self.url = url
        
        var request = URLRequest(url: url)
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue("https://trade.bitazza.com", forHTTPHeaderField: "Origin")
        request.addValue("no-cache", forHTTPHeaderField: "Pragma")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        self.request = request
        
    }
    
    public func setup() {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        wsTask = urlSession.webSocketTask(with: request)
        wsTask?.resume()
    }
    
    public func sendInitialAuthRequest() {
        wsTask?.send(.string("{\"m\":0,\"i\":14,\"n\":\"WebAuthenticateUser\",\"o\":\"{\\\"password\\\":\\\"Focnyn-denqej-jurqa2\\\",\\\"username\\\":\\\"zain.azeem@gmail.com\\\"}\"}")) { err in
                if let err = err {
                    print(err)
                }
            
        }
        readMessage()
        
    }
    
    public func send2FACode(code: String) {
        print("{\"m\":0,\"i\":16,\"n\":\"Authenticate2FA\",\"o\":\"{\\\"Code\\\":\\\"\(code)\\\"}\"}")
        wsTask?.send(.string("{\"m\":0,\"i\":16,\"n\":\"Authenticate2FA\",\"o\":\"{\\\"Code\\\":\\\"\(code)\\\"}\"}")) { err in
            if let err = err {
                print(err)
            }
        }
        
    }
    
    public func apiKey() {
        wsTask?.send(.string("{\"m\":0,\"i\":94,\"n\":\"AddUserAPIKey\",\"o\":\"{\\\"UserId\\\":434006,\\\"Permissions\\\":[\\\"Trading\\\",\\\"Withdraw\\\",\\\"Deposit\\\"]}\"}")) { err in
            if let err = err {
                print(err)
            }
        }
        needAPIKey = false
    }
    
    public func readMessage()  {
        print("Read message called")
        wsTask?.receive { result in
            print("result")
            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text message: \(text)")
                    if let get2fa = self.get2fa, self.called2fa == false {
                        get2fa()
                        self.called2fa = true
                    }
                    
                    else if self.called2fa, self.needAPIKey {
                        self.apiKey()
                    }
                    
                    if self.shouldSendKeyri, !self.needAPIKey {
                        print("Sending to Keyri")
                        DispatchQueue.main.async {
                            print(text)
                            Keyri().easyKeyriAuth(publicUserId: "", appKey: "CWBd3sBv291ZdOsFdYt36mepIRUyd66W", payload: text) { res in
                                print(res)
                            }
                        }
                    }
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    fatalError()
                }
                
                self.readMessage()
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("CONNECTED TO WEBSOCKET")
        self.sendInitialAuthRequest()
    }
    
    
}
