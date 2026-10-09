# MacAndroidToolbox

**English** | [简体中文](README.md)

[![Version](https://img.shields.io/badge/Version-v1.4.1-blue.svg?style=flat)](https://github.com/Cometphotograph/MacAndroidToolbox)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2026%2B-blue.svg?style=flat&logo=apple)](https://www.apple.com/macos)
[![Arch](https://img.shields.io/badge/Arch-Apple%20Silicon%20(arm64)-purple.svg)](https://apple.com)
[![Author](https://img.shields.io/badge/Author-bilibili%40EchoIM__-pink.svg?style=flat&logo=bilibili)](https://space.bilibili.com/432147890?spm_id_from=333.337.0.0)
[![Email](https://img.shields.io/badge/Email-magicalgirlkrea%40gmail.com-blue.svg?style=flat&logo=gmail)](mailto:magicalgirlkrea@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717.svg?style=flat&logo=github)](https://github.com/Cometphotograph/MacAndroidToolbox)
[![Design](https://img.shields.io/badge/Design-Liquid%20Glass-purple.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern native Android flashing and debugging graphical toolbox tailored for **macOS**. Developed natively with **Swift 6** and **SwiftUI**, it adopts the **Liquid Glass** skeuomorphic design language, strictly adhering to Apple's Human Interface Guidelines (HIG) with multi-layered depth, frosted glass materials, fluid light gradients, and smooth responsiveness.

<p align="center">
  <img src="docs/images/preview.jpg" alt="MacAndroidToolbox Preview" width="850">
</p>

---

## ⚠️ Important Notices & Safety Warnings

> [!CAUTION]
> ### 1. Open Source & Resale Strictly Prohibited
> **This software is completely open-source and released free of charge. Reselling, commercial distribution, paid bundling, or charging for this software in any form is strictly prohibited!**  
> If you acquired this software through any paid channel, please demand an immediate refund and report the seller to the respective platform.

> [!WARNING]
> ### 2. Flashing & Low-Level Modification Disclaimer
> Flashing firmware, unlocking the Bootloader, gaining Root privileges, wiping/writing partitions, and executing system-level debugging carry inherent risks. These actions may result in soft or hard bricking (device unable to boot), permanent data loss, voided manufacturer warranties, or compromised hardware security features.  
> **Always back up all important personal data before executing any flashing or modification procedures.**  
> Neither this software nor its developers shall be held liable for any direct or indirect damages resulting from improper operation, hardware discrepancies, or third-party custom ROM incompatibilities.

> [!IMPORTANT]
> ### 3. Recommendation: Prioritize Official Bootloader Unlocking
> It is strongly recommended to prioritize official, authorized manufacturer channels when unlocking the Bootloader (especially on devices running heavily customized OEM skins such as Xiaomi HyperOS, OPPO ColorOS, vivo OriginOS, or Meizu Flyme).  
> Attempting to bypass Bootloader locks via unofficial exploits or brute-force methods frequently causes CPU e-fuse anomalies, permanent hardware TEE/fingerprint module corruption, baseband loss, or motherboard failure.

---

## ✨ Core Feature Modules

### 📱 1. Device Dashboard & Status Overview (Dashboard)
* **Intelligent Mode Detection**: Automatically detects device connection states in real time (ADB Normal mode, Fastboot mode, FastbootD userspace partition mode, Recovery mode, Sideload mode, Qualcomm 9008 mode, and Unauthorized state).
* **Comprehensive Hardware & Software Specs**: Brand, model, codename, Android OS version, SDK API level, and security patch date.
* **Live Hardware Sensors**: Battery remaining percentage, real-time temperature (°C), and charging/discharging state.
* **Intelligent SoC Platform Recognition**: Automatically detects and maps chipset hardware platforms (Qualcomm Snapdragon, MediaTek Dimensity, Google Tensor, Samsung Exynos, Huawei Kirin, Unisoc, etc.) with commercial marketing names and chip codenames.
* **Root Privilege Detection**: Probes for root frameworks (Magisk / KernelSU / APatch / SU).
* **Quick Reboot Panel**: Reboot System, Reboot to Bootloader/Fastboot, Reboot to Recovery, and Reboot to FastbootD.
* **Wireless ADB Setup Wizard**: One-click opening of TCP/IP port 5555 to debug without cables via IP and port.

---

### ⚡️ 2. Fastboot Flasher & Partition Management (Fastboot Flasher)
* **One-Click Partition Flashing**:
  - Core partitions supported: `boot`, `init_boot` (essential for Android 13+ architectures), `recovery`, `vbmeta`, `vendor_boot`, `system`, `vendor`, `super`, `dtbo`, etc.
  - Custom partition name input support.
  - **AVB Verification Disabling**: One-click `--disable-verity --disable-verification` flag for `vbmeta`.
  - Drag-and-drop support for `.img` and `.bin` image files or selection via native file dialog.
* **Temporary Image Booting (Fastboot Boot)**:
  - Run `fastboot boot <image>` to test TWRP, OrangeFox, or Magisk-patched kernels in memory without modifying persistent storage.
* **Seamless A/B Slot Switching**:
  - Instantly inspects active slot (Slot A or Slot B) with one-click slot toggling.
* **Bootloader Lock & Unlock**:
  - Supports modern standard unlock protocol (`flashing unlock`), critical partition unlock (`flashing unlock_critical`), legacy unlock (`oem unlock`), and OEM re-locking (`flashing lock` / `oem lock`).
  - Built-in secondary safety confirmation dialogs to prevent accidental locks.
* **Partition Formatting & Erasing**:
  - Format or wipe `userdata`, `cache`, and `metadata` partitions to unbrick devices.
* **Fastboot Variable Inspector**:
  - Retrieve the full parameter list from `fastboot getvar all` with live keyword filtering and search.

---

### 🧯 3. Qualcomm 9008 Emergency Flasher (Qualcomm EDL 9008)
* **USB Hardware 9008 Mode Auto-Detection**: Uses macOS low-level IOKit to rapidly detect Qualcomm devices in Emergency Download mode (VID `0x05c6` PID `0x9008` / `0x900e`).
* **Built-in 192 Firehose Loader Library**:
  - Comprehensive collection across 8 major phone brands: **Xiaomi, OPlus (OPPO/OnePlus/Realme), Meizu, Black Shark, Nubia (RedMagic/ZTE), Lenovo (Legion/Moto), ASUS (ROG), and LG**.
  - Supports chipsets from Snapdragon 625/835 to Snapdragon 8 Gen 1/2/3/4 and Snapdragon 8 Elite with automated auth signature matching (`Digest.elf` and `Sign.bin`).
* **One-Click "Send Loader (Sahara Handshake)"**:
  - Instantly uploads the Firehose programmer into device memory via Sahara protocol to establish communication.
  - Includes troubleshooting hints (alternative programmer switching, power-cycle port reset, and signature exclusion).
* **QFIL Emulation Full Firmware Flashing**:
  - Full support for Qualcomm factory `rawprogram*.xml` partition mappings and `patch*.xml` sector patches.
  - Supports modern UFS and eMMC storage types with automated firmware folder matching.
* **Single Partition Read, Write & Erase**:
  - Directly write images into individual physical partitions (`boot`, `init_boot`, `recovery`, `vbmeta`, `modem`, `abl`, `xbl`, `super`, `persist`, etc.).
  - Dump / backup any physical partition directly from flash memory.
  - Securely erase corrupted partitions.
* **GPT Physical Partition Table Explorer (Print GPT)**:
  - Directly reads partition layouts from hardware flash memory, displaying partition names, start/end LBAs, and sizes with live keyword search.
* **One-Click Exit 9008 / Reboot Device**: Sends hardware reset command (`edl reset`) to safely reboot the device.
* **Environment Diagnostics & Unbricking Guide**:
  - Automatic diagnostics for Python 3, `libusb`, and `edl` toolsuite, with one-click dependency installer.
  - Comprehensive guide covering key combinations, CLI commands, EDL deep flash cables, and motherboard Test Points.

---

### 📦 4. App Manager & APK Deployment (App Manager)
* **Categorized App List & Instant Search**: Filter by All, Third-party User Apps, or System Built-in Apps with real-time package name searching.
* **Multi-Format APK Installation**: Drag and drop `.apk`, `.apks`, or `.xapk` packages for silent background installation.
* **Comprehensive App Operations**: Launch app, force stop, clear app data/cache, uninstall, and disable/freeze system apps.
* **APK Extraction & Export**: Extract any installed app's APK directly to your Mac.

---

### 📁 5. File Manager & Recovery Sideload (Files & Sideload)
* **Remote Device File Explorer**: Browse Android internal storage (`/sdcard/Download`, DCIM, Documents, etc.) with file size and timestamp inspection.
* **Bidirectional File Transfers**:
  - **Push**: Send Mac files directly to any destination on the device.
  - **Pull**: Download files from device storage to your Mac.
* **Recovery Sideload Flashing**:
  - Flash official OTA update packages, full ROM zips, or Magisk / KernelSU / APatch zips via `adb sideload` in Recovery mode with live progress percentage monitoring.

---

### 💻 6. Shell Terminal & System Tweaks (Shell & Tweaks)
* **Interactive ADB Shell Console**: Integrated shell terminal to run Android commands with auto-scrolling, output clearing, and copying.
* **Handy System Tweaks**:
  - Open hidden native developer settings and System UI Tuner.
  - Adjust window, transition, and animator duration scales (0.5x, 1.0x, or Disabled).
  - Disable thermal throttling configurations for sustained performance testing in games.
  - Force global high refresh rates on supported devices.

---

### 🔰 7. Onboarding Wizard & Environment Auto-Configuration (Onboarding)
* **Automatic Dependency Detection**: Verifies presence of `adb`, `fastboot`, `edl`, and Homebrew on the host system.
* **One-Click Homebrew Installation**: Automatically installs `android-platform-tools` via Homebrew when tools are missing, streaming live terminal installation logs.
* **Browser Links & Manual Commands**: One-click link to the official Homebrew portal (`brew.sh`) or command clipboard copying.
* Re-accessible anytime in Settings.

---

### 🎨 8. Modern Appearance & Theme Adaptability (Appearance Themes)
* **Three Theme Modes**:
  - Light Mode
  - Dark Mode
  - Follow System
* **Real-time System Synchronization**: Listens to macOS `AppleInterfaceThemeChangedNotification` to smoothly adapt in real time as the system shifts between light and dark without restarting.

---

### 🌐 9. Internationalization & Supported Languages (Supported Languages)

MacAndroidToolbox includes a comprehensive built-in internationalization architecture, allowing immediate language changes across the entire interface without restarting the app. The following languages are currently supported:

* 繁體中文 (Traditional Chinese)
* 简体中文 (Simplified Chinese)
* English
* Français (French)
* 日本語 (Japanese)
* Español (Spanish)
* 한국어 (Korean)
* Русский (Russian)
* Українська (Ukrainian)

---

## 🖥️ Platform & System Requirements

### Runtime Requirements
1. **Operating System**: macOS 26.0 or newer.
2. **Architecture**: Apple Silicon native only (arm64, M1 / M2 / M3 / M4 / M5 and newer M-series chips). Intel (x86_64) processors are not supported.
3. **Android Platform Tools**:
   - Google `adb` and `fastboot` utilities.
   - Install automatically via the in-app installer or via Homebrew in Terminal:
     ```bash
     brew install --cask android-platform-tools
     ```
   - Custom binary paths can also be configured manually under Settings -> Tool Paths.

### Build Requirements (For Developers)
- macOS 26.0+
- Swift 6.0+
- Command Line Tools or Xcode:
  ```bash
  xcode-select --install
  ```

---

## 📥 Download & Installation

### Option 1: 💿 DMG Disk Image (Recommended)
1. Download `MacAndroidToolbox_v1.4.0.dmg` from the [Releases](../../releases) page.
2. Double-click to mount the DMG.
3. Drag `MacAndroidToolbox.app` into the `Applications` shortcut folder.

### Option 2: 🛠️ Build from Source
```bash
# 1. Clone the repository
git clone https://github.com/Cometphotograph/MacAndroidToolbox.git
cd MacAndroidToolbox

# 2. Run automated release build (outputs .app and .dmg to releases/ folder)
./build_app.sh

# 3. Launch the built application
open "releases/MacAndroidToolbox_v1.4.0.app"
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE). All code is freely available in compliance with open-source standards.
