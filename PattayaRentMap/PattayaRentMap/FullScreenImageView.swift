import SwiftUI
import AppKit

struct FullScreenImageView: View {
    let images: [NSImage]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool

    enum TransitionDirection { case forward, backward }

    @State private var transitionDirection: TransitionDirection = .forward
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Кнопка закрытия
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white, .blue)
                            .font(.title)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                            }
                    }
                    .buttonStyle(.plain)
                    
                }
                .padding([.top, .trailing], 12)

                Spacer()

                // Основное изображение
                
                ZStack {
                    ForEach(images.indices, id: \.self) { index in
                        if index == currentIndex {
                            Image(nsImage: images[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit) // Восстанавливаем правильное соотношение
                                .frame(maxWidth: .infinity, maxHeight: .infinity) // Занимаем всё доступное пространство
                                .scaleEffect(currentScale)
                                .offset(currentOffset)
                                .transition(getTransition())
                                .zIndex(1)
                                .gesture(magnifyAndDragGestures)
                                .simultaneousGesture(doubleTapGesture)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Главный контейнер

                Spacer() // Добавьте этот Spacer перед индикаторами

                // Индикаторы
                VStack(spacing: 8) {
                    Text("\(currentIndex + 1) из \(images.count)")
                        .foregroundColor(.white)
                        .font(.caption)

                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == currentIndex ? Color.white : Color.gray.opacity(0.5))
                                .frame(width: index == currentIndex ? 20 : 8, height: 8)
                                .onTapGesture {
                                    withAnimation { currentIndex = index }
                                }
                        }
                    }
                }
                .padding(.bottom, 20) // Можно увеличить этот отступ, если нужно опустить еще ниже
                
            }

            // Кнопки навигации
            HStack {
                Button(action: goPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .disabled(currentIndex == 0)
                .opacity(currentIndex == 0 ? 0 : 1)

                Spacer()

                Button(action: goNext) {
                    Image(systemName: "chevron.right")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .disabled(currentIndex >= images.count - 1)
                .opacity(currentIndex >= images.count - 1 ? 0 : 1)
            }
            .padding(.horizontal, 20)
        }
        .gesture(swipeGesture)
        .onChange(of: currentIndex) {resetImageState() }
    }

    private var magnifyAndDragGestures: some Gesture {
        MagnificationGesture()
            .onChanged { value in currentScale = lastScale * value }
            .onEnded { _ in
                lastScale = currentScale
                if currentScale < 1.0 { resetImageState() }
            }
            .simultaneously(with:
                DragGesture()
                    .onChanged { value in
                        if currentScale > 1.0 {
                            currentOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in lastOffset = currentOffset }
            )
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    currentScale = currentScale > 1.0 ? 1.0 : 2.5
                    lastScale = currentScale
                }
            }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                if currentScale == 1.0 {
                    if value.translation.width < -50 { goNext() }
                    else if value.translation.width > 50 { goPrevious() }
                }
            }
    }

    private func goPrevious() {
        resetImageState()
        withAnimation {
            transitionDirection = .backward
            currentIndex = max(0, currentIndex - 1)
        }
    }

    private func goNext() {
        resetImageState()
        withAnimation {
            transitionDirection = .forward
            currentIndex = min(images.count - 1, currentIndex + 1)
        }
    }

    private func resetImageState() {
        withAnimation {
            currentScale = 1.0
            lastScale = 1.0
            currentOffset = .zero
            lastOffset = .zero
        }
    }

    private func getTransition() -> AnyTransition {
        switch transitionDirection {
        case .forward: return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .backward: return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }
}
