//
//  ContentView.swift
//  DIYDragy
//
//  Created by Chris Whiteford on 2020-04-26.
//

import SwiftUI
import Darwin

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    // 🔌 BLE manager hook (shared across tabs)
    @StateObject private var ble = BleNmeaManager()

    var body: some View {
        VStack(spacing: 0) {
            if colorScheme == .light {
                Color(red: 0.97, green: 0.97, blue: 0.97)
                    .edgesIgnoringSafeArea(.top)
                    .frame(height: 1)
            } else {
                Color(red: 0.07, green: 0.07, blue: 0.07)
                    .edgesIgnoringSafeArea(.top)
                    .frame(height: 1)
            }

            DDHeaderView()

            TabView {
                // Inject BLE manager into tabs that need it
                MainView()
                    .environmentObject(ble)
                    .tabItem {
                        Image(systemName: "house").font(.system(size: 21))
                        Text("Home")
                    }

                ResultsView()
                    .environmentObject(DDResultsData.shared)
                    .environmentObject(ble)
                    .tabItem {
                        Image(systemName: "list.dash").font(.system(size: 21))
                        Text("Results")
                    }

                SettingsView()
                    .environmentObject(ble)
                    .tabItem {
                        Image(systemName: "gear").font(.system(size: 24))
                        Text("Settings")
                    }
            }
            .accentColor(colorScheme == .light ? .black : .white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewLayout(PreviewLayout.device)
                .environmentObject(DDAppData.shared)
                .environmentObject(BleNmeaManager())
                .environment(\.colorScheme, .light)

            ContentView()
                .previewLayout(PreviewLayout.device)
                .environmentObject(DDAppData.shared)
                .environmentObject(BleNmeaManager())
                .environment(\.colorScheme, .dark)
        }
    }
}
