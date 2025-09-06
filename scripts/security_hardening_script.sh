#!/bin/bash
# Security Hardening Script
# Run this on ALL VMs for security compliance

set -e

echo "=== Starting Security Hardening at $(date) ==="

# 1. Disable password authentication for SSH
echo "1. Disabling SSH password authentication..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

# 2. Restart SSH service
echo "2. Restarting SSH service..."
sudo systemctl restart sshd

# 3. Update system packages
echo "3. Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 4. Install fail2ban for additional security
echo "4. Installing fail2ban..."
sudo apt install -y fail2ban

# 5. Configure basic fail2ban for SSH
echo "5. Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
EOF

# 6. Start and enable fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 7. Configure automatic security updates
echo "6. Configuring automatic security updates..."
sudo apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# 8. Set up basic firewall with ufw (if not using AWS Security Groups exclusively)
echo "7. Setting up basic firewall rules..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable

# 9. Verify SSH key authentication
echo "8. Verifying SSH configuration..."
sudo sshd -t
echo "SSH configuration test passed"

# 10. Show current user
echo "9. Current user and groups:"
id
groups

# 11. Check Docker user permissions
echo "10. Docker user permissions:"
groups | grep docker && echo "User is in docker group" || echo "WARNING: User not in docker group"

# 12. Show SSH configuration
echo "11. SSH Password Authentication status:"
sudo grep "PasswordAuthentication" /etc/ssh/sshd_config

# 13. Show fail2ban status
echo "12. Fail2ban status:"
sudo systemctl status fail2ban --no-pager

echo "=== Security Hardening completed at $(date) ==="
echo ""
echo "Security measures applied:"
echo "✓ SSH password authentication disabled"
echo "✓ Fail2ban installed and configured"
echo "✓ Automatic security updates enabled"
echo "✓ Basic firewall rules configured"
echo "✓ System packages updated"
echo ""
echo "IMPORTANT: Make sure you have SSH key access before logging out!"
echo "Test SSH key access from another terminal before disconnecting."