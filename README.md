# Tecno LH8n LightBelt Backlight Service

A KernelSU-style root module that packages the **Backlight Effect** application and runs boot-time setup for the Tecno LH8n rear LightBelt LEDs, which use an AW22xxx controller.

The repository contains a prebuilt APK and shell scripts; it does not contain the Android app's source code. The module metadata describes the target as HyperOS. Device, firmware, kernel, and controller differences can affect whether the application and sysfs controls work.

> **Important security notice:** `post-fs-data.sh` runs `setenforce 0` during early boot. This switches Android SELinux to permissive mode system-wide, weakening an important security boundary. Review this behavior before installing. If you do not want SELinux permissive, remove that command from `post-fs-data.sh` before packaging/installing the module. LED access or app functionality may then be limited by your device's existing policy.

## Contents

| Path | Purpose |
| --- | --- |
| `module.prop` | Root-module ID, display name, version, author, and description. |
| `system/priv-app/LightBelt/LightBelt.apk` | Prebuilt Backlight Effect app, placed in a systemless privileged-app overlay. |
| `01_lh8n_sysfs.sh` | Early-boot daemon executed during class main. Powers on the AW22127 controller, reads cached startup animation parameters (`/data/local/tmp/lh8n_*`), plays the startup backlight during the Android boot animation, and transitions to charging/standby upon boot completion. |
| `customize.sh` | Installer hook. Sets file permissions, attempts an APK package-manager install, sets permissions on known LED sysfs paths, and attempts to enable the app's notification listener. |
| `service.sh` | Waits until Android reports boot complete, verifies that `01_lh8n_sysfs.sh` is active, and reapplies LED-node permissions and notification-listener access. |
| `post-fs-data.sh` | Early-boot hook that currently sets SELinux to permissive mode. |
| `action.sh` | KernelSU Next action script that runs a short LED test sequence. |
| `META-INF/com/google/android/update-binary` | Minimal recovery installer that extracts the module files under `/data/adb/modules/lh8n_lightbelt` and invokes `customize.sh`. |
| `META-INF/com/google/android/updater-script` | Installer marker. |
| `icon.png` | Module icon. |

## App and module details

- **Module ID:** `lh8n_lightbelt`
- **Module version:** `1.3.0` (version code `130`)
- **App package:** `com.transsion.lightbelt`
- **App label:** Backlight Effect
- **APK version:** `14` (version code `34`)
- **APK Android requirement:** minimum SDK 34, which corresponds to Android 14
- **App permissions declared in the APK:** `WRITE_SECURE_SETTINGS`, `VIBRATE`, `READ_PHONE_STATE`, and the app's own dynamic-receiver permission
- **Notification listener component used by the scripts:** `com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService`

The APK declares a notification-listener service and a Quick Settings tile service. The scripts request notification-listener access with Android's `cmd notification allow_listener` command. This does not guarantee that every Android/HyperOS release will accept the command or that all app features will work.

The module description mentions thermal protection. That behavior is part of the prebuilt application and cannot be inspected or changed from the shell scripts in this repository. Do not treat the description as a guarantee of hardware thermal protection.

## Requirements and compatibility

Before installing, check all of the following:

1. The device is a Tecno LH8n (or a device whose LED controller and sysfs interface are known to be compatible).
2. Android is version 14 or later, to satisfy the APK's minimum SDK requirement.
3. A supported root-module manager is installed and functioning. The scripts and packaging target KernelSU/KernelSU Next-style module layouts; the included recovery installer uses the same `/data/adb/modules` location.
4. The expected AW22xxx LED sysfs nodes exist on the device. The paths are hard-coded and may differ across kernels or firmware.
5. You understand the SELinux permissive behavior described above.

The installer suppresses errors for several privileged operations and continues if they fail. A successful module installation therefore does not by itself prove that the APK was registered, permissions were applied, or the LEDs are controllable.

## Installation

### Install with a root-module manager

