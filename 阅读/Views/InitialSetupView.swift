import SwiftUI

struct InitialSetupView: View {
    @ObservedObject var store: URLStore
    var onComplete: () -> Void

    @State private var name: String = ""
    @State private var url: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("欢迎使用阅读")) {
                    Text("首次使用请添加一个网址以开始阅读。此步骤必填，无法跳过。")
                }

                Section(header: Text("名称")) {
                    TextField("输入名称 (非必填)", text: $name)
                }

                Section(header: Text("url地址")) {
                    TextField("输入 http(s) 地址", text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("初始化设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始") {
                        let safeName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        var fullURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // 如果用户没有输入协议，自动添加 https://
                        if !fullURL.lowercased().hasPrefix("http://") && !fullURL.lowercased().hasPrefix("https://") {
                            fullURL = "https://" + fullURL
                        }
                        
                        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              let _ = URL(string: fullURL) else { return }

                        store.add(name: safeName.isEmpty ? fullURL : safeName, urlString: fullURL)
                        onComplete()
                    }
                    .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}