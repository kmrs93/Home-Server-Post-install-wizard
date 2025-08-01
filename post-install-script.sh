#!/bin/bash

set -e

### ┌────────────────────────────────────────────┐
### │ 1. Expand LVM Root Volume                  │
### └────────────────────────────────────────────┘
expand_lvm() {
    echo "📈 Expanding LVM root volume..."
    sudo lvextend -l +100%FREE -r /dev/mapper/ubuntu--vg-ubuntu--lv
}

### ┌────────────────────────────────────────────┐
### │ 2. Disable Sleep on Lid Close              │
### └────────────────────────────────────────────┘
disable_lid_sleep() {
    echo "🔧 Configuring lid close behavior..."
    local config="/etc/systemd/logind.conf"
    sudo cp "$config" "${config}.bak"
    sudo sed -i '/^HandleLidSwitch/d;/^HandleLidSwitchDocked/d' "$config"
    echo "HandleLidSwitch=ignore" | sudo tee -a "$config" > /dev/null
    echo "HandleLidSwitchDocked=ignore" | sudo tee -a "$config" > /dev/null
    sudo systemctl restart systemd-logind
}

### ┌────────────────────────────────────────────┐
### │ 3. Setup Wi-Fi with Static IP (Netplan)    │
### └────────────────────────────────────────────┘
setup_wifi_netplan() {
    echo "📶 Configuring Wi-Fi with Netplan..."

    read -rp "📡 Enter Wi-Fi interface name (e.g. wlan0): " iface
    read -rp "📶 Enter Wi-Fi SSID: " ssid
    read -rsp "🔐 Enter Wi-Fi Password: " pass; echo
    read -rp "🌐 Enter static IP (e.g. 192.168.1.100): " ip
    read -rp "🚪 Enter gateway IP (e.g. 192.168.1.1): " gw
    read -rp "🧭 Enter DNS servers (comma-separated): " dns

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

    echo "🔧 Applying Netplan configuration..."
    sudo netplan apply
    echo "✅ Wi-Fi with static IP configured!"
}

### ┌────────────────────────────────────────────┐
### │ 4. Mount HDDs Interactively                │
### └────────────────────────────────────────────┘
mount_hdds() {
    echo "📁 Mounting HDDs interactively..."

    read -rp "🔢 How many HDDs do you want to mount? " hdd_count
    if ! [[ "$hdd_count" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid number. Aborting."
        return 1
    fi

    sudo cp /etc/fstab /etc/fstab.bak

    for ((i = 1; i <= hdd_count; i++)); do
        echo "🛠️ Configuring HDD #$i..."

        read -rp "📂 Enter mount folder path (e.g. /media/hdd$i): " mount_path
        read -rp "🔗 Enter UUID of the HDD: " uuid
        read -rp "🧾 Enter filesystem type (e.g. ext4, ntfs, xfs): " fs_type

        if [ ! -d "$mount_path" ]; then
            echo "📁 Creating mount folder: $mount_path"
            sudo mkdir -p "$mount_path"
        fi

        sudo chown root:root "$mount_path"
        sudo chmod 755 "$mount_path"

        if [[ "$fs_type" == "ntfs" ]] || [[ "$fs_type" == "ntfs-3g" ]]; then
            if ! dpkg -s ntfs-3g >/dev/null 2>&1; then
                echo "📦 Installing ntfs-3g..."
                sudo apt update
                sudo apt install -y ntfs-3g
            fi
            fs_type="ntfs-3g"
        fi

        sudo sed -i "/$uuid/d" /etc/fstab
        echo "UUID=$uuid $mount_path $fs_type rw,defaults 0 2" | sudo tee -a /etc/fstab
        sudo mount "$mount_path"
    done

    echo "✅ All HDDs mounted and configured!"
}

### ┌────────────────────────────────────────────┐
### │ 5. Install and Configure Samba             │
### └────────────────────────────────────────────┘
setup_samba() {
    echo "🔐 Setting up Samba..."

    read -rp "📁 Enter the full path of the folder to share via Samba: " share_path
    if [ ! -d "$share_path" ]; then
        echo "❌ Folder does not exist. Creating it..."
        sudo mkdir -p "$share_path"
    fi

    read -rp "👤 Enter Samba username: " smb_user
    if ! id "$smb_user" &>/dev/null; then
        sudo adduser --no-create-home --disabled-login "$smb_user"
    fi

    echo "🔑 Set Samba password for '$smb_user':"
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
    echo "✅ Samba share configured for: $share_path"
}

### ┌────────────────────────────────────────────┐
### │ 6. Install Docker                          │
### └────────────────────────────────────────────┘
install_docker() {
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
}

### ┌────────────────────────────────────────────┐
### │ Main Execution                             │
### └────────────────────────────────────────────┘
main() {
    expand_lvm
    disable_lid_sleep
    setup_wifi_netplan
    mount_hdds
    setup_samba
    install_docker

    echo "🎉 All post-install tasks completed!"
    echo "🔄 Please log out and back in to apply Docker group changes."
}

main
