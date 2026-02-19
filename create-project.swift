// 这个脚本可以帮你生成Xcode项目
// 在终端运行: swift create-project.swift

import Foundation

let packagePath = "Package.swift"
let projectName = "SchulteGrid"

print("正在生成Xcode项目...")

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
task.arguments = ["swift", "package", "generate-xcodeproj", "--output", "\(projectName).xcodeproj"]

do {
    try task.run()
    task.waitUntilExit()
    print("✅ Xcode项目已生成: \(projectName).xcodeproj")
    print("\n接下来请按以下步骤操作:")
    print("1. 打开 \(projectName).xcodeproj")
    print("2. 选择SchulteApp target")
    print("3. 在General标签页中找到App Icons and Launch Images")
    print("4. 点击Asset Catalog的箭头或创建新的Asset Catalog")
    print("5. 在Asset Catalog中添加AppIcon并拖拽你的icon图片")
} catch {
    print("❌ 生成项目失败: \(error)")
}
