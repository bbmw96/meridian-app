import SwiftUI

struct VaultView: View {
    @State private var cipher = CipherProtocol()
    @State private var showingAddSheet = false
    @State private var selectedCategory: CipherEntry.Category = .intelligence
    @State private var newLabel = ""
    @State private var newContent = ""
    @State private var revealedContent: [UUID: String] = [:]
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                if cipher.isUnlocked {
                    unlockedView
                } else {
                    lockedView
                }
            }
            .navigationTitle("CIPHER Vault")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if cipher.isUnlocked {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingAddSheet = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation { cipher.lock() }
                        } label: {
                            Label("Lock", systemImage: "lock.fill")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddVaultEntrySheet(
                    label: $newLabel,
                    content: $newContent,
                    category: $selectedCategory,
                    onSave: {
                        do {
                            _ = try cipher.store(label: newLabel, category: selectedCategory, plaintext: newContent)
                            newLabel = ""
                            newContent = ""
                            showingAddSheet = false
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                )
            }
            .alert("Vault Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.meridianAccent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.meridianAccent)
                        .meridianGlow(colour: .meridianAccent)
                }

                VStack(spacing: 8) {
                    Text("Intelligence Vault")
                        .font(.title2).fontWeight(.bold)
                    Text("Zero-knowledge encrypted storage.\nAuthenticate to access your classified intelligence.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        do {
                            try await cipher.unlock()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    Label("Authenticate with Face ID", systemImage: "faceid")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.meridianAccent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                HStack(spacing: 6) {
                    Image(systemName: "lock.doc.fill").font(.caption2).foregroundStyle(.secondary)
                    Text("AES-GCM 256-bit · CryptoKit · On-device only")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(32)
    }

    private var unlockedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let stats = cipher.stats {
                    VaultStatsCard(stats: stats)
                }

                if cipher.entries.isEmpty {
                    VaultEmptyState()
                } else {
                    VStack(spacing: 0) {
                        ForEach(CipherEntry.Category.allCases, id: \.rawValue) { cat in
                            let catEntries = cipher.entries.filter { $0.category == cat }
                            if !catEntries.isEmpty {
                                VaultCategorySection(
                                    category: cat,
                                    entries: catEntries,
                                    revealedContent: $revealedContent,
                                    onReveal: { entry in
                                        do {
                                            revealedContent[entry.id] = try cipher.retrieve(entry)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            showError = true
                                        }
                                    },
                                    onDelete: { entry in
                                        try? cipher.delete(entry)
                                        revealedContent.removeValue(forKey: entry.id)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Sub-views

struct VaultStatsCard: View {
    let stats: CipherVaultStats

    var body: some View {
        HStack(spacing: 20) {
            VaultStat(label: "Entries", value: "\(stats.totalEntries)", icon: "doc.fill")
            Divider().frame(height: 32)
            VaultStat(label: "Size", value: "\(stats.encryptedSizeBytes / 1024)KB", icon: "internaldrive.fill")
            Divider().frame(height: 32)
            VaultStat(label: "Integrity", value: stats.integrityStatus.rawValue, icon: "checkmark.shield.fill")
        }
        .padding(16)
        .meridianCard()
        .padding(.horizontal)
    }
}

struct VaultStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.callout).foregroundStyle(Color.meridianAccent)
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VaultCategorySection: View {
    let category: CipherEntry.Category
    let entries: [CipherEntry]
    @Binding var revealedContent: [UUID: String]
    let onReveal: (CipherEntry) -> Void
    let onDelete: (CipherEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(category.rawValue)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(entries) { entry in
                VaultEntryRow(
                    entry: entry,
                    revealedText: revealedContent[entry.id],
                    onReveal: { onReveal(entry) },
                    onHide: { revealedContent.removeValue(forKey: entry.id) },
                    onDelete: { onDelete(entry) }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
}

struct VaultEntryRow: View {
    let entry: CipherEntry
    let revealedText: String?
    let onReveal: () -> Void
    let onHide: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.label).font(.subheadline).fontWeight(.semibold)
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                Button(revealedText != nil ? "Hide" : "Reveal") {
                    revealedText != nil ? onHide() : onReveal()
                }
                .font(.caption).foregroundStyle(Color.meridianAccent)
            }

            if let text = revealedText {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text("● ● ● ● ● ● ● ● ● ● ●")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .meridianCard()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct VaultEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.meridianAccent.opacity(0.4))
            Text("No Classified Intelligence")
                .font(.title3).fontWeight(.semibold)
            Text("Tap + to add your first encrypted entry.\nAll data is encrypted with AES-GCM 256-bit on-device.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct AddVaultEntrySheet: View {
    @Binding var label: String
    @Binding var content: String
    @Binding var category: CipherEntry.Category
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("Entry name", text: $label)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(CipherEntry.Category.allCases, id: \.rawValue) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                Section("Content") {
                    TextEditor(text: $content).frame(minHeight: 120)
                }
                Section {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.green)
                        Text("Encrypted with AES-GCM 256-bit before saving")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Encrypt & Save", action: onSave)
                        .disabled(label.isEmpty || content.isEmpty)
                }
            }
        }
    }
}
