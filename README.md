# 🧙 Post-Install Wizard for Ubuntu

An interactive Bash-based setup wizard designed to streamline post-installation tasks on Ubuntu systems. Whether you're configuring a fresh server or customizing a desktop environment, this tool helps automate essential setup steps with a user-friendly interface powered by `whiptail`.

---

## 🚀 Features

* ✅ Dependency auto-check and installation  
* 📦 Expand LVM root volume  
* 💤 Disable lid sleep behavior  
* 🌐 Configure Wi-Fi with static IP using Netplan  
* 💾 Mount multiple HDDs with UUID and filesystem support  
* 📁 Set up Samba shares with user access control  
* 🐳 Install Docker and add current user to Docker group  
* 🧩 Task checklist or full sequential execution  
* 🛡️ Config file backups before modification  

---

## 📋 Requirements

This script is intended for Ubuntu-based systems and requires `sudo` privileges.

Dependencies (auto-installed if missing):

* `whiptail`  
* `lsblk`  
* `ip`  
* `awk`  
* `curl`  
* `netplan`  
* `NetworkManager`  
* `smbpasswd`  

---

## 🧑‍💻 Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/post-install-wizard.git
   cd post-install-wizard
   ```

2. Make the script executable:

   ```bash
   chmod +x post_install_wizard.sh
   ```

3. Run the wizard:

   ```bash
   sudo ./post_install_wizard.sh
   ```

---

## 🛠️ Customization

You can modify or extend the script by adding new setup functions or adjusting existing ones. Each task is modular and easy to adapt.

To add a new task:

* Define a new function  
* Add it to the checklist in `task_checklist()`  
* Optionally include it in the sequential run block  

---

## ⚠️ Notes

* Some changes (e.g., Docker group membership) may require logging out and back in.  
* Always review and test changes in a safe environment before deploying to production systems.  

---

## 📄 License

This project is open-source under the MIT License.

---

## 🙌 Credits

Crafted with care to simplify Ubuntu setup workflows. Contributions and suggestions welcome!
