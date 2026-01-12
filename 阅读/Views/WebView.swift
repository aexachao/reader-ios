import SwiftUI
import WebKit

final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var updateIsLoading: ((Bool) -> Void)?
    var updateCanGoBack: ((Bool) -> Void)?
    var updateCanGoForward: ((Bool) -> Void)?
    var updateProgress: ((Double) -> Void)?
    var updateURL: ((URL?) -> Void)?
    var updateIsReaderMode: ((Bool) -> Void)?
    var updateLastError: ((Error?) -> Void)?
    var logger: ((String) -> Void)?
    var updateThemeColorHex: ((String?) -> Void)?
    weak var webview: WKWebView?

    init(updateIsLoading: ((Bool) -> Void)? = nil,
         updateCanGoBack: ((Bool) -> Void)? = nil,
         updateCanGoForward: ((Bool) -> Void)? = nil,
         updateProgress: ((Double) -> Void)? = nil,
         updateURL: ((URL?) -> Void)? = nil,
         updateIsReaderMode: ((Bool) -> Void)? = nil,
         updateLastError: ((Error?) -> Void)? = nil,
         updateThemeColorHex: ((String?) -> Void)? = nil,
         logger: ((String) -> Void)? = nil) {
        self.updateIsLoading = updateIsLoading
        self.updateCanGoBack = updateCanGoBack
        self.updateCanGoForward = updateCanGoForward
        self.updateProgress = updateProgress
        self.updateURL = updateURL
        self.updateIsReaderMode = updateIsReaderMode
        self.updateLastError = updateLastError
        self.updateThemeColorHex = updateThemeColorHex
        self.logger = logger
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateIsLoading?(true)
        // keep reference
        self.webview = webView
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateIsLoading?(false)
        updateCanGoBack?(webView.canGoBack)
        updateCanGoForward?(webView.canGoForward)
        updateProgress?(webView.estimatedProgress)
        updateURL?(webView.url)

        // extract theme-color meta or body's background-color
        let js = "(function(){var m=document.querySelector('meta[name=\\'theme-color\\']'); if(m && m.content) return m.content; var bg = window.getComputedStyle(document.body).backgroundColor; return bg; })();"
        webView.evaluateJavaScript(js) { result, error in
            if let err = error {
                self.logger?("theme color js error: \(err)")
                self.updateThemeColorHex?(nil)
            } else if let color = result as? String {
                self.updateThemeColorHex?(color)
            } else {
                self.updateThemeColorHex?(nil)
            }
        }

        if let urlStr = webView.url?.absoluteString.lowercased() {
            // Strict detection: only treat as reader when the path contains '/reader?bookurl='
            if urlStr.contains("/reader?bookurl=") {
                updateIsReaderMode?(true)
            } else {
                updateIsReaderMode?(false)
            }
        } else {
            updateIsReaderMode?(false)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateIsLoading?(false)
        updateLastError?(error)
        logger?("Navigation failed: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateIsLoading?(false)
        updateLastError?(error)
        logger?("Provisional navigation failed: \(error)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        logger?("WebContent process terminated, reloading...")
        webView.reload()
    }

    @objc func handleReloadNotification(_ n: Notification) {
        DispatchQueue.main.async {
            self.webview?.reload()
        }
    }
}

struct WebView: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var isLoading: Bool
    @Binding var progress: Double
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isReaderMode: Bool
    @Binding var lastError: Error?
    var allowsBackForwardNavigationGestures: Bool = true

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(
            updateIsLoading: { [self] newValue in
                DispatchQueue.main.async {
                    self.isLoading = newValue
                }
            },
            updateCanGoBack: { [self] newValue in
                DispatchQueue.main.async {
                    self.canGoBack = newValue
                }
            },
            updateCanGoForward: { [self] newValue in
                DispatchQueue.main.async {
                    self.canGoForward = newValue
                }
            },
            updateProgress: { [self] newValue in
                DispatchQueue.main.async {
                    self.progress = newValue
                }
            },
            updateURL: { [self] newValue in
                DispatchQueue.main.async {
                    self.url = newValue
                }
            },
            updateIsReaderMode: { [self] newValue in
                DispatchQueue.main.async {
                    self.isReaderMode = newValue
                }
            },
            updateLastError: { [self] newValue in
                DispatchQueue.main.async {
                    self.lastError = newValue
                }
            },
            updateThemeColorHex: { hex in
                NotificationCenter.default.post(name: Notification.Name("WebViewThemeColorChanged"), object: hex)
            },
            logger: { self.log($0) }
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let webConfig = WKWebViewConfiguration()
        webConfig.allowsInlineMediaPlayback = true
        
        // 允许使用第三方键盘
        if #available(iOS 14.5, *) {
            webConfig.preferences.isTextInteractionEnabled = true
        }

        let webview = WKWebView(frame: .zero, configuration: webConfig)
        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator
        webview.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        
        // 允许第三方键盘访问
        webview.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // 禁用缩放功能
        webview.scrollView.minimumZoomScale = 1.0
        webview.scrollView.maximumZoomScale = 1.0
        webview.scrollView.bouncesZoom = false

        // Make web content extend under status bar by disabling automatic content inset adjustment
        if #available(iOS 11.0, *) {
            webview.scrollView.contentInsetAdjustmentBehavior = .never
        }
        webview.scrollView.contentInset = .zero
        webview.scrollView.scrollIndicatorInsets = .zero

        webview.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webview.addObserver(context.coordinator, forKeyPath: "URL", options: .new, context: nil)

        if let url = url {
            webview.load(URLRequest(url: url))
        }

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(WebViewCoordinator.handleReloadNotification(_:)), name: Notification.Name("WebViewReloadRequested"), object: nil)

        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            if let url = url {
                uiView.load(URLRequest(url: url))
            }
        }
        uiView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: WebViewCoordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        uiView.removeObserver(coordinator, forKeyPath: "URL")
        NotificationCenter.default.removeObserver(coordinator, name: Notification.Name("WebViewReloadRequested"), object: nil)
    }
}

// Extend coordinator to observe progress and URL changes
extension WebViewCoordinator {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let webview = object as? WKWebView else { return }
        if keyPath == "estimatedProgress" {
            updateProgress?(webview.estimatedProgress)
        } else if keyPath == "URL" {
            updateURL?(webview.url)
                if let urlStr = webview.url?.absoluteString.lowercased() {
                    if urlStr.contains("/reader?bookurl=") {
                        updateIsReaderMode?(true)
                    } else {
                        updateIsReaderMode?(false)
                    }
                }
            // also try to extract theme color when URL changes
            let js = "(function(){var m=document.querySelector('meta[name=\\'theme-color\\']'); if(m && m.content) return m.content; var bg = window.getComputedStyle(document.body).backgroundColor; return bg; })();"
            webview.evaluateJavaScript(js) { result, error in
                if let color = result as? String {
                    self.updateThemeColorHex?(color)
                }
            }
        }
    }
}

extension WebView {
    // small helper for logging
    fileprivate func log(_ message: String) {
        #if DEBUG
        print("[WebView] \(message)")
        #endif
    }
}
