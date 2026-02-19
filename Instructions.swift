// 请按照以下步骤操作：

/*
 1. 准备你的icon图片，需要以下尺寸（iOS为例）：
    - 1024x1024 (App Store)
    - 60x60 @2x, @3x (iPhone)
    - 76x76 @1x, @2x (iPad)
    - 83.5x83.5 @2x (iPad Pro)
    - 等等...
    
 2. 创建Assets.xcassets文件夹结构：
    SchulteGrid/
    ├── Assets.xcassets
    │   ├── AppIcon.appiconset
    │   │   ├── Contents.json
    │   │   ├── 1024.png
    │   │   ├── 60@2x.png
    │   │   └── ... (其他尺寸)
    │   └── Contents.json
 */

// 这是AppIcon.appiconset/Contents.json的内容示例
let appIconContentsJSON = """
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
