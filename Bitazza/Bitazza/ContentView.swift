//
//  ContentView.swift
//  Bitazza
//
//  Created by Aditya Malladi on 11/29/22.
//

import SwiftUI

struct ContentView: View {
    @State private var username: String = ""
    @State private var pw: String = ""
    
    @State private var show2fa = false
    
    @State private var code: String = ""
    
    private var sm = SocketManager(url: URL(string: "wss://apexapi.bitazza.com/WSGateway")!)
    
    var body: some View {
        VStack {
            if show2fa {
                SecureField(
                    "2fa Code",
                    text: $code
                ).font(.title2)
            } else {
                TextField(
                    "User name",
                    text: $username
                ).font(.title2)
                SecureField(
                    "password",
                    text: $pw
                ).font(.title2)
            }
            
            Button(show2fa == true ? "Submit 2fa code" : "Submit username/password") {
                if !self.show2fa {
                    sm.get2fa = {
                        print("callback")
                        self.show2fa = true
                    }
                    sm.setup()
                } else {
                    sm.send2FACode(code: code)
                }
                
            }.font(.title3)
            
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
