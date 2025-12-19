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

extension Edge {
    var strValue: String {
        switch self {
        case .bottom: return ".bottom"
        case .leading: return ".leading"
        case .top: return ".top"
        case .trailing: return ".trailing"
        }
    }
    
    static func strToEdge(string: String) -> Edge {
        switch string {
        case ".bottom": return .bottom
        case ".leading": return .leading
        case ".top": return .top
        case ".trailing": return .trailing
        default:
            return .trailing
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
        .toolbar {
            // Trailing (Right) side
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ZoomableScrollView {
                        Image(.buildInTransitionView)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                } label: {
                    Image(systemName: "keyboard")
                }
            }
        }
        .onChange(of: offset, initial: false, { oldValue, newValue in
            buildConfigs()
        })
        .onChange(of: moveEdge, initial: false, { oldValue, newValue in
            buildConfigs()
        })
        .onChange(of: pushEdge, initial: false, { oldValue, newValue in
            buildConfigs()
        })
        .task {
            buildConfigs()
        }
    }
    
    func buildConfigView(configs: [BuildInTransitionConfig.Config]) -> some View {
        VStack {
            ForEach(configs) { config in
                switch config.value {
                case .offset(let offset):
                    HStack {
                        Text("x")
                        TextField("x", text: .init(get: {
                            "\(offset.wrappedValue.width)"
                        }, set: { value in
                            offset.wrappedValue.width = CGFloat(Double(value) ?? 0)
                        }))
                        .textFieldStyle(.roundedBorder)
                        
                        Text("y")
                        TextField("y", text: .init(get: {
                            "\(offset.wrappedValue.height)"
                        }, set: { value in
                            offset.wrappedValue.height = CGFloat(Double(value) ?? 0)
                        }))
                        .textFieldStyle(.roundedBorder)
                    }
                case .move(let edge):
                    HStack {
                        Text("edge")
                        TextField("edge", text: .init(get: {
                            "\(edge.wrappedValue.strValue)"
                        }, set: { value in
                            edge.wrappedValue = Edge.strToEdge(string: value)
                        }))
                        .textFieldStyle(.roundedBorder)
                    }
                case .push(let edge):
                    HStack {
                        Text("edge")
                        TextField("edge", text: .init(get: {
                            "\(edge.wrappedValue.strValue)"
                        }, set: { value in
                            edge.wrappedValue = Edge.strToEdge(string: value)
                        }))
                        .textFieldStyle(.roundedBorder)
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
            .init(name: ".blurReplace", transition: AnyTransition(BlurReplaceTransition.blurReplace), configs: []),
            .init(name: ".offset", transition: .offset(offset), configs: [
                BuildInTransitionConfig.Config(name: "Offset", value: .offset($offset))
            ]),
            .init(name: ".move", transition: .move(edge: moveEdge), configs: [
                BuildInTransitionConfig.Config(name: "Move", value: .move($moveEdge))
            ]),
            .init(name: ".push", transition: .push(from: pushEdge), configs: [
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
