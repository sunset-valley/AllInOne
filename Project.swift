import ProjectDescription

let project = Project(
  name: "AllInOneiOS",
  targets: [
    .target(
      name: "AllInOneiOS",
      destinations: .iOS,
      product: .app,
      bundleId: "dev.tuist.AllInOneiOS",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ]
        ]
      ),
      buildableFolders: [
        "AllInOneiOS/Sources",
        "AllInOneiOS/Resources",
      ],
      scripts: [
        .post(
          script: """
            # Copy Features source files to bundle resources
            SOURCE_DIR="${SRCROOT}/AllInOneiOS/Sources/Features"
            DEST_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/FeatureSources"

            rm -rf "$DEST_DIR"
            mkdir -p "$DEST_DIR"

            # Copy only .swift files while preserving directory structure
            cd "$SOURCE_DIR"
            find . -name "*.swift" -type f | while read file; do
                mkdir -p "$DEST_DIR/$(dirname "$file")"
                cp "$file" "$DEST_DIR/$file"
            done
            """,
          name: "Copy Feature Sources",
          basedOnDependencyAnalysis: false
        )
      ],
      dependencies: []
    ),
    .target(
      name: "AllInOneiOSTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "dev.tuist.AllInOneiOSTests",
      infoPlist: .default,
      buildableFolders: [
        "AllInOneiOS/Tests"
      ],
      dependencies: [.target(name: "AllInOneiOS")]
    ),
  ]
)
