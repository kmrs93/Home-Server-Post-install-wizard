# 🏠 Home Server Post-Install Wizard

A collection of Bash scripts to automate and simplify post-installation tasks on Ubuntu-based home servers. Whether you're setting up storage, networking, or services like Samba and Docker, this toolkit helps you get it done fast—with or without a GUI.

---

## 📦 Quick Install

Clone this repository using `curl` and `git`:

```bash
curl -L https://github.com/kmrs93/Home-Server-Post-install-wizard/archive/refs/heads/main.tar.gz | tar -xz && mv Home-Server-Post-install-wizard-main Home-Server-Post-install-wizard
```

Or use `git` directly:

```bash
git clone https://github.com/kmrs93/Home-Server-Post-install-wizard.git
```

---

## 📁 Contents

| Script | Description | 
| --- | --- | 
| `post_install.sh` | Runs all setup tasks sequentially with minimal prompts | 
| `wizard_install.sh` | Interactive wizard with checklists and progress bars | 

---

## 🛠️ Features

* 📈 Expand LVM root volume  
* 🔧 Disable sleep on lid close  
* 📶 Configure Wi-Fi with static IP (Netplan)  
* 📁 Mount HDDs interactively  
* 🔐 Install and configure Samba shares  
* 🐳 Install Docker and add user to Docker group  

---

## 🚀 Usage

### 🔧 Prerequisites

* Ubuntu system with LVM  
* Sudo privileges  
* Internet connection  
* Optional: `whiptail` (for wizard interface)  

### ▶️ Run the Scripts

#### Option 1: Automatic Setup

```bash
chmod +x post_install.sh
./post_install.sh
```

#### Option 2: Interactive Wizard

```bash
chmod +x wizard_install.sh
./wizard_install.sh
```

You'll be guided through a checklist of tasks with progress bars and input dialogs.

---

## 📦 Dependencies

The wizard script will auto-install missing dependencies:

* `whiptail`, `lsblk`, `ip`, `awk`, `curl`, `netplan`, `NetworkManager`, `smbpasswd`

---

## 📂 Repository Structure

```
Home-Server-Post-install-wizard/
├── post_install.sh       # Sequential automation script
├── wizard_install.sh     # Interactive setup wizard
└── README.md             # Documentation
```

---

## 📜 License

MIT License — free to use, modify, and distribute.

---

## 👤 Author

[@kmrs93](https://github.com/kmrs93)
