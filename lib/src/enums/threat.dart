/// Security threats that flutter_rasp can detect.
enum Threat {
  /// Root (Android) or jailbreak (iOS).
  root,

  /// Running on an emulator or simulator.
  emulator,

  /// Attached debugger (JDWP, ptrace).
  debug,

  /// Frida, Xposed, Cycript, Substrate.
  hook,

  /// App signature or bundle has been modified.
  repackaging,

  /// Installed from an untrusted source.
  trustedInstall,

  /// Active VPN connection.
  vpn,

  /// Android only: developer options enabled.
  developerMode,

  /// Android only: ADB (Android Debug Bridge) is enabled.
  adbEnabled,

  /// No screen lock configured.
  devicePasscode,

  /// Device lacks hardware-backed keystore (TEE/StrongBox/Secure Enclave).
  secureHardwareNotAvailable,

  /// App binary is not obfuscated — class/symbol names are readable.
  obfuscationIssues,

  /// Android only: system clock may be spoofed (auto-time disabled).
  timeSpoofing,

  /// Android only: mock locations enabled or mock-location app detected.
  locationSpoofing,

  /// Android only: app running in a cloned/dual-app environment.
  multiInstance,

  undefined;

  static final Set<Threat> active = Set.unmodifiable(
    values.where((t) => t != undefined).toSet(),
  );

  static Threat fromName(String name) {
    return Threat.values.firstWhere(
      (threat) => threat.name == name,
      orElse: () => Threat.undefined,
    );
  }
}
