//
//  FloatingTabBar.swift
//  RedditKitty
//
//  Created by Akash on 27/03/26.
//
struct TabData: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let icon: String
}

struct FloatingTabBar<Content: View>: View {

    let tabData: [TabData]
    @Binding var selectedIndex: Int
    let content: Content

    @Namespace var namespace
    @State private var showFloating = false
    private let heroHeight = 0.0

    init(tabData: [TabData], selectedIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.tabData = tabData
        self._selectedIndex = selectedIndex
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                scrollableContent(proxy: proxy, showFloating: showFloating)
                floatingButtons(showFloating: showFloating)
            }
        }
    }

    @ViewBuilder
    private func floatingButtons(showFloating: Bool) -> some View {
        if showFloating {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ForEach(tabData.indices, id: \.self) { index in
                        let tab = tabData[index]
                        Button {
                            updateIndex(index)
                        } label: {
                            Label(tab.title, systemImage: tab.icon)
                                .foregroundColor(selectedIndex == index ? .black : .white)
                        }
                        .tint(selectedIndex == index ? .white.opacity(0.8) : .black.opacity(0.5))
                        .matchedGeometryEffect(id: tab.id, in: namespace)
                        .buttonStyle(.glassProminent)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }


    private func scrollableContent(proxy: GeometryProxy, showFloating: Bool) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                heroView()
                tabbar(showFloating: showFloating)
                content
            }
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            let offsetY = geometry.contentOffset.y
            let top = geometry.contentInsets.top
            let adjustedOffset = offsetY + top - heroHeight
            let minY = proxy.frame(in: .global).minY - geometry.contentInsets.top
            return adjustedOffset > minY

        } action: { oldValue, newValue in
            guard oldValue != newValue else {
                return
            }
            withAnimation(.easeInOut(duration: 0.15)) {
                self.showFloating = newValue
            }
        }
    }

    private func heroView() -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.blue.gradient)
            .frame(height: heroHeight)
    }

    @ViewBuilder
    private func tabbar(showFloating: Bool) -> some View {
        if !showFloating {
            HStack(spacing: 5) {
                ForEach(tabData.indices, id: \.self) { index in
                    let tab = tabData[index]
                    RoundedRectangle(cornerRadius: 5)
                        .fill(selectedIndex == index ? .white : .green)
                        .overlay(content: {
                            Image(systemName: tab.icon)
                                .foregroundColor(selectedIndex == index ? .green : .white)
                        })
                        .matchedGeometryEffect(id: tab.id, in: namespace)
                        .onTapGesture {
                            updateIndex(index)
                        }
                }
            }
            .padding(.horizontal)
            .frame(height: 40)
        } else {
            Spacer().frame(height: 60)
        }
    }

    private func updateIndex(_ index: Int) {
        guard index != selectedIndex else { return }
        withAnimation {
            selectedIndex = index
        }
    }
}
