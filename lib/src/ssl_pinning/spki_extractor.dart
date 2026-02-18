import 'dart:typed_data';

/// Extracts the SPKI bytes from a DER-encoded X.509 certificate
/// via minimal ASN.1 parsing.
class SpkiExtractor {
  const SpkiExtractor._();

  static Uint8List? extract(Uint8List derBytes) {
    try {
      var offset = 0;

      // Outer SEQUENCE (Certificate).
      final cert = _readTlv(derBytes, offset);
      if (cert == null || cert.tag != 0x30) return null;

      // Inner SEQUENCE (TBSCertificate).
      offset = cert.contentOffset;
      final tbs = _readTlv(derBytes, offset);
      if (tbs == null || tbs.tag != 0x30) return null;

      offset = tbs.contentOffset;

      // Skip optional version [0] if present.
      if (offset < derBytes.length && (derBytes[offset] & 0xFF) == 0xA0) {
        final version = _readTlv(derBytes, offset);
        if (version == null) return null;
        offset = version.endOffset;
      }

      // Skip: serialNumber, signatureAlgorithm, issuer, validity, subject
      // (5 elements).
      for (var i = 0; i < 5; i++) {
        final element = _readTlv(derBytes, offset);
        if (element == null) return null;
        offset = element.endOffset;
      }

      // Next element is subjectPublicKeyInfo.
      final spki = _readTlv(derBytes, offset);
      if (spki == null || spki.tag != 0x30) return null;

      return Uint8List.sublistView(derBytes, offset, spki.endOffset);
    } catch (_) {
      return null;
    }
  }

  static _Tlv? _readTlv(Uint8List data, int offset) {
    if (offset >= data.length) return null;
    final tag = data[offset];
    var pos = offset + 1;

    if (pos >= data.length) return null;
    final lengthByte = data[pos];
    pos++;

    int contentLength;
    if (lengthByte < 0x80) {
      contentLength = lengthByte;
    } else {
      final numBytes = lengthByte & 0x7F;
      if (numBytes == 0 || numBytes > 4) return null;
      contentLength = 0;
      for (var i = 0; i < numBytes; i++) {
        if (pos >= data.length) return null;
        contentLength = (contentLength << 8) | data[pos];
        pos++;
      }
    }

    if (pos + contentLength > data.length) return null;
    return _Tlv(tag, pos, contentLength);
  }
}

class _Tlv {
  final int tag;
  final int contentOffset;
  final int contentLength;

  const _Tlv(this.tag, this.contentOffset, this.contentLength);

  int get endOffset => contentOffset + contentLength;
}
