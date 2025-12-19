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
                    ],
                ]
            ),
            buildableFolders: [
                "AllInOneiOS/Sources",
                "AllInOneiOS/Resources",
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
