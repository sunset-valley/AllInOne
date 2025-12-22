import SwiftUI

struct BuildInTransitionConfig: Identifiable {
  struct Config: Identifiable {
    let id = UUID()
    let name: String
    let value: ConfigValue
  }

  enum ConfigValue {
    case offset(Binding<CGSize>)
    case move(Binding<Edge>)
    case push(Binding<Edge>)
  }

  let id = UUID()
  let name: String
  let transition: AnyTransition
  let configs: [Config]
}

extension Edge: CaseIterable {
  public static var allCases: [Edge] {
    [.top, .bottom, .leading, .trailing]
  }

  var name: String {
    switch self {
    case .top: return "Top"
    case .bottom: return "Bottom"
    case .leading: return "Leading"
    case .trailing: return "Trailing"
    }
  }
}

struct BuildInTransitionView: View {
  @State private var showText = true
  @State private var transitions: [BuildInTransitionConfig] = []
  @State private var offset: CGSize = .init(width: 100, height: 100)
  @State private var moveEdge: Edge = .trailing
  @State private var pushEdge: Edge = .leading

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(transitions) { transition in
          GroupBox(transition.name) {
            VStack {
              buildConfigView(configs: transition.configs)

              if showText {
                Text(transition.name.localizedUppercase)
                  .font(.title)
                  .transition(transition.transition)
              } else {
                // There should be a placeholder here, and this text make the GroupBox keep its size.
                Text(" ")
                  .font(.title)
              }

              Button {
                showText.toggle()
              } label: {
                showText
                  ? Text("Hide")
                  : Text("Show")
              }
            }
          }
        }
      }
    }
    .animation(.linear, value: showText)
    .onChange(
      of: offset, initial: false,
      { oldValue, newValue in
        buildConfigs()
      }
    )
    .onChange(
      of: moveEdge, initial: false,
      { oldValue, newValue in
        buildConfigs()
      }
    )
    .onChange(
      of: pushEdge, initial: false,
      { oldValue, newValue in
        buildConfigs()
      }
    )
    .task {
      buildConfigs()
    }
  }

  func buildConfigView(configs: [BuildInTransitionConfig.Config]) -> some View {
    VStack {
      ForEach(configs) { config in
        switch config.value {
        case .offset(let offset):
          VStack {
            HStack {
              Text("X:")
                .frame(width: 20, alignment: .leading)
              // @dynamicMemberLookup is the "magic" that keeps SwiftUI code concise. It lets you treat a Binding as if it were the object it wraps,
              // automatically wrapping any property you access back into a Binding.
              Stepper(
                "\(Int(offset.wrappedValue.width))", value: offset.width, in: -500...500, step: 10)
            }
            HStack {
              Text("Y:")
                .frame(width: 20, alignment: .leading)
              Stepper(
                "\(Int(offset.wrappedValue.height))", value: offset.height, in: -500...500, step: 10
              )
            }
          }
        case .move(let edge):
          HStack {
            Text("Edge:")
            Picker("Edge", selection: edge) {
              ForEach(Edge.allCases, id: \.self) { edge in
                Text(edge.name).tag(edge)
              }
            }
            .pickerStyle(.segmented)
          }
        case .push(let edge):
          HStack {
            Text("Edge:")
            Picker("Edge", selection: edge) {
              ForEach(Edge.allCases, id: \.self) { edge in
                Text(edge.name).tag(edge)
              }
            }
            .pickerStyle(.segmented)
          }
        }
      }
    }
  }

  func buildConfigs() {
    transitions = [
      .init(name: ".opacity", transition: .opacity, configs: []),
      .init(name: ".scale", transition: .scale, configs: []),
      .init(name: ".slide", transition: .slide, configs: []),
      .init(
        name: ".blurReplace", transition: AnyTransition(BlurReplaceTransition.blurReplace),
        configs: []),
      .init(
        name: ".offset", transition: .offset(offset),
        configs: [
          BuildInTransitionConfig.Config(name: "Offset", value: .offset($offset))
        ]),
      .init(
        name: ".move", transition: .move(edge: moveEdge),
        configs: [
          BuildInTransitionConfig.Config(name: "Move", value: .move($moveEdge))
        ]),
      .init(
        name: ".push", transition: .push(from: pushEdge),
        configs: [
          BuildInTransitionConfig.Config(name: "Push", value: .push($pushEdge))
        ]),
    ]
  }
}

#Preview {
  NavigationStack {
    BuildInTransitionView()
  }
}
