import SwiftUI

struct AddressManagerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var store: URLStore
    /// Called when the user selects an address from the list. Passes the selected URL.
    var onSelect: ((URL) -> Void)? = nil

    @State private var showingAdd = false
    @State private var editingItem: URLItem? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(store.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text(item.urlString).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if store.selectedID == item.id {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.select(id: item.id)
                        if let url = URL(string: item.urlString) {
                            onSelect?(url)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .contextMenu {
                        if store.selectedID == item.id {
                            // currently in use – show a disabled label
                            Text("使用中")
                        } else {
                            Button("编辑") { editingItem = item }
                            Button("删除", role: .destructive) { store.remove(id: item.id) }
                        }
                    }
                }
                .onDelete { idxSet in
                    for idx in idxSet {
                        let id = store.items[idx].id
                        // skip deleting the selected (in-use) item
                        if store.selectedID == id { continue }
                        store.remove(id: id)
                    }
                }
            }
            .navigationTitle("地址管理")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showingAdd = true }) { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddressEditView { name, url in
                    store.add(name: name, urlString: url)
                    showingAdd = false
                }
            }
            .sheet(item: $editingItem) { item in
                AddressEditView(item: item) { name, url in
                    store.update(id: item.id, name: name, urlString: url)
                    editingItem = nil
                }
            }
        }
    }
}

struct AddressEditView: View {
    var item: URLItem? = nil
    var onSave: (String, String) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var name: String = ""
    @State private var url: String = ""

    var body: some View {
        NavigationView {
            Form {
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
            .navigationTitle(item == nil ? "新增地址" : "编辑地址")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var fullURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // 如果用户没有输入协议，自动添加 https://
                        if !fullURL.lowercased().hasPrefix("http://") && !fullURL.lowercased().hasPrefix("https://") {
                            fullURL = "https://" + fullURL
                        }
                        
                        onSave(name.isEmpty ? fullURL : name, fullURL)
                        presentationMode.wrappedValue.dismiss()
                    }.disabled(url.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .onAppear {
            if let item = item {
                name = item.name
                url = item.urlString
            }
        }
    }
}