// macOS Test VM build configuration
// Based on patterns from packer-examples/macos

source "parallels-ipsw" "macos" {
  output_directory = local.output_dir

  // OCR-based boot sequence for automated macOS setup
  // This sequence navigates the macOS Setup Assistant automatically

  boot_screen_config {
    boot_command     = ["<wait1s><enter>"]
    screen_name      = "Empty"
    matching_strings = []
  }
  boot_screen_config {
    boot_command     = ["<wait1s><enter>"]
    screen_name      = "GetStarted"
    matching_strings = ["Get Started"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Language"
    matching_strings = ["English", "Language"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Country"
    matching_strings = ["Select Your Country or Region"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "SpokenLanguages"
    matching_strings = ["Written and Spoken Languages"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Accessibility"
    matching_strings = ["Accessibility", "Vision", "Hearing"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "DataAndPrivacy"
    matching_strings = ["Data", "Privacy"]
  }
  boot_screen_config {
    boot_command     = ["<tab><tab><tab><spacebar>"]
    screen_name      = "MigrationAssistant"
    matching_strings = ["Migration Assistant", "From a Mac"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><tab><leftShiftOff><spacebar>"]
    screen_name      = "SignInWithApple"
    matching_strings = ["Sign in with your apple", "Sign in to use iCloud"]
  }
  boot_screen_config {
    boot_command     = ["<tab><spacebar>"]
    screen_name      = "SignInWithApplePopup"
    matching_strings = ["Are you sure you want to skip"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar><wait1s><tab><spacebar>"]
    screen_name      = "TermsAndConditions"
    matching_strings = ["Terms and Conditions"]
  }
  boot_screen_config {
    boot_command     = ["${local.ssh_username}<tab><tab>${local.ssh_password}<tab>${local.ssh_password}<tab><tab><tab><spacebar>"]
    screen_name      = "CreateAccount"
    matching_strings = ["Create a Computer Account"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar><wait2s><tab><spacebar>"]
    screen_name      = "LocationServices"
    matching_strings = ["Enable Location Services"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "TimeZone"
    matching_strings = ["Select your Time Zone"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Analytics"
    matching_strings = ["Share Mac Analytics"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "ScreenTime"
    matching_strings = ["Screen Time"]
  }
  boot_screen_config {
    boot_command     = ["<tab><spacebar><tab><tab><tab><spacebar>"]
    screen_name      = "Siri"
    matching_strings = ["Siri"]
  }
  boot_screen_config {
    boot_command     = ["<leftShiftOn><tab><leftShiftOff><spacebar>"]
    screen_name      = "Looks"
    matching_strings = ["Choose your look"]
  }
  // Enable SSH via System Settings
  boot_screen_config {
    boot_command = [
      "<leftCtrlOn><f7><leftCtrlOff>",
      "<leftSuperOn><spacebar><leftSuperOff>System<spacebar>Settings<enter><wait5s>",
      "<up><wait><tab><wait><leftShiftOn><tab><tab><tab><tab><leftShiftOff><spacebar>",
    ]
    screen_name      = "Desktop"
    matching_strings = ["Finder", "Go"]
  }
  boot_screen_config {
    boot_command = [
      "<leftShiftOn><tab><tab><tab><tab><tab><tab><leftShiftOff><spacebar>",
      "<leftSuperOn><spacebar><leftSuperOff>terminal<enter>"
    ]
    screen_name      = "Sharing"
    matching_strings = ["File Sharing", "Remote Login"]
  }
  // Configure passwordless sudo and install Parallels Tools
  boot_screen_config {
    boot_command = [
      "sudo visudo /private/etc/sudoers.d/${local.ssh_username}<enter><wait2s>",
      "${local.ssh_password}<enter><wait2s>",
      "i<wait>${local.ssh_username} ALL = (ALL) NOPASSWD: ALL",
      "<esc>:wq<enter><wait2s>"
    ]
    screen_name      = "Terminal"
    matching_strings = ["Terminal", "${local.ssh_username}@"]
    is_last_screen   = true
  }

  boot_wait        = "1s"
  shutdown_command = "sudo shutdown -h now"
  ipsw_url         = var.ipsw_url
  ssh_username     = local.ssh_username
  ssh_password     = local.ssh_password
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
