// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import SwiftUI

struct NativeTabBar: View {
    @Environment(AppModel.self) private var model

    let serverID: UUID

    var body: some View {
        let tabs = model.views.tabs(for: serverID)
        let activeID = model.views.activeView(for: serverID)?.id

        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        TabButton(
                            tab: tab,
                            isSelected: tab.id == activeID,
                            isCloseDisabled: tabs.count <= 1
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            Button(action: createTab) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.trailing, 8)
        }
        .background(.bar)
    }

    private func createTab() {
        model.createTab(for: serverID)
    }
}

private struct TabButton: View {
    @Environment(AppModel.self) private var model

    let tab: MattermostViewState
    let isSelected: Bool
    let isCloseDisabled: Bool

    var body: some View {
        HStack(spacing: 6) {
            Button(action: select) {
                TabTitle(tab: tab)
            }
            .buttonStyle(.plain)

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Close Tab")
            .disabled(isCloseDisabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 120, maxWidth: 220)
        .background(
            isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
            in: RoundedRectangle(cornerRadius: 7)
        )
    }

    private func select() {
        model.views.setActiveView(tab.id, for: tab.serverID)
    }

    private func close() {
        model.closeTab(tab)
    }
}

private struct TabTitle: View {
    let tab: MattermostViewState

    var body: some View {
        HStack(spacing: 5) {
            Text(tab.title.isEmpty ? "Mattermost" : tab.title)
                .lineLimit(1)
            TabUnreadIndicator(tab: tab)
        }
    }
}

private struct TabUnreadIndicator: View {
    let tab: MattermostViewState

    var body: some View {
        if tab.mentionCount > 0 {
            Text("\(tab.mentionCount)")
                .font(.caption2)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.red, in: Capsule())
                .foregroundStyle(.white)
        } else if tab.hasUnread {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
        }
    }
}
