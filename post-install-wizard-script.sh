#!/bin/bash

set -e

# ───────────────────────────────────────────────
# 0. Dependency Check
# ───────────────────────────────────────────────
check_dependencies() {
    echo "🔍 Checking required dependencies..."

    REQUIRED_CMDS=("whiptail" "lsblk" "ip" "awk" "curl" "netplan" "NetworkManager" "smbpasswd")
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "📦 Installing missing dependency: $cmd"
            sudo apt update
            sudo apt install -y "$cmd"
        fi
    done
}

# ───────────────────────────────────────────────
# 1. Progress Bar Wrapper
# ───────────────────────────────────────────────
run_with_progress() {
    {
        for i in $(seq 1 100); do
            echo $i
            sleep 0.01
        done
    } | whiptail --gauge "⏳ Running: $1..." 6 60 0
}

# ───────────────────────────────────────────────
# 2. Modular Setup Functions
# ───────────────────────────────────────────────
expand_lvm() {
    run_with_progress "Expanding LVM Root Volume"
    sudo lvextend -l +100%FREE -r /dev/mapper/ubuntu--vg-ubuntu--lv
}

disable_lid_sleep() {
    run_with_progress "Disabling Lid Sleep"
    local config="/etc/systemd/logind.conf"
    sudo cp "$config" "${config}.bak"
    sudo sed -i '/^HandleLidSwitch/d;/^HandleLidSwitchDocked/d' "$config"
    echo "HandleLidSwitch=ignore" | sudo tee -a "$config" > /dev/null
    echo "HandleLidSwitchDocked=ignore" | sudo tee -a "$config" > /dev/null
    sudo systemctl restart systemd-logind
}

setup_wifi_netplan() {
    iface=$(ip -o link show | awk -F': ' '{print $2}' | \
        whiptail --title "🌐 Select Interface" --menu "Choose Wi-Fi interface:" 20 60 10 $(cat) 3>&1 1>&2 2>&3)
    ssid=$(whiptail --inputbox "Enter Wi-Fi SSID:" 10 50 3>&1 1>&2 2>&3)
    pass=$(whiptail --passwordbox "Enter Wi-Fi Password:" 10 50 3>&1 1>&2 2>&3)
    ip=$(whiptail --inputbox "Enter static IP (e.g. 192.168.1.100):" 10 50 3>&1 1>&2 2>&3)
    gw=$(whiptail --inputbox "Enter gateway IP (e.g. 192.168.1.1):" 10 50 3>&1 1>&2 2>&3)
    dns=$(whiptail --inputbox "Enter DNS servers (comma-separated):" 10 50 3>&1 1>&2 2>&3)

    run_with_progress "Configuring Wi-Fi"

    sudo tee /etc/netplan/01-wifi-static.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: NetworkManager
  wifis:
    $iface:
      dhcp4: no
      addresses:
        - $ip/24
      gateway4: $gw
      nameservers:
        addresses: [${dns//,/ }]
      access-points:
        "$ssid":
          password: "$pass"
EOF

    sudo netplan apply
}

mount_hdds() {
    hdd_count=$(whiptail --inputbox "🔢 How many HDDs to mount?" 10 50 3>&1 1>&2 2>&3)
    sudo cp /etc/fstab /etc/fstab.bak

    for ((i = 1; i <= hdd_count; i++)); do
        mount_path=$(whiptail --inputbox "📂 Mount path for HDD #$i:" 10 50 "/media/hdd$i" 3>&1 1>&2 2>&3)
        uuid=$(whiptail --inputbox "🔗 UUID for HDD #$i:" 10 50 3>&1 1>&2 2>&3)
        fs_type=$(whiptail --inputbox "🧾 Filesystem type (e.g. ext4, ntfs):" 10 50 3>&1 1>&2 2>&3)

        run_with_progress "Mounting HDD #$i"

        sudo mkdir -p "$mount_path"
        sudo chown root:root "$mount_path"
        sudo chmod 755 "$mount_path"

        [[ "$fs_type" == "ntfs" ]] && sudo apt install -y ntfs-3g && fs_type="ntfs-3g"

        sudo sed -i "/$uuid/d" /etc/fstab
        echo "UUID=$uuid $mount_path $fs_type rw,defaults 0 2" | sudo tee -a /etc/fstab
        sudo mount "$mount_path"
    done
}

setup_samba() {
    share_path=$(whiptail --inputbox "📁 Folder to share via Samba:" 10 50 3>&1 1>&2 2>&3)
    smb_user=$(whiptail --inputbox "👤 Samba username:" 10 50 3>&1 1>&2 2>&3)

    run_with_progress "Setting up Samba"

    sudo mkdir -p "$share_path"
    sudo adduser --no-create-home --disabled-login "$smb_user"
    sudo smbpasswd -a "$smb_user"
    sudo chown "$smb_user":"$smb_user" "$share_path"
    sudo chmod 770 "$share_path"

    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
    sudo tee -a /etc/samba/smb.conf > /dev/null <<EOF

[SharedFolder]
   path = $share_path
   browseable = yes
   writable = yes
   valid users = $smb_user
   create mask = 0770
   directory mask = 0770
EOF

    sudo systemctl restart smbd
}

install_docker() {
    run_with_progress "Installing Docker"
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
}

# ───────────────────────────────────────────────
# 3. Run Selected Tasks from Checklist
# ───────────────────────────────────────────────
task_checklist() {
    TASKS=$(whiptail --title "🧩 Select Tasks" --checklist \
        "Use spacebar to select tasks to run:" 20 70 10 \
        "expand_lvm" "Expand LVM Root Volume" OFF \
        "disable_lid_sleep" "Disable Lid Sleep" OFF \
        "setup_wifi_netplan" "Setup Wi-Fi (Netplan)" OFF \
        "mount_hdds" "Mount HDDs" OFF \
        "setup_samba" "Configure Samba Share" OFF \
        "install_docker" "Install Docker" OFF \
        3>&1 1>&2 2>&3)

    for task in $TASKS; do
        eval "${task//\"/}"
    done

    whiptail --msgbox "✅ Selected tasks completed!" 10 40
}

# ───────────────────────────────────────────────
# 4. Welcome and Main Menu
# ───────────────────────────────────────────────
welcome() {
    whiptail --title "🧙 Welcome" --msgbox \
    "Welcome to the Post-Install Wizard!\n\nThis tool will guide you through system setup tasks interactively." 12 50
}

main_menu() {
    while true; do
        CHOICE=$(whiptail --title "🛠️ Setup Wizard" --menu "Choose an option:" 20 60 10 \
            "1" "Run Selected Tasks (Checklist)" \
            "2" "Run All Tasks Sequentially" \
            "0" "Exit Wizard" 3>&1 1>&2 2>&3)

        case $CHOICE in
            1) task_checklist ;;
            2) expand_lvm; disable_lid_sleep; setup_wifi_netplan; mount_hdds; setup_samba; install_docker ;;
            0) whiptail --title "👋 Goodbye" --msgbox "Setup complete. You may log out and back in to apply changes." 10 50; exit 0 ;;
        esac
    done
}

# ───────────────────────────────────────────────
# 5. Launch Wizard
# ───────────────────────────────────────────────
welcome
check_dependencies
main_menu
