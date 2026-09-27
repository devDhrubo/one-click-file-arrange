# ⚡ Desktop & Folder File Organizer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6.svg)](https://microsoft.com/windows)
[![Author](https://img.shields.io/badge/Developer-Dolan%20Dhrubo%20Ray-blue.svg)](https://github.com/devDhrubo)
[![GitHub stars](https://img.shields.io/github/stars/devDhrubo/one-click-file-arrange?style=social)](https://github.com/devDhrubo/one-click-file-arrange)

A modern, fast, and safe open-source Windows Desktop Application to organize messy Desktops and folders into categorized subfolders with **1 click**.

**Developed by [Dolan Dhrubo Ray](https://github.com/devDhrubo)**

---

## ✨ Features

- ⚡ **1-Click Instant Organizing**: Sorts hundreds of loose files in under 1 second.
- 📸 **Smart Screenshot Detection**: Automatically identifies Windows Snip / Screenshots and isolates them from ordinary photos.
- 🎨 **Modern Dark UI**: Beautiful dashboard with live category badges and interactive table preview.
- 🛡️ **Safety First**:
  - **Preserves Desktop Shortcuts (`.lnk`, `.url`)**: Keeps your pinned app icons intact.
  - **No Overwriting**: Automatically renames duplicate filenames (e.g. `document (1).pdf`).
  - **1-Click Undo / Rollback**: Revert any organization instantly.
  - **Zero Junk Files**: Keeps history logs silently inside Windows Local AppData.
- 📦 **Zero Dependencies**: Lightweight standalone portable executable (`.exe`). No installation required!

---

## 📥 Download & Usage

1. Go to the **[Releases Page](https://github.com/devDhrubo/one-click-file-arrange/releases)**.
2. Download **`FileOrganizer.exe`** (or `FileOrganizer-Portable.zip`).
3. Run `FileOrganizer.exe` ➔ Select your target folder (or click **🖥️ Desktop**) ➔ Click **⚡ Organize Now**.

---

## 📁 Automatic Category Breakdown

| Category | Extensions & Patterns |
| :--- | :--- |
| 📸 **Screenshots** | `*Screenshot*`, `*Screen Shot*`, `*Snip*`, `*Capture*` (`.png`, `.jpg`, `.jpeg`, `.bmp`, `.webp`) |
| 📄 **PDFs & Documents** | `.pdf`, `.docx`, `.doc`, `.txt`, `.rtf`, `.odt`, `.xlsx`, `.xls`, `.csv`, `.pptx`, `.ppt`, `.epub`, `.md`, `.xopp` |
| 🖼️ **Images & Photos** | `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.bmp`, `.ico`, `.tiff`, `.heic`, `.psd`, `.ai`, `.avif` |
| 🎥 **Videos** | `.mp4`, `.mkv`, `.mov`, `.avi`, `.wmv`, `.flv`, `.webm`, `.m4v`, `.3gp`, `.ts`, `.mpg` |
| 🎵 **Audio & Music** | `.mp3`, `.wav`, `.aac`, `.flac`, `.ogg`, `.m4a`, `.wma`, `.opus`, `.mid` |
| 📦 **Archives & Compressed** | `.zip`, `.rar`, `.7z`, `.tar`, `.gz`, `.bz2`, `.xz`, `.iso` |
| ⚙️ **Installers & Executables** | `.exe`, `.msi`, `.msix`, `.appx`, `.reg` |
| 💻 **Code & Development** | `.py`, `.js`, `.ts`, `.html`, `.css`, `.json`, `.xml`, `.yaml`, `.sql`, `.cpp`, `.cs`, `.java`, `.bat` |
| 📁 **Others** | Any remaining unrecognized extensions |

---

## 🛠️ Building from Source

No special IDE required! Built with native .NET WPF:

```powershell
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$wpf = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF"
$refs = @("/r:System.dll", "/r:System.Core.dll", "/r:System.Drawing.dll", "/r:System.Windows.Forms.dll", "/r:$wpf\PresentationFramework.dll", "/r:$wpf\PresentationCore.dll", "/r:$wpf\WindowsBase.dll", "/r:System.Xaml.dll", "/r:System.Web.Extensions.dll")
& $csc /target:winexe "/out:FileOrganizer.exe" $refs "FileOrganizerApp.cs"
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](https://github.com/devDhrubo/one-click-file-arrange/issues).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
