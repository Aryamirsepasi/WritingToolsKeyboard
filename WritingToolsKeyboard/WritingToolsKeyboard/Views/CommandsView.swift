import SwiftUI

struct CommandsView: View {
    @ObservedObject var commandsManager: KeyboardCommandsManager
    
    @State private var isShowingEditor = false
    @State private var editingCommand: KeyboardCommand? = nil
    
    var body: some View {
        List {
            Section {
                ForEach(commandsManager.builtInCommands) { cmd in
                    commandRow(cmd)
                }
            } header: {
                Text("Built-in Commands")
            } footer: {
                Text("These are the default commands available in the keyboard. You can edit them but not delete them.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section {
                ForEach(commandsManager.customCommands) { cmd in
                    commandRow(cmd)
                }
            } header: {
                Text("Custom Commands")
            } footer: {
                Text("These are your custom commands available in the keyboard.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Keyboard Commands")
        .toolbar {
            Button {
                isShowingEditor = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(item: $editingCommand) { cmd in
            CommandEditorView(
                commandsManager: commandsManager,
                onDismiss: { editingCommand = nil },
                existingCommand: cmd
            )
        }
        .sheet(isPresented: $isShowingEditor) {
            CommandEditorView(
                commandsManager: commandsManager,
                onDismiss: { isShowingEditor = false }
            )
        }
    }
    
    private func commandRow(_ cmd: KeyboardCommand) -> some View {
        HStack {
            Image(systemName: cmd.icon)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(cmd.name)
                    .font(.headline)
                Text(cmd.prompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            
            // Edit
            Button {
                editingCommand = cmd
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            
            // Delete (only available for custom commands)
            if !cmd.isBuiltIn {
                Button(role: .destructive) {
                    commandsManager.deleteCommand(cmd)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// Editor to create or update a Command
struct CommandEditorView: View {
    @ObservedObject var commandsManager: KeyboardCommandsManager
    let onDismiss: () -> Void
    
    var existingCommand: KeyboardCommand? = nil
    
    @State private var name: String = ""
    @State private var prompt: String = ""
    @State private var icon: String = "wand.and.stars"
    @State private var isBuiltIn: Bool = false
    
    let icons: [String] = [
        "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "globe",
        "text.bubble.fill", "pencil", "doc.fill", "book.fill", "bookmark.fill",
        "tag.fill", "checkmark.circle.fill", "bell.fill", "flag.fill", "paperclip",
        "link", "quote.bubble.fill", "list.bullet", "chart.bar.fill", "arrow.right.circle.fill",
        "arrow.triangle.2.circlepath", "magnifyingglass", "lightbulb.fill", "wand.and.stars",
        "brain.head.profile", "character.bubble", "globe.europe.africa.fill",
        "globe.americas.fill", "globe.asia.australia.fill", "character", "textformat",
        "folder.fill", "pencil.tip.crop.circle", "paintbrush", "text.justify", "scissors",
        "doc.on.clipboard", "arrow.up.doc", "arrow.down.doc", "doc.badge.plus",
        "bookmark.circle.fill", "bubble.left.and.bubble.right", "doc.text.magnifyingglass",
        "checkmark.rectangle", "trash", "quote.bubble", "abc", "globe.badge.chevron.backward",
        "character.book.closed", "book", "rectangle.and.text.magnifyingglass",
        "keyboard", "text.redaction", "a.magnify", "character.textbox",
        "character.cursor.ibeam", "cursorarrow.and.square.on.square.dashed", "rectangle.and.pencil.and.ellipsis",
        "bubble.middle.bottom", "bubble.left", "text.badge.star", "text.insert", "arrow.uturn.backward.circle.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Command Info") {
                    TextField("Name", text: $name)
                    TextField("Prompt", text: $prompt, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { icn in
                                Button {
                                    icon = icn
                                } label: {
                                    Image(systemName: icn)
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(icon == icn ? Color.blue.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                if existingCommand?.isBuiltIn == true {
                    Section {
                        Text("This is a built-in command. While you can modify it, you cannot delete it.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(existingCommand == nil ? "New Command" : "Edit Command")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cmd = KeyboardCommand(
                            id: existingCommand?.id ?? UUID(),
                            name: name,
                            prompt: prompt,
                            icon: icon,
                            isBuiltIn: existingCommand?.isBuiltIn ?? false
                        )
                        if let _ = existingCommand {
                            commandsManager.updateCommand(cmd)
                        } else {
                            commandsManager.addCommand(cmd)
                        }
                        onDismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let existing = existingCommand {
                name = existing.name
                prompt = existing.prompt
                icon = existing.icon
                isBuiltIn = existing.isBuiltIn
            }
        }
    }
}
