//
//  ContentView.swift
//  阅读
//
//  Created by Chris Li on 2025/10/21.
//

import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @StateObject private var store = URLStore()

    @State private var currentURL: URL? = nil
    @State private var isLoading = false
    @State private var progress: Double = 0
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isReaderMode = false
    @State private var lastError: Error? = nil
    @State private var showingAddresses = false
    @State private var showingInitialSetup = false
    

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // WebView 作为底层
                WebView(url: $currentURL,
                        isLoading: $isLoading,
                        progress: $progress,
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        isReaderMode: $isReaderMode,
                        lastError: $lastError)
                    .edgesIgnoringSafeArea([.top, .bottom])
                
                // 进度条在最顶层，状态栏下方
                if isLoading && progress < 1.0 {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: geometry.safeAreaInsets.top)
                        
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * CGFloat(progress), height: 2)
                                .animation(.linear(duration: 0.2), value: progress)
                        }
                        .frame(height: 2)
                        
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }

                // Floating buttons (hidden in reader mode)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if !isReaderMode {
                            VStack(spacing: 12) {
                                Button(action: { refresh() }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.black.opacity(0.65)))
                                }
                                .buttonStyle(.plain)

                                Button(action: { showingAddresses = true }) {
                                    Image(systemName: "gearshape")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.black.opacity(0.65)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            // If there's no selected (in-use) address, force initial setup once
            if store.selectedID == nil {
                showingInitialSetup = true
                return
            }

            // restore last visited if available, otherwise load selected
            if let last = store.lastVisitedURL() {
                currentURL = last
            } else if let item = store.item(for: store.selectedID) {
                currentURL = URL(string: item.urlString)
            }

            // 屏幕常亮
            UIApplication.shared.isIdleTimerDisabled = true
            // 需要在后续实现 BackgroundAudioManager 激活后台音频
            BackgroundAudioManager.shared.start()
        }
        .onDisappear {
            BackgroundAudioManager.shared.stop()
        }
        .sheet(isPresented: $showingAddresses) {
            AddressManagerView(store: store, onSelect: { url in
                currentURL = url
                store.setLastVisited(url: url)
            })
        }
        .fullScreenCover(isPresented: $showingInitialSetup) {
            InitialSetupView(store: store) {
                // 完成后关闭并加载所选网址
                showingInitialSetup = false
                if let selected = store.item(for: store.selectedID) {
                    currentURL = URL(string: selected.urlString)
                    store.setLastVisited(url: currentURL)
                } else if let first = store.items.first {
                    currentURL = URL(string: first.urlString)
                    store.select(id: first.id)
                    store.setLastVisited(url: currentURL)
                }
            }
        }
        .statusBar(hidden: isReaderMode)
        .onChange(of: currentURL) { oldValue, newValue in
            store.setLastVisited(url: newValue)
        }
        .onChange(of: isReaderMode) { oldValue, newValue in
            // 发送通知给 CustomHostingController
            NotificationCenter.default.post(
                name: Notification.Name("ReaderModeChanged"),
                object: newValue
            )
        }
        // debug overlay removed
    }

    // (No modal transparent controller – using lightweight HomeIndicatorController overlay only)

    private func refresh() {
        NotificationCenter.default.post(name: Notification.Name("WebViewReloadRequested"), object: nil)
    }

    // no-op: removed modal presentation approach to avoid blocking web interactions
}

#Preview {
    ContentView()
}
