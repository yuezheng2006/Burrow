//
//  ScanningIndicators.swift
//  Fuchen
//

import SwiftUI

/// Shows currently scanning categories with animated indicators
struct ScanningCategoriesView: View {
    let accent: Color
    let lines: [String]
    @State private var visibleCategories: [String] = []
    @State private var animationTimer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(visibleCategories.enumerated()), id: \.offset) { index, category in
                HStack(spacing: 10) {
                    // Animated scanning icon
                    ScanningDotIndicator(accent: accent, index: index)

                    Text(category)
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(accent.opacity(0.15), lineWidth: 1)
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: 320)
        .onChange(of: lines) { _, newLines in
            updateCategories(from: newLines)
        }
    }

    private func updateCategories(from lines: [String]) {
        // Extract category markers from log lines
        let newCategories = lines
            .filter { $0.hasPrefix("➤") }
            .map { line in
                String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            .suffix(3) // Show last 3 categories

        withAnimation(.easeInOut(duration: 0.4)) {
            visibleCategories = Array(newCategories)
        }
    }
}

/// Animated dot indicator for scanning items
struct ScanningDotIndicator: View {
    let accent: Color
    let index: Int
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { dotIndex in
                Circle()
                    .fill(accent)
                    .frame(width: 4, height: 4)
                    .opacity(dotOpacity(dotIndex))
                    .scaleEffect(dotScale(dotIndex))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }

    private func dotOpacity(_ dotIndex: Int) -> Double {
        let offset = Double(dotIndex) * 0.33 + Double(index) * 0.1
        let value = (phase + offset).truncatingRemainder(dividingBy: 1.0)
        return 0.3 + value * 0.7
    }

    private func dotScale(_ dotIndex: Int) -> CGFloat {
        let offset = Double(dotIndex) * 0.33 + Double(index) * 0.1
        let value = (phase + offset).truncatingRemainder(dividingBy: 1.0)
        return 0.8 + CGFloat(value) * 0.4
    }
}
