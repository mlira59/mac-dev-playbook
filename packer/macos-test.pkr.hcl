// macOS Test VM build configuration
// Boot sequence aligned with Parallels packer-examples for Sequoia 15.4+
// Ref: https://github.com/Parallels/packer-examples/blob/main/macos/

source "parallels-ipsw" "macos" {
  output_directory = local.output_dir

  // OCR-based boot sequence for automated macOS Setup Assistant navigation

  boot_screen_config {
    boot_command     = ["<wait2s><enter>"]
    screen_name      = "Empty"
    matching_strings = []
  }
  boot_screen_config {
    boot_command     = ["<wait1s><enter>"]
    screen_name      = "GetStarted"
    matching_strings = ["Get Started"]
  }
  boot_screen_config {
    boot_command     = ["<wait1s><enter>"]
    screen_name      = "GetStarted2"
    matching_strings = ["hola"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Language"
    matching_strings = ["English", "Language", "Australia", "India"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Country"
    matching_strings = ["Select Your Country or Region"]
  }
  // Sequoia 15.4+ replaced "Migration Assistant" with "Transfer Your Data"
  // 4 tabs to "Set up as new", space to select, 2 tabs to Continue, space to click
  boot_screen_config {
    boot_command     = ["<tab><tab><tab><tab><spacebar><tab><tab><spacebar>"]
    screen_name      = "TransferData"
    matching_strings = ["transfer", "information"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "SpokenLanguages"
    matching_strings = ["Written and Spoken Languages"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Accessibility"
    matching_strings = ["Accessibility", "Vision", "Hearing", "Motor", "Cognitive"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "DataAndPrivacy"
    matching_strings = ["Data", "Privacy", "This icon appears"]
  }
  // Sequoia 15.4+: "Create a Mac Account" (was "Create a Computer Account")
  // Password may get corrupted by tab cycling; we fix it later via dscl in Terminal
  boot_screen_config {
    boot_command     = ["${local.ssh_username}<tab><tab>${local.ssh_password}<tab>${local.ssh_password}<tab><tab><tab><tab><spacebar>"]
    screen_name      = "CreateAccount"
    matching_strings = ["Create a Mac Account", "The password you create here"]
  }
  // Sequoia 15.4+ needs Ctrl+F7 to enable Full Keyboard Access before Sign In screens
  boot_screen_config {
    boot_command     = ["<leftCtrlOn><f7><leftCtrlOff><wait1s><leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "SignInToApple"
    matching_strings = ["Sign in to your apple", "Sign in to use iCloud"]
  }
  boot_screen_config {
    boot_command     = ["<leftCtrlOn><f7><leftCtrlOff><wait1s><leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "SignInWithApple"
    matching_strings = ["Sign in with your apple", "Sign in to use iCloud"]
  }
  boot_screen_config {
    boot_command     = ["<tab><spacebar>"]
    screen_name      = "SignInWithApplePopup"
    matching_strings = ["Are you sure you want to skip", "signing in with an Apple"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar><wait1s><tab><spacebar>"]
    screen_name      = "TermsAndConditionsUS"
    matching_strings = ["Terms and Conditions", "macOS Software License Agreement"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar><wait2s><tab><spacebar>"]
    screen_name      = "LocationServices"
    matching_strings = ["Enable Location Services", "About Location Services"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "TimeZone"
    matching_strings = ["Select your Time Zone"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Analytics"
    matching_strings = ["Share Mac Analytics with Apple"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "ScreenTime"
    matching_strings = ["Screen Time", "Get insights about your"]
  }
  boot_screen_config {
    boot_command     = ["<tab><spacebar><tab><tab><tab><spacebar>"]
    screen_name      = "Siri"
    matching_strings = ["Siri", "Siri helps you get things done"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Looks"
    matching_strings = ["Choose your look", "Select an appearance"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Update"
    matching_strings = ["Update Mac Automatically"]
  }
  boot_screen_config {
    boot_command     = ["<spacebar>"]
    screen_name      = "WelcomeToMac"
    matching_strings = ["Welcome to Mac", "continue"]
  }
  // Open Terminal via Finder Go-to-Folder shortcut
  boot_screen_config {
    boot_command = [
      "<leftShiftOn><leftSuperOn>G<leftSuperOff><leftShiftOff>/Applications/Utilities/Terminal.app<enter><leftSuperOn>o<leftSuperOff>",
    ]
    screen_name       = "Desktop"
    matching_strings  = ["Finder", "Go"]
    execute_only_once = true
  }
  // Configure sudo, reset password (may be corrupted from CreateAccount tab cycling),
  // enable SSH with password auth, and set static IP for NAT forwarding
  boot_screen_config {
    boot_command = [
      // Set up passwordless sudo
      "sudo visudo /private/etc/sudoers.d/${local.ssh_username}<enter><wait2s>",
      "${local.ssh_password}<enter><wait2s>",
      "i<wait>${local.ssh_username} ALL = (ALL) NOPASSWD: ALL",
      "<esc>:wq<enter><wait3s>",
      // Reset password via dscl (may be corrupted from CreateAccount tab cycling)
      "sudo dscl . -passwd /Users/${local.ssh_username} '${local.ssh_password}'<enter><wait2s>",
      // Enable SSH with password auth (write to sshd_config.d so it takes priority over Include)
      "printf 'PasswordAuthentication yes\\nKbdInteractiveAuthentication yes\\n' | sudo tee /etc/ssh/sshd_config.d/00-packer.conf<enter><wait2s>",
      "sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist<enter><wait5s>",
      // Set static IP for Parallels NAT forwarding (bypasses macOS Sequoia TCC Local Network restriction)
      "sudo networksetup -setmanual Ethernet ${var.vm_static_ip} 255.255.255.0 10.211.55.1<enter><wait5s>",
      "sudo networksetup -setdnsservers Ethernet 10.211.55.1 8.8.8.8<enter><wait2s>",
    ]
    screen_name      = "Terminal"
    matching_strings = ["Terminal", "${local.ssh_username}@", "macos-test"]
    is_last_screen   = true
  }

  boot_wait        = "1s"
  shutdown_command  = "sudo shutdown -h now"
  ipsw_url         = var.ipsw_url
  ipsw_checksum    = var.ipsw_checksum
  // Connect via localhost NAT forwarding to bypass macOS Sequoia TCC
  ssh_host         = "127.0.0.1"
  ssh_port         = var.ssh_forward_port
  ssh_username     = local.ssh_username
  ssh_password     = local.ssh_password
  ssh_timeout      = "30m"
  vm_name          = local.machine_name
  cpus             = var.vm_specs.cpus
  memory           = var.vm_specs.memory
}

build {
  sources = ["source.parallels-ipsw.macos"]

  // Install Xcode Command Line Tools
  provisioner "shell" {
    inline = [
      "sudo xcode-select --install || true",
      "sleep 10"
    ]
    expect_disconnect = true
  }

  // Install Homebrew
  provisioner "shell" {
    environment_vars = ["NONINTERACTIVE=1"]
    inline = [
      "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "(echo; echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"') >> /Users/${local.ssh_username}/.zprofile",
      "eval \"$(/opt/homebrew/bin/brew shellenv)\"",
      "brew install python3 ansible"
    ]
    timeout = "30m"
  }

  // Copy SSH public key for Ansible access
  provisioner "shell" {
    inline = [
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "curl -fsSL https://github.com/mlira59.keys >> ~/.ssh/authorized_keys || true",
      "chmod 600 ~/.ssh/authorized_keys"
    ]
  }
}