1. Download or clone this repository, then create a module ZIP from the **contents** of the repository. `module.prop`, the shell scripts, `system/`, and `META-INF/` must be at the ZIP root, not inside an extra enclosing project directory.
2. Review `post-fs-data.sh`. Remove `setenforce 0` if you do not want the module to disable SELinux enforcement; save the change before creating the ZIP.
3. In KernelSU or KernelSU Next, choose the option to install a module from storage and select the ZIP.
4. Read the manager's installation output. Reboot when prompted so the boot hooks and systemless app overlay take effect.
5. After reboot, open **Backlight Effect** from the app drawer and check whether the app recognizes the device's lighting hardware.

The included recovery updater is a small custom extraction script, not a full-featured recovery installer. The recommended installation route for this project is the root-module manager.

### Installer operations

`customize.sh` performs these operations:

- Sets recursive ownership to `root:root`, directories to mode `0755`, and files to mode `0644`; then marks `service.sh` and `action.sh` executable (`0755`).
- Attempts `pm install -r -d` on the bundled APK. Output is discarded and failure is ignored, so this step can fail without stopping the installation.
- Attempts to set mode `0666` on files beneath the listed AW22xxx LED paths and `/sys/led/led/tran_led_cmd`.
- Attempts to grant notification-listener access to the app's background service.

`service.sh` waits in two-second intervals for `sys.boot_completed` to become `1`, then repeats the sysfs permission and listener-access operations. The script does not explicitly start the app's UI.

## Using the LED test action

If your manager exposes module actions, run the module's **Test LED Lightstrip** action. `action.sh` writes values to `/sys/class/leds/aw22xxx_led/` to enable the controller, select a current limit and effect/configuration, set brightness to `255`, wait three seconds, and then write `cfg=9` and `hwen=0`.


The action assumes that exact sysfs path and those controller values are valid for the device. It does not check whether each write succeeded, so its "completed successfully" message is printed even if a node is missing or a write fails. Do not use it on unrelated hardware. Stop the test if the LEDs, device, or controller behave unexpectedly.

## Sysfs paths used

The installer and boot service try to change permissions on these paths:

```text
/sys/class/leds/aw22xxx_led/*
/sys/devices/platform/11d21000.i2c/i2c-2/2-006a/*
/sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/*
/sys/devices/platform/11d02000.i2c/i2c-2/2-006a/*
/sys/led/led/tran_led_cmd
```

The action script writes specifically to:

```text
/sys/class/leds/aw22xxx_led/hwen
/sys/class/leds/aw22xxx_led/imax
/sys/class/leds/aw22xxx_led/brightness
/sys/class/leds/aw22xxx_led/effect
/sys/class/leds/aw22xxx_led/cfg
```

Missing paths are ignored by the permission scripts. Check the paths on your own device before diagnosing an LED-control problem.

## Troubleshooting

### The module installs, but the app is missing

- Confirm that `system/priv-app/LightBelt/LightBelt.apk` was present at that exact path in the ZIP.
- Check that the device runs Android 14 or newer; the APK declares minimum SDK 34.
- The package-manager install in `customize.sh` ignores errors. Review Android package-manager logs or try installing the APK manually to see the actual error. The script's attempt is not proof of a successful install.
- Verify whether the module is enabled and whether the systemless overlay was mounted after reboot.

### The app opens, but the LEDs do not respond

- Confirm that the device exposes `/sys/class/leds/aw22xxx_led/` and the expected nodes (`hwen`, `imax`, `brightness`, `effect`, and `cfg`).
- Check whether your kernel or firmware uses a different I2C address or sysfs layout. The module does not discover alternate paths.
- Run the test action only on compatible hardware and inspect root/kernel logs for denied or failed writes.
- Permission changes may be reset by the kernel or another boot service. `service.sh` reapplies them once after Android reports boot complete, but it does not monitor for later resets.

### Notification-based features do not work

- Confirm that the app's notification-listener component is enabled in Android's notification access settings.
- The module attempts to grant access at install time and again after boot, but ignores command failures. Menu names and command behavior vary by Android/HyperOS release.

### The device's security state changes

`post-fs-data.sh` calls `setenforce 0`, which requests permissive SELinux mode on every boot while the module is active. Disable the module or remove that command and reinstall/reboot if you want SELinux enforcement restored. Confirm the resulting SELinux state on the device; other modules or firmware policies can also affect it.

## Uninstallation

