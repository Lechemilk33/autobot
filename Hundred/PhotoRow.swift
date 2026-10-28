import SwiftUI

/// The two daily photos, side by side. Tap an empty slot to take it,
/// tap a filled one to retake or remove it.
struct PhotoRow: View {
    @Binding var face: Data?
    @Binding var body_: Data?

    var body: some View {
        HStack(spacing: 12) {
            PhotoSlot(title: "Face", symbol: "face.smiling",
                      color: .purple, device: .front, data: $face)
            PhotoSlot(title: "Body", symbol: "figure.stand",
                      color: .cyan, device: .rear, data: $body_)
        }
    }
}

struct PhotoSlot: View {
    let title: String
    let symbol: String
    let color: Color
    let device: UIImagePickerController.CameraDevice
    @Binding var data: Data?

    @State private var showingCamera = false

    private var image: UIImage? { data.flatMap(UIImage.init(data:)) }

    var body: some View {
        Button {
            showingCamera = true
        } label: {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.white.opacity(0.08)
                    VStack(spacing: 8) {
                        Image(systemName: symbol)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(color)
                        Text(title)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(alignment: .bottomLeading) {
                if image != nil {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.45), in: .capsule)
                        .padding(10)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(image == nil ? Color.white.opacity(0.10) : color.opacity(0.55),
                                  lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(image == nil ? "Take \(title) photo" : "\(title) photo")
        .contextMenu {
            if image != nil {
                Button("Retake", systemImage: "camera") { showingCamera = true }
                Button("Remove", systemImage: "trash", role: .destructive) {
                    withAnimation(.snappy) { data = nil }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(device: device) { captured in
                withAnimation(.snappy) { data = captured }
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: data) { old, new in old == nil && new != nil }
    }
}
