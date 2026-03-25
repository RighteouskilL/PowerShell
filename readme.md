# 🧰 PowerShell Config Dependencies Guide

รายการโปรแกรม/โมดูลที่ต้องติดตั้งเพื่อให้ config นี้ใช้งานได้ครบถ้วน  
(แนะนำ: ใช้ `scoop` เป็นหลัก และใช้ `winget` เฉพาะตัวที่ไม่มีใน scoop)

---

## ✅ 1. Core Tools (จำเป็น)

### 🔹 fzf (Fuzzy Finder)
ใช้สำหรับค้นหาไฟล์ / history
```bash
scoop install fzf
```

### 🔹 fd (Modern find)
ใช้แทน `find` / `dir`
```bash
scoop install fd
```

### 🔹 ripgrep (rg)
ใช้สำหรับ search text ในไฟล์ (เร็วมาก)
```bash
scoop install ripgrep
```

---

## ✅ 2. Preview & File Tools (แนะนำมาก)

### 🔹 bat (cat + syntax highlight)
```bash
scoop install bat
```

### 🔹 eza (ls แบบ modern)
```bash
scoop install eza
```

---

## ✅ 3. Editor

### 🔹 Neovim
```bash
scoop install neovim
```

---

## ✅ 4. UI / Prompt

### 🔹 oh-my-posh
ใช้ทำ prompt สวย ๆ
```bash
winget install JanDeDobbeleer.OhMyPosh
```

---

## ✅ 5. PowerShell Modules

เปิด PowerShell (Run as Admin) แล้วติดตั้ง:

```powershell
Install-Module PSFzf -Scope CurrentUser -Force
Install-Module PSCompletions -Scope CurrentUser -Force
Install-Module Microsoft.WinGet.CommandNotFound -Scope CurrentUser -Force
```

---

## ✅ 6. Python (สำหรับ compress-project)

### 🔹 Python
```bash
winget install Python.Python.3
```

---

## 📦 สรุปแบบสั้น

### ใช้ Scoop
```bash
scoop install fzf fd ripgrep bat eza neovim
```

### ใช้ Winget
```bash
winget install JanDeDobbeleer.OhMyPosh
winget install Python.Python.3
```

---

## ⚠️ Optional (แต่แนะนำ)

### 🔹 Nerd Font (เพื่อให้ oh-my-posh แสดง icon ได้)
```bash
scoop bucket add nerd-fonts
scoop install CascadiaCode-NF
```

แล้วตั้งค่า font ใน Terminal เป็น:
```
CascadiaCode Nerd Font
```

---

## 🚀 เสร็จแล้วต้องทำอะไรต่อ?

1. Restart PowerShell  
2. ตรวจสอบว่า command ใช้งานได้:

```powershell
fzf
fd
rg
bat
nvim
oh-my-posh
```

---

## 💡 Tips

- ถ้า `fzf preview` ไม่ขึ้น → เช็คว่า `bat` ติดตั้งแล้ว  
- ถ้า icon ไม่ขึ้น → 99% ลืมลง Nerd Font  
- ถ้า `rg` ไม่ทำงาน → PATH อาจยังไม่ reload  

---

## 🎯 Result

เมื่อ setup ครบ:
- Ctrl+R → Fuzzy history  
- Ctrl+F → File search  
- Ctrl+G → Content search (ripgrep)  
- Tab → Fuzzy autocomplete  
- Prompt → สวย + informative ⚡  

---