1. Disable or uninstall `lh8n_lightbelt` in KernelSU/KernelSU Next (or the manager used to install it).
2. Reboot so the systemless overlay and boot scripts are no longer active. Rebooting also allows the device's normal SELinux boot policy to take effect again.
3. If **Backlight Effect** remains installed after module removal, check the package list and uninstall `com.transsion.lightbelt` through Android settings or with a package-manager command appropriate for your device. The module's `pm install` attempt may register the APK separately from the systemless overlay.

## Building a module ZIP

No build toolchain is required: the APK is already included. To package the module, zip the repository contents while preserving the directory structure and placing `module.prop` at the ZIP root. Do not put the project folder itself as the only top-level entry. Keep executable bits on `customize.sh`, `service.sh`, `post-fs-data.sh`, and `action.sh` when the packaging tool supports Unix permissions; the installer explicitly sets executable permissions for `service.sh` and `action.sh`.

## Known Issues / Bugs

- None currently known. (Previous Low Battery color mismatch resolved by redesigning customization screens with 14 full-palette hardware animation presets and removing non-functional userspace RGB overrides).

## Release Notes (v1.2.4)

### What's New
- **Startup Cache Resolution Fix (`01_lh8n_sysfs.sh`)**: Reads `global tran_led_startup_cmd` directly before falling back to the corrected `0..5` index lookup (`0=Dreamy Illusion`, `1=Racing`, `2=Soft Wave`, `3=Breathing Pulse`, `4=Party Rhythm`, `5=Off`).
- **Updated LightBelt APK (`v1.2.4`)**:
  - Added explicit preview loop delays (`2500/4000/8700/2000/3000 ms`) across continuous/wave styles (`game.json`, `calling.json`, `startup.json`, `music_pure.json`, `music_party.json`).
  - Restarts `mLottieView` cleanly per preview cycle and sets `music_party.json` playback speed to `0.5f`.
  - Marks `CustomEffectActivity` as `android:exported="true"`.

## Release Notes (v1.2.2)

### What's New
- **Startup Backlight Customizer with Dedicated SAVE Buttons**:
  - Added prominent, highly visible **SAVE** buttons (top-bar pill `#007AFF` and bottom full-width button) in `CustomEffectActivity` for Startup Backlight, Charging, and Low Battery.
  - Tapping SAVE immediately persists user choices, synchronizes early-boot cache files (`/data/local/tmp/lh8n_startup_cmd`, `/data/local/tmp/lh8n_imax`, `/data/local/tmp/lh8n_master`), displays toast confirmation (`✓ <Preset> saved!`), and cleanly exits to `HomeActivity`.
- **Permanent Fix for Boot Backlight Failing After Changing Settings**:
  - Identified root cause in stock `SelectTypeActivity` where button tags were scrambled (e.g. Racing button was tagged with index `0`, Dreamy with `5`, and None/Off with `4`). Storing index `0` caused early boot to treat it as "Turn Off / None", disabling the backlight during reboot!
  - Replaced ambiguous integer indices with raw microcode hex strings stored in `tran_led_startup_cmd` (e.g., `00 31 02 00 00 00` for Racing).
  - Wired `HomeActivity`'s Startup item directly into `CustomEffectActivity(type="startup")`, providing all 14 preset options, real-time Lottie previews, hardware brightness slider, and live dynamic subtitle updates on the Home screen.
  - Corrected legacy integer fallback mapping in `01_lh8n_sysfs.sh`: `0` = Dreamy Illusion, `1` = Racing, `2` = Soft Wave, `3` = Breathing Pulse, `4` = Party Rhythm, `5` = None/Off.

## Release Notes (v1.2.1)

### What's New
- **Early-Boot Startup Backlight Animation Engine**:
  - Fixed startup backlight failing to illuminate during device boot on HyperOS 3.0 / AOSP custom ROMs (where stock HiOS framework services are absent).
  - Implemented standalone early-boot service in `01_lh8n_sysfs.sh` reading cached startup microcode (`/data/local/tmp/lh8n_startup_cmd`), current limit (`/data/local/tmp/lh8n_imax`), and master switch (`/data/local/tmp/lh8n_master`).
  - Initiates the chosen backlight effect at early boot ($t \approx 31\text{s}$ during Android bootanimation), waits for `sys.boot_completed == 1`, holds for 4 seconds, and seamlessly transitions to charging animation or standby.
  - Cleaned up `service.sh` by removing conflicting daemon kill signals and premature standby commands, ensuring seamless handoff to the live background service.
