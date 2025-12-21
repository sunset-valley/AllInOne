import SwiftUI

struct HighlightSwiftViewExample: View {
    @State var colors: CodeTextColors = .theme(.xcode)
    @State var font: Font = .body

    let code: String = """
      import SwiftUI

      struct SwiftUIView: View {
          var body: some View {
              Text("Hello World!")
          }
      }
      """

    var body: some View {
      List {
        CodeText(code)
          .codeTextStyle(.card)
          .codeTextColors(colors)
          .highlightLanguage(.swift)
          .font(font)
        Button {
          withAnimation {
            colors = .theme(randomTheme())
            font = randomFont()
          }
        } label: {
          Text("Random")
        }
      }
    }

    func randomTheme() -> HighlightTheme {
      let cases = HighlightTheme.allCases
      return cases[.random(in: 0..<cases.count)]
    }

    func randomFont() -> Font {
      let cases: [Font] = [
        .body,
        .callout,
        .caption,
        .caption2,
        .footnote,
        .headline,
        .largeTitle,
        .subheadline,
        .title,
      ]
      return cases[.random(in: 0..<cases.count)]
    }
}

#Preview {
  HighlightSwiftViewExample()
}
