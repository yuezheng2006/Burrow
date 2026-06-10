//
//  CleanableItemsView.swift
//  Fuchen
//
//  Interactive cleanable items list with checkbox selection
//

import SwiftUI

/// Cleanable category with selection state
struct CleanableCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let currentSize: String
    let maxSize: String
    let progress: Double // 0.0 - 1.0
    var isSelected: Bool
    var details: [String] = []
}

/// Interactive cleanable items list view
struct CleanableItemsView: View {
    @Binding var categories: [CleanableCategory]
    let accent: Color

    var totalSelected: String {
        // Calculate total size of selected items
        let total = categories.filter { $0.isSelected }
            .compactMap { parseSize($0.maxSize) }
            .reduce(0, +)
        return formatSize(total)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.readyToClean)
                    .font(Brand.sans(13, .semibold))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Text(L10n.selectedItems(categories.filter { $0.isSelected }.count, categories.count))
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Rectangle().fill(Brand.hairline).frame(height: 1)

            // Scrollable list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($categories) { $category in
                        CleanableCategoryRow(category: $category, accent: accent)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }

            // Bottom summary bar
            Rectangle().fill(Brand.hairline).frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.permanentClean)
                        .font(Brand.sans(11))
                        .foregroundStyle(Brand.textTertiary)
                    Text(totalSelected)
                        .font(Brand.mono(20, .bold))
                        .foregroundStyle(accent)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.2))
        }
    }

    private func parseSize(_ str: String) -> Double {
        let clean = str.replacingOccurrences(of: " ", with: "")
        if clean.hasSuffix("GB") {
            return Double(clean.dropLast(2)) ?? 0.0
        } else if clean.hasSuffix("MB") {
            return (Double(clean.dropLast(2)) ?? 0.0) / 1024.0
        } else if clean.hasSuffix("KB") {
            return (Double(clean.dropLast(2)) ?? 0.0) / 1024.0 / 1024.0
        }
        return 0.0
    }

    private func formatSize(_ gb: Double) -> String {
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else if gb >= 0.001 {
            return String(format: "%.0f MB", gb * 1024)
        } else {
            return String(format: "%.0f KB", gb * 1024 * 1024)
        }
    }
}

/// Single cleanable category row
struct CleanableCategoryRow: View {
    @Binding var category: CleanableCategory
    let accent: Color
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Checkbox
                    CheckboxView(isChecked: $category.isSelected, accent: accent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                category.isSelected.toggle()
                            }
                        }

                    // Icon
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(accent)
                        .frame(width: 24)

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(category.title)
                                .font(Brand.sans(13, .semibold))
                                .foregroundStyle(Brand.textPrimary)
                            Text(category.subtitle)
                                .font(Brand.mono(10))
                                .foregroundStyle(Brand.textTertiary)
                        }

                        Text(category.subtitle)
                            .font(Brand.sans(11))
                            .foregroundStyle(Brand.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Size info
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(category.currentSize)
                            .font(Brand.mono(12, .medium))
                            .foregroundStyle(Brand.textSecondary)
                        Text("/ " + category.maxSize)
                            .font(Brand.mono(10))
                            .foregroundStyle(accent)
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Brand.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(category.isSelected ? accent.opacity(0.08) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            category.isSelected ? accent.opacity(0.3) : Brand.hairline,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)

            // Expanded details
            if isExpanded && !category.details.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(category.details, id: \.self) { detail in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Brand.textTertiary)
                                .frame(width: 3, height: 3)
                            Text(detail)
                                .font(Brand.mono(10))
                                .foregroundStyle(Brand.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

/// Animated checkbox
struct CheckboxView: View {
    @Binding var isChecked: Bool
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(isChecked ? accent : Brand.textTertiary, lineWidth: 2)
                .frame(width: 20, height: 20)

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                    .scaleEffect(isChecked ? 1.0 : 0.3)
            }
        }
    }
}
