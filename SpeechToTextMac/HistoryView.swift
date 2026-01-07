import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.2, green: 0.2, blue: 0.2)
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)

                    Text("Transcript History")
                        .font(.system(size: 24, weight: .bold))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search transcripts...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()

                // Main Content
                if viewModel.filteredTranscripts.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: viewModel.searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(viewModel.searchText.isEmpty ? "No transcripts yet" : "No matching transcripts")
                            .font(.headline)
                        if viewModel.searchText.isEmpty {
                            Text("Press F13 to start recording")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredTranscripts) { record in
                                TranscriptRow(
                                    record: record,
                                    onCopy: { viewModel.copy(record) },
                                    onRetranscribe: { provider in
                                        viewModel.retranscribe(record, with: provider)
                                    },
                                    onDelete: { viewModel.delete(record) }
                                )
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // Footer
                HStack {
                    Text("\(viewModel.filteredTranscripts.count) transcript\(viewModel.filteredTranscripts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Done") {
                        NSApplication.shared.keyWindow?.close()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .frame(width: 700, height: 650)
        .onAppear {
            viewModel.loadTranscripts()
        }
        .alert("Re-transcription Result", isPresented: .constant(viewModel.retranscriptionResult != nil || viewModel.retranscriptionError != nil)) {
            Button("OK") {
                viewModel.clearRetranscriptionResult()
            }
        } message: {
            if let result = viewModel.retranscriptionResult {
                Text(result)
            } else if let error = viewModel.retranscriptionError {
                Text("Error: \(error)")
            }
        }
        .overlay {
            if viewModel.isRetranscribing {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Re-transcribing...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }
}

struct TranscriptRow: View {
    let record: TranscriptRecord
    let onCopy: () -> Void
    let onRetranscribe: (SpeechProvider) -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: providerIcon)
                    .foregroundStyle(providerColor)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(record.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(record.provider.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(providerColor.opacity(0.2))
                            .foregroundStyle(providerColor)
                            .cornerRadius(4)
                    }

                    Text(record.text)
                        .font(.body)
                        .lineLimit(isExpanded ? nil : 3)
                        .textSelection(.enabled)
                }

                Spacer()

                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help(isExpanded ? "Collapse" : "Expand")
            }

            if isHovered || isExpanded {
                HStack(spacing: 8) {
                    Button(action: onCopy) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Menu {
                        ForEach(SpeechProvider.allCases, id: \.self) { provider in
                            Button {
                                onRetranscribe(provider)
                            } label: {
                                Label(provider.rawValue, systemImage: provider == record.provider ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Re-transcribe", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.white.opacity(isHovered ? 0.08 : 0.05))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var providerIcon: String {
        switch record.provider {
        case .local:
            return "cpu.fill"
        case .openai:
            return "network"
        case .groq:
            return "bolt.fill"
        }
    }

    private var providerColor: Color {
        switch record.provider {
        case .local:
            return .blue
        case .openai:
            return .green
        case .groq:
            return .purple
        }
    }
}

struct HistoryTabContent: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search transcripts...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Main Content
            if viewModel.filteredTranscripts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: viewModel.searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(viewModel.searchText.isEmpty ? "No transcripts yet" : "No matching transcripts")
                        .font(.headline)
                    if viewModel.searchText.isEmpty {
                        Text("Press F13 to start recording")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredTranscripts) { record in
                            TranscriptRow(
                                record: record,
                                onCopy: { viewModel.copy(record) },
                                onRetranscribe: { provider in
                                    viewModel.retranscribe(record, with: provider)
                                },
                                onDelete: { viewModel.delete(record) }
                            )
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Footer
            HStack {
                Text("\(viewModel.filteredTranscripts.count) transcript\(viewModel.filteredTranscripts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            viewModel.loadTranscripts()
        }
        .alert("Re-transcription Result", isPresented: .constant(viewModel.retranscriptionResult != nil || viewModel.retranscriptionError != nil)) {
            Button("OK") {
                viewModel.clearRetranscriptionResult()
            }
        } message: {
            if let result = viewModel.retranscriptionResult {
                Text(result)
            } else if let error = viewModel.retranscriptionError {
                Text("Error: \(error)")
            }
        }
        .overlay {
            if viewModel.isRetranscribing {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Re-transcribing...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
