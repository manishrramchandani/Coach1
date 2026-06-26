//  MessagesView.swift
//  CoachOS — Features/Messaging
//
//  CALLOUT: Implements FR-8 (1:1 coach↔client messaging) + design UF-S5. Uses
//  POLLING for near-real-time (MVP transport decision: 15s poll) behind the service
//  layer so a WebSocket swap is isolated. Shows timestamps + read state; marks
//  inbound messages read on open (read receipts).

import SwiftUI

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var draft = ""
    private var api: APIService
    private var pollTask: Task<Void, Never>?
    private(set) var meId: UUID = UUID()
    init(api: APIService) { self.api = api }
    func configure(api: APIService, meId: UUID) { self.api = api; self.meId = meId }

    func load() async {
        if let (_, msgs) = try? await api.fetchMessages() { messages = msgs }
        try? await api.markRead()
    }
    // CALLOUT: Poll every 15s (MVP). Cancelled on disappear to save battery.
    func startPolling() {
        pollTask = Task { while !Task.isCancelled { try? await Task.sleep(nanoseconds: 15_000_000_000); await load() } }
    }
    func stopPolling() { pollTask?.cancel() }

    func send() async {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        draft = ""
        if let m = try? await api.sendMessage(body) { messages.append(m) }
    }
}

struct MessagesView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var vm = MessagesViewModel(api: MockAPIService())
    @State private var configured = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Space.s) {
                    ForEach(vm.messages) { m in MessageBubble(message: m, isMe: m.senderId == vm.meId) }
                }.padding(Space.l)
            }
            // Composer
            HStack(spacing: Space.s) {
                TextField("Message your coach", text: $vm.draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(1...4)
                Button { Task { await vm.send() } } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundColor(AppColor.accent)
                }.frame(width: 44, height: 44)
            }
            .padding(Space.m).background(AppColor.surface)
        }
        .background(AppColor.background)
        .navigationTitle(state.session?.coach.name ?? "Coach")
        .task {
            if !configured { vm.configure(api: state.api, meId: state.session?.user.id ?? UUID()); configured = true }
            await vm.load(); vm.startPolling()
        }
        .onDisappear { vm.stopPolling() }
    }
}

// CALLOUT: Chat bubble. Mine = orange right-aligned; coach = surface left-aligned.
// Shows time + a read indicator on my sent messages.
struct MessageBubble: View {
    let message: Message
    let isMe: Bool
    var body: some View {
        HStack {
            if isMe { Spacer() }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(message.body).font(AppFont.body)
                    .foregroundColor(isMe ? .white : AppColor.ink)
                    .padding(.horizontal, Space.m).padding(.vertical, Space.s)
                    .background(isMe ? AppColor.accent : AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sheet))
                HStack(spacing: Space.xs) {
                    Text(message.sentAt, style: .time).font(.system(size: 11)).foregroundColor(AppColor.muted)
                    if isMe { Image(systemName: message.readAt != nil ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 10)).foregroundColor(AppColor.muted) }
                }
            }
            if !isMe { Spacer() }
        }
    }
}
