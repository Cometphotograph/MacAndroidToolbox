#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# 軟體名稱與版本設定 (符合英文命名規範: MacAndroidToolbox + 版本號)
APP_NAME="MacAndroidToolbox"
APP_DISPLAY_NAME="麥安工具箱"

# 動態從 LanguageManager.swift 讀取版本號，若無則預設 1.1.1
VERSION_STR=$(grep 'public let appVersion' Sources/Services/LanguageManager.swift | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.1.1")
BUILD_STR=$(grep 'public let appBuild' Sources/Services/LanguageManager.swift | sed -E 's/.*"([^"]+)".*/\1/' || echo "20261007_111")
SHORT_VERSION=$(echo "$VERSION_STR" | sed 's/^v//')

# .app 檔案名使用純英文名: MacAndroidToolbox_v1.1.1.app
RELEASES_DIR="$DIR/releases"
mkdir -p "$RELEASES_DIR"
OUTPUT_BUNDLE_NAME="${APP_NAME}_${VERSION_STR}.app"
BUNDLE_DIR="$RELEASES_DIR/$OUTPUT_BUNDLE_NAME"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 正在使用 Swift 編譯 Release 版本 ($APP_NAME $VERSION_STR)..."
swift build -c release

echo "📦 建立 macOS 應用程式結構: $OUTPUT_BUNDLE_NAME"
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 複製二進位執行檔
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# 複製應用程式圖示 (若存在)
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# 複製資源檔案 (包含贊助收款碼圖片等)
if [ -d "$DIR/Resources" ]; then
    cp -R "$DIR/Resources/"* "$RESOURCES_DIR/" 2>/dev/null || true
fi

# 產生 Info.plist
cat << EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.macandroid.toolbox</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${SHORT_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_STR}</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 建立 releases/MacAndroidToolbox.app 軟連結以相容常用路徑
rm -rf "$RELEASES_DIR/${APP_NAME}.app"
ln -sf "$OUTPUT_BUNDLE_NAME" "$RELEASES_DIR/${APP_NAME}.app"

echo "✅ App 封裝完成: $BUNDLE_DIR"

# ==========================================
# 建立 DMG 光盤映像 (純英文名: MacAndroidToolbox_v1.2.0.dmg)
# ==========================================
OUTPUT_DMG_NAME="${APP_NAME}_${VERSION_STR}.dmg"
DMG_PATH="$RELEASES_DIR/$OUTPUT_DMG_NAME"
DMG_STAGING_DIR="$DIR/.build/dmg_staging_${VERSION_STR}"

echo "💿 正在打包 DMG 光盤映像: $OUTPUT_DMG_NAME ..."
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"

# 複製 .app 到暫存目錄，以標準「MacAndroidToolbox.app」命名以便拖曳安裝
cp -R "$BUNDLE_DIR" "$DMG_STAGING_DIR/${APP_NAME}.app"

# 建立 Applications 捷徑，使用者可直接拖曳安裝
ln -s /Applications "$DMG_STAGING_DIR/Applications"

# 若存在圖示，建立卷宗圖示
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$DMG_STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
fi

# 移除舊的 DMG
rm -f "$DMG_PATH"

# 使用 hdiutil 建立壓縮唯讀 DMG (UDZO)
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# 清理暫存目錄
rm -rf "$DMG_STAGING_DIR"

# 建立相容軟連結 releases/MacAndroidToolbox.dmg
rm -f "$RELEASES_DIR/${APP_NAME}.dmg"
ln -sf "$OUTPUT_DMG_NAME" "$RELEASES_DIR/${APP_NAME}.dmg"

echo ""
echo "🎉 全部打包完成！共生成 2 種英文命名封裝（存放於 releases/ 目錄）："
echo "  1️⃣  .app 應用程式目錄: $BUNDLE_DIR"
echo "  2️⃣  .dmg 安裝光盤映像: $DMG_PATH"
echo "👉 相容捷徑: $RELEASES_DIR/${APP_NAME}.app 及 $RELEASES_DIR/${APP_NAME}.dmg"
