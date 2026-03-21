extension FilePathExt on String {
  String get fileExtension {
    final dot = lastIndexOf('.');
    return dot == -1 ? '' : substring(dot).toLowerCase();
  }

  bool get isPlainCertificate {
    const extensions = {'.pem', '.crt', '.cer'};
    return extensions.contains(fileExtension);
  }

  bool get isEncryptedCertificate => fileExtension == '.enc';
}