- **Full 14-Effect Palette for Charging & Low Battery**:
  - Expanded both Charging Light Effect and Low Battery Warning to support all 14 native animation effects: Dynamic Flow 1 & 2, Racing (Speed), Warning Blink, Soft Wave, Dreamy Illusion, Breathing Pulse, Party Rhythm, Pure Flash, Starburst, Halo, Lightning, Sunrise, and Solid Glow.
- **Built-in On-Screen Lottie Light Preview**:
  - Replaced the standalone preview button with a native in-app preview container at the top of the screen (`back_light_bg` phone graphic + real-time looping `LottieAnimationView`), perfectly mimicking the stock app experience.
  - Selecting any preset updates the on-screen Lottie preview and immediately plays the physical hardware LED in synchronized real time.
- **Color Selection Cleanup**:
  - Removed all ineffective LED color picker cards and radio buttons across Charging and Low Battery menus.
  - Streamlined Home UI summaries to `Style • Duration` (e.g. `Dynamic Flow 1 • Always`, `Warning Blink • 5 Seconds`).
- **1:1 Frame-Accurate Notification Preview Sync**:
  - Re-synchronized the notification preview loop cadence from 1400ms to **2867 ms** (`0xb33`), precisely matching the 172-frame / 60 fps duration of the stock Lottie preview assets (`animation_startriver`, `animation_lightning`, `animation_pureness`, `animation_rise`, `animation_halo`).
  - Physical LED double-flash pulses now lock into permanent frame-level synchrony with the on-screen animation without drifting.
- **Dynamic Racing Animation Upgrade & Continuous Loop Engine**:
  - Re-mapped the `"Racing"` preset (`command_speed`) from frozen static cyan microcode (`00 30 01 00 00 00` / `lamp1_static_game_02.bin`) to the native dynamic racing animation (`00 31 02 00 00 00` / `lamp1_game_PUBG_03_drive.bin`).
  - Added an automated software repeating engine (`Utils.getPreviewLoopDelay` at **5000 ms** / `0x1388`) perfectly synchronized with the 300-frame @ 60fps duration of `game.json`. Racing sweeps continuously without shutting off after the first cycle, while continuous hardware microcodes (Soft, Dreamy, Breathe, Party) loop naturally without software interrupts.
- **Sysfs Directory Traversal Hardening**:
  - Enforced strict `0755` permissions on `/sys/devices/platform/11d21000.i2c/i2c-2/2-006a` and applied `chown -R system:system` across all boot scripts to prevent permission denial bugs for the `system` user.

## Release Notes (v1.2.0)

### What's New
- **Zero-Delay Command Execution**: Eliminated the artificial 100ms UI debounce, redundant 20ms wake sleep cycles, and 256-read I2C `/reg` sysfs dumps. Command latency reduced from ~170ms down to 3ms.
- **Cold Boot Recovery**: Added automated hardware register awakening in `service.sh` and userspace self-healing (`brightness=180` boot trigger) to permanently fix LEDs failing to illuminate after reboot.
- **Configurable Backlight Durations**:
  - **Charging Light**: Always (Continuous), 15s, 30s, 1m, 5m, 10m.
  - **Low Battery Alert**: 5s, 15s, 30s, 1m, 5m, Always (Continuous).
- **Home UI Duration Summaries & Quick Picker**: Subtitles dynamically reflect `Style • Color • Duration`, and long-pressing either row directly in `HomeActivity` opens a quick-selection dialog.
- **Notification Palette Alignment**: Corrected color values to match stock Lottie assets (Halo pure white `#ffffff`, Starburst azure `#3f8dff`, Pure emerald `#009e2b`).

## Project scope

This repository packages and configures the application; it does not include source code for the APK, kernel drivers, AW22xxx firmware, or an automatic device-compatibility detector. For changes to app behavior, obtain and maintain the app source separately. For changes to the hardware interface, confirm the target kernel's sysfs nodes and expected values first.
