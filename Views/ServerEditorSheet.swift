// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

struct ServerEditorSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let editor: ServerEditorState

    @State private var name: String
    @State private var urlString: String
    @State private var errorMessage: String?

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(editor: ServerEditorState) {
        self.editor = editor
        _name = State(initialValue: editor.name)
        _urlString = State(initialValue: editor.urlString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(editor.title)
                .font(.title2.weight(.semibold))

            Form {
                TextField("Server name", text: $name)
                TextField("Server URL", text: $urlString)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isSaveDisabled)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func cancel() {
        dismiss()
    }

    private func save() {
        do {
            try model.updateServer(editor: editor, name: name, urlString: urlString)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
