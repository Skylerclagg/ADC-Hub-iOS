//
//  GameManual.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI
import WebKit


// Main SwiftUI view for the Game Manual
struct GameManual: View {
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    var body: some View {
        // Embedding the WebView that will display the flipbook
        WebView(url: URL(string: "https://online.flippingbook.com/view/201482508/")!).onAppear(){
            navigation_bar_manager.title = "Game Manual"
        }
        
        // Set the title for the navigation bar
    }
}
// SwiftUI wrapper for WKWebView to display web content in SwiftUI
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        // Create and configure the WKWebView instance
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No need to update the view during state changes
    }
}


// Preview for SwiftUI (optional)
struct GameManual_Previews: PreviewProvider {
    static var previews: some View {
        GameManual()
    }
}
