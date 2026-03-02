# Platina Klipper Panel 🚀

Technical solution for Klipper monitoring via Android connected through an ADB data tunnel (USB). This configuration eliminates latency and ensures the screen functions as a high-performance native panel.

## 📍 Table of Contents
* [Overview](#-overview)
* [Technical Highlights](#-technical-highlights)
* [Critical Requirement: USB Connection](#-critical-requirement-usb-connection)
* [Installation Step-by-Step](#-installation-step-by-step)
* [Android Finalization](#-android-finalization)
* [Moonraker Configuration (Update Manager)](#️-moonraker-configuration-update-manager)
* [File Structure](#-file-structure)
* [License](#-license)

---

## 🔍 Overview
The project utilizes the USB bus to transmit VNC data directly to the Android device. This avoids Wi-Fi drops and allows the Host (Orange Pi/SBC) to automatically control the phone's screen state and brightness.

## 🛠 Technical Highlights
* **Zero Latency:** Direct TCP tunneling via USB cable.
* **Screen Automation:** The system detects the connection and launches the interface automatically.
* **Panel Preservation:** Brightness control logic and sleep mode to prevent screen burn-in.

## 🔌 Critical Requirement: USB Connection
> **IMPORTANT:** The Android device must be connected to the Host via USB during the installation process.

**Why is this necessary?** The installation script uses the ADB protocol to "push" the automation macro and the brightness control script directly to the phone's internal memory (`Download` folder). Without a physical connection and active USB Debugging, the installer will configure the Linux system but will fail to prepare the phone for use.

## 💻 Installation Step-by-Step
Follow the instructions below to configure your panel. Each command must be executed sequentially in your Host's terminal.

### 1. Clone the Repository
Download the necessary files to your scripts directory:
```bash
git clone [https://github.com/VicthorHW/platina-klipper-panel.git](https://github.com/VicthorHW/platina-klipper-panel.git) ~/scripts_vnc
```

### 2. Assign Execution Permissions
Make the master installer executable so it can perform system changes:
```bash
cd ~/scripts_vnc && chmod +x install.sh
```

### 3. Run the Master Installation
Ensure the phone is plugged in. The command below will configure the USB detection rules and send the automation files to the Android device:
```bash
./install.sh
```

## 📱 Android Finalization
After the script finishes on the Host, the files will already be on your phone. Follow these steps to activate the automation:

1. Open the **MacroDroid** app.
2. Tap the **Import/Export** option and select **Import**.
3. Navigate to your phone's `Download` folder.
4. Select the `MacroDroid_Macros.mdr` file.
5. The imported macro will use the `ligar_vnc.sh` script (also sent to the `Download` folder) to manage the connection and brightness automatically.

## ⚙️ Moonraker Configuration (Update Manager)
To allow updates for this panel directly through the Mainsail or Fluidd interface, add the following block to your `moonraker.conf` file:

```ini
[update_manager setup_android_vnc]
type: git_repo
path: ~/scripts_vnc
origin: [https://github.com/VicthorHW/platina-klipper-panel.git](https://github.com/VicthorHW/platina-klipper-panel.git)
primary_branch: main
managed_services: klipper
```

## 📂 File Structure

| File | Technical Function |
| :--- | :--- |
| `install.sh` | Unified installer (Configures Host and transfers files to Android). |
| `setup_adb_forward.sh` | Maintains the active TCP tunnel over the Host's USB bus. |
| `99-android-adb.rules` | UDEV rule for automatic Android device detection. |
| `ligar_vnc.sh` | Brightness control and screen protection script (runs on Android). |
| `MacroDroid_Macros/` | Folder containing the macro ready for MacroDroid import. |

## 📄 License
Distributed under the MIT License. Feel free to modify and distribute.