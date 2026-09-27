"""
Desktop & Folder File Organizer (Python Edition)
Automatically categorizes PDF, documents, videos, screenshots, images, archives, installers, code into folders.
"""

import os
import shutil
import json
import re
from pathlib import Path
from datetime import datetime

# Category rules
CATEGORY_RULES = {
    "Screenshots": {
        "extensions": {".png", ".jpg", ".jpeg", ".bmp", ".webp"},
        "patterns": [r"screenshot", r"screen\s*shot", r"snip", r"capture", r"snippingtool"]
    },
    "PDFs & Documents": {
        "extensions": {".pdf", ".docx", ".doc", ".txt", ".rtf", ".odt", ".xlsx", ".xls", ".csv", ".pptx", ".ppt", ".epub", ".pages", ".numbers", ".key", ".tsv", ".md", ".xopp"}
    },
    "Images & Photos": {
        "extensions": {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp", ".ico", ".tiff", ".tif", ".raw", ".heic", ".psd", ".ai", ".eps", ".avif"}
    },
    "Videos": {
        "extensions": {".mp4", ".mkv", ".mov", ".avi", ".wmv", ".flv", ".webm", ".m4v", ".3gp", ".ts", ".vob", ".mpg", ".mpeg"}
    },
    "Audio & Music": {
        "extensions": {".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a", ".wma", ".opus", ".mid", ".midi"}
    },
    "Archives & Compressed": {
        "extensions": {".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".tgz", ".iso", ".cab", ".dmg"}
    },
    "Installers & Executables": {
        "extensions": {".exe", ".msi", ".msix", ".appx", ".reg"}
    },
    "Code & Development": {
        "extensions": {".py", ".js", ".jsx", ".ts", ".tsx", ".html", ".htm", ".css", ".scss", ".json", ".xml", ".yaml", ".yml", ".sql", ".cpp", ".c", ".h", ".cs", ".java", ".go", ".rs", ".php", ".rb", ".sh", ".ps1"}
    }
}

EXCLUDED_FILES = {
    "desktop.ini", "thumbs.db", ".ds_store", ".organizer_history.json",
    ".file_organizer_history.json", "organizer.ps1", "fileorganizergui.ps1",
    "organizer.py", "organize-desktop.bat", "organize-current-folder.bat",
    "launch_organizer_gui.bat", "organize_desktop_now.bat", "organize_current_folder.bat",
    "undo_desktop_organization.bat", "organize_files.bat", "readme.md"
}

EXCLUDED_EXTENSIONS = {".lnk", ".url"}

def get_category(file_path: Path) -> str:
    name_lower = file_path.name.lower()
    ext_lower = file_path.suffix.lower()

    # 1. Screenshot detection
    scr_info = CATEGORY_RULES["Screenshots"]
    if ext_lower in scr_info["extensions"]:
        for pattern in scr_info["patterns"]:
            if re.search(pattern, name_lower):
                return "Screenshots"

    # 2. Standard categories
    for cat, data in CATEGORY_RULES.items():
        if cat == "Screenshots":
            continue
        if ext_lower in data["extensions"]:
            return cat

    return "Others"

def get_unique_destination(target_folder: Path, original_name: str) -> Path:
    dest_path = target_folder / original_name
    if not dest_path.exists():
        return dest_path

    base_name = dest_path.stem
    extension = dest_path.suffix
    counter = 1

    while dest_path.exists():
        dest_path = target_folder / f"{base_name} ({counter}){extension}"
        counter += 1

    return dest_path

def get_history_file(target: Path) -> Path:
    app_data = Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "FileOrganizer"
    app_data.mkdir(parents=True, exist_ok=True)
    import base64
    d_hash = base64.urlsafe_b64encode(str(target).lower().encode("utf-8")).decode("ascii").rstrip("=")
    return app_data / f"history_{d_hash}.json"

def organize_directory(directory_path: str = None, preview: bool = False):
    target = Path(directory_path) if directory_path else Path.cwd()
    target = target.resolve()
    history_file = get_history_file(target)

    files_to_move = []
    category_counts = {}

    for item in target.iterdir():
        if not item.is_file():
            continue
        if item.name.lower() in EXCLUDED_FILES or item.suffix.lower() in EXCLUDED_EXTENSIONS:
            continue

        cat = get_category(item)
        cat_dir = target / cat
        dest = get_unique_destination(cat_dir, item.name)

        files_to_move.append({
            "original_name": item.name,
            "original_path": str(item),
            "category": cat,
            "destination": str(dest)
        })

        category_counts[cat] = category_counts.get(cat, 0) + 1

    if preview:
        print(f"\n--- PREVIEW: {len(files_to_move)} files found in {target} ---")
        for cat, count in category_counts.items():
            print(f"  [{cat}]: {count} files")
        return files_to_move

    if not files_to_move:
        print("All files are already organized!")
        return

    moves_log = []
    created_folders = []

    for file_info in files_to_move:
        dest_path = Path(file_info["destination"])
        dest_folder = dest_path.parent
        if not dest_folder.exists():
            dest_folder.mkdir(parents=True, exist_ok=True)
            created_folders.append(str(dest_folder))

        shutil.move(file_info["original_path"], dest_path)
        moves_log.append({
            "OriginalPath": file_info["original_path"],
            "NewPath": str(dest_path),
            "Category": file_info["category"],
            "FileName": file_info["original_name"]
        })

    # Save transaction history
    history_data = {"Transactions": []}
    if history_file.exists():
        try:
            with open(history_file, "r", encoding="utf-8") as f:
                history_data = json.load(f)
        except Exception:
            pass

    history_data.setdefault("Transactions", []).append({
        "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "TargetDir": str(target),
        "MovedCount": len(moves_log),
        "FoldersCreated": created_folders,
        "Moves": moves_log
    })

    with open(history_file, "w", encoding="utf-8") as f:
        json.dump(history_data, f, indent=2)

    print(f"Successfully organized {len(moves_log)} files into categorized folders!")

def undo_organization(directory_path: str = None):
    target = Path(directory_path) if directory_path else Path.cwd()
    target = target.resolve()
    history_file = get_history_file(target)
    if not history_file.exists():
        legacy = target / ".organizer_history.json"
        if legacy.exists():
            history_file = legacy

    if not history_file.exists():
        print(f"No undo history found in {target}")
        return

    try:
        with open(history_file, "r", encoding="utf-8") as f:
            history_data = json.load(f)
    except Exception as e:
        print(f"Failed to read history file: {e}")
        return

    transactions = history_data.get("Transactions", [])
    if not transactions:
        print("No transactions to undo.")
        return

    last_tx = transactions.pop()
    moves = last_tx.get("Moves", [])
    restored = 0

    for item in moves:
        cur_path = Path(item["NewPath"])
        orig_path = Path(item["OriginalPath"])
        if cur_path.exists():
            shutil.move(cur_path, orig_path)
            restored += 1

    # Clean up empty folders
    for folder_str in last_tx.get("FoldersCreated", []):
        folder_p = Path(folder_str)
        if folder_p.exists() and not any(folder_p.iterdir()):
            folder_p.rmdir()

    if transactions:
        history_data["Transactions"] = transactions
        with open(history_file, "w", encoding="utf-8") as f:
            json.dump(history_data, f, indent=2)
    else:
        history_file.unlink(missing_ok=True)

    print(f"Restored {restored} files back to their original locations.")

if __name__ == "__main__":
    import sys
    args = sys.argv[1:]
    if "--undo" in args:
        undo_organization()
    elif "--preview" in args:
        organize_directory(preview=True)
    else:
        organize_directory()
