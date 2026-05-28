// Local mock backend for the flutter_rasp example. See ../README.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

const _defaultPort = 8787;

final List<Map<String, Object?>> _reports = <Map<String, Object?>>[];

Future<void> main(List<String> args) async {
  var port = _defaultPort;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--port' && i + 1 < args.length) {
      port = int.parse(args[++i]);
    } else if (a == '-h' || a == '--help') {
      stdout.writeln('Usage: dart run tool/mock_backend.dart [--port N]');
      return;
    }
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('flutter_rasp mock backend');
  stdout.writeln('  listening on http://localhost:$port');
  stdout.writeln('  open the dashboard: http://localhost:$port/');
  stdout.writeln('');

  await for (final req in server) {
    unawaited(_handle(req));
  }
}

Future<void> _handle(HttpRequest req) async {
  try {
    final path = req.uri.path;
    if (req.method == 'POST' && path == '/v1/ingest') {
      await _ingest(req);
    } else if (req.method == 'GET' && path == '/') {
      _renderDashboard(req);
    } else if (req.method == 'GET' && path == '/reports') {
      _renderJson(req);
    } else if (req.method == 'DELETE' && path == '/reports') {
      _reports.clear();
      stdout.writeln('reports cleared');
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
    } else {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
    }
  } catch (e, s) {
    stderr.writeln('handler error: $e\n$s');
    try {
      req.response.statusCode = HttpStatus.internalServerError;
      await req.response.close();
    } catch (_) {}
  }
}

Future<void> _ingest(HttpRequest req) async {
  final bytes = await _drain(req);
  final body = utf8.decode(bytes);

  final receivedSig = req.headers.value('x-rasp-signature');
  Map<String, Object?> payload;
  try {
    payload = (jsonDecode(body) as Map).cast<String, Object?>();
  } catch (e) {
    stderr.writeln('invalid JSON: $e');
    req.response.statusCode = HttpStatus.badRequest;
    await req.response.close();
    return;
  }

  if (receivedSig != null) payload['_hmac'] = receivedSig;
  payload['_receivedAt'] = DateTime.now().toUtc().toIso8601String();
  _reports.insert(0, payload);
  _printReport(payload, hmac: receivedSig);

  req.response.statusCode = HttpStatus.noContent;
  await req.response.close();
}

void _printReport(Map<String, Object?> r, {String? hmac}) {
  final type = r['type'];
  final vuln = r['vulnerabilityKind'] ?? '-';
  final device = (r['device'] as Map?)?.cast<String, Object?>() ?? const {};
  final app = (r['app'] as Map?)?.cast<String, Object?>() ?? const {};
  final id = (device['id'] as String?) ?? '';
  final idShort = id.length > 12 ? id.substring(0, 12) : id;

  stdout.writeln('---');
  stdout.writeln('[$type] vuln=$vuln  device=$idShort...');
  stdout.writeln(
    '  ${device['manufacturer']} ${device['model']} . ${device['platform']} ${device['osVersion']}',
  );
  stdout.writeln('  ${app['packageName']} v${app['version']} (${app['build']})');
  if (hmac != null) stdout.writeln('  hmac: $hmac');
  if (r['message'] != null) stdout.writeln('  msg: ${r['message']}');
}

void _renderJson(HttpRequest req) {
  req.response.headers.contentType =
      ContentType('application', 'json', charset: 'utf-8');
  req.response.write(jsonEncode(_reports));
  req.response.close();
}

void _renderDashboard(HttpRequest req) {
  final rows = _reports.map(_renderRow).join();
  final html = '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>flutter_rasp · mock backend</title>
<meta http-equiv="refresh" content="5">
<style>
  body { font: 13px/1.5 -apple-system, system-ui, sans-serif;
         background:#0f0f1a; color:#e5e5f0; margin:0; padding:24px; }
  h1 { margin:0 0 4px; font-size:18px; color:#7c4dff; }
  .sub { color:#888; margin-bottom:24px; font-size:11px; }
  .empty { color:#666; padding:24px; text-align:center;
           border:1px dashed #333; border-radius:6px; }
  .row { background:#1a1a2e; border:1px solid #2a2a44;
         border-radius:6px; padding:14px 18px; margin-bottom:10px; }
  .head { display:flex; align-items:center; flex-wrap:wrap; gap:8px; }
  .tag { display:inline-block; padding:2px 8px; border-radius:3px;
         font-size:10px; font-weight:700; letter-spacing:.5px;
         text-transform:uppercase; }
  .exit { background:#5a1a1a; color:#ff7676; }
  .threat { background:#4a3a1a; color:#ffc266; }
  .flutter { background:#1a3a5a; color:#76b8ff; }
  .dart { background:#3a3a1a; color:#ffd576; }
  .manual { background:#1a3a3a; color:#76ffd8; }
  .threatDetected { background:#3a2a1a; color:#ffaa66; }
  .msg { margin-top:8px; color:#ddd; font-size:12px; }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr));
          gap:12px 24px; margin-top:12px; }
  .sec h4 { margin:0 0 4px; font-size:10px; color:#7c4dff;
            letter-spacing:1px; text-transform:uppercase; }
  .kv { display:grid; grid-template-columns:auto 1fr; column-gap:8px;
        row-gap:2px; font: 11px/1.4 ui-monospace, monospace; }
  .kv b { color:#888; font-weight:400; }
  .kv span { color:#ddd; word-break:break-all; }
  details { margin-top:10px; }
  details summary { cursor:pointer; font-size:10px; color:#7c4dff;
                    letter-spacing:1px; text-transform:uppercase;
                    padding:4px 0; user-select:none; }
  pre { margin:6px 0 0; padding:8px 10px; background:#0a0a14;
        border-radius:4px; max-height:240px; overflow:auto;
        font: 11px/1.4 ui-monospace, monospace; color:#bbb;
        white-space:pre-wrap; word-break:break-all; }
  .crumb { padding:3px 0; border-bottom:1px solid #222;
           font: 11px/1.4 ui-monospace, monospace; }
  .crumb:last-child { border-bottom:none; }
  .crumb .lvl { display:inline-block; min-width:54px; color:#888; }
  .crumb .cat { color:#7c4dff; }
  .crumb .ts  { color:#555; font-size:10px; }
  .meta { margin-top:10px; font: 11px/1.4 ui-monospace, monospace;
          color:#555; word-break:break-all; }
  .actions { margin-top:16px; }
  button { background:#2a2a44; color:#e5e5f0; border:none;
           border-radius:4px; padding:6px 12px; cursor:pointer;
           font: 11px/1 ui-monospace, monospace; }
  button:hover { background:#3a3a54; }
</style>
</head>
<body>
  <h1>flutter_rasp · mock backend</h1>
  <div class="sub">${_reports.length} reports · auto-refresh 5s · ${DateTime.now().toUtc().toIso8601String()}</div>
  ${_reports.isEmpty ? '<div class="empty">Waiting for reports…</div>' : rows}
  <div class="actions">
    <form method="post" action="/reports" onsubmit="event.preventDefault();fetch('/reports',{method:'DELETE'}).then(()=>location.reload());">
      <button type="submit">Clear all</button>
    </form>
  </div>
</body>
</html>
''';
  req.response.headers.contentType = ContentType.html;
  req.response.write(html);
  req.response.close();
}

String _renderRow(Map<String, Object?> r) {
  final type = (r['type'] as String?) ?? 'manual';
  final cls = switch (type) {
    'exitThreat' => 'exit',
    'flutterError' => 'flutter',
    'dartError' => 'dart',
    'threatDetected' => 'threatDetected',
    _ => 'manual',
  };
  final device = (r['device'] as Map?)?.cast<String, Object?>() ?? const {};
  final app = (r['app'] as Map?)?.cast<String, Object?>() ?? const {};
  final user = (r['user'] as Map?)?.cast<String, Object?>() ?? const {};
  final extras = (r['extras'] as Map?)?.cast<String, Object?>() ?? const {};
  final breadcrumbs = (r['breadcrumbs'] as List?) ?? const [];
  final detected = (r['detectedThreats'] as List?) ?? const [];
  final msg = r['message'];
  final vuln = r['vulnerabilityKind'];
  final stack = r['stackTrace'];

  final threatTags = detected.map((t) =>
      '<span class="tag threat">${_escape(t.toString())}</span>').join(' ');

  return '''
<div class="row">
  <div class="head">
    <span class="tag $cls">$type</span>
    ${vuln != null ? '<span class="tag exit">$vuln</span>' : ''}
    $threatTags
  </div>
  ${msg != null ? '<div class="msg">${_escape(msg.toString())}</div>' : ''}

  <div class="grid">
    ${_kvSection('Device', _entries(device))}
    ${_kvSection('App', _entries(app))}
    ${user.isNotEmpty ? _kvSection('User', _entries(user)) : ''}
    ${extras.isNotEmpty ? _kvSection('Extras', _entries(extras)) : ''}
  </div>

  ${_breadcrumbsBlock(breadcrumbs)}
  ${stack != null ? '<details><summary>Stack trace (${stack.toString().split('\n').length} lines)</summary><pre>${_escape(stack.toString())}</pre></details>' : ''}

  <div class="meta">
    schema=${r['schemaVersion']} ·
    session=${r['sessionId']} ·
    report=${r['reportId']} ·
    ts=${r['timestamp']}
    ${r['_receivedAt'] != null ? ' · received=${r['_receivedAt']}' : ''}
    ${r['_hmac'] != null ? ' · hmac=${r['_hmac']}' : ''}
  </div>
</div>
''';
}

List<MapEntry<String, String>> _entries(Map<String, Object?> m) =>
    m.entries.map((e) => MapEntry(e.key, _stringify(e.value))).toList();

String _stringify(Object? v) {
  if (v == null) return '∅';
  if (v is String) return v;
  if (v is num || v is bool) return v.toString();
  return jsonEncode(v);
}

String _kvSection(String title, List<MapEntry<String, String>> entries) {
  if (entries.isEmpty) return '';
  final rows = entries.map((e) =>
      '<b>${_escape(e.key)}</b><span>${_escape(e.value)}</span>').join();
  return '<div class="sec"><h4>$title</h4><div class="kv">$rows</div></div>';
}

String _breadcrumbsBlock(List<Object?> crumbs) {
  if (crumbs.isEmpty) return '';
  final items = crumbs.map((c) {
    final m = (c as Map?)?.cast<String, Object?>() ?? const {};
    final ts = m['ts']?.toString() ?? '';
    final cat = m['category']?.toString() ?? '';
    final lvl = m['level']?.toString() ?? '';
    final msg = m['message']?.toString() ?? '';
    final data = m['data'];
    final dataStr = data == null ? '' : ' · ${_escape(jsonEncode(data))}';
    return '<div class="crumb">'
        '<span class="lvl">[$lvl]</span>'
        '<span class="cat">$cat</span> '
        '<span>${_escape(msg)}</span>'
        '<span class="ts"> · $ts$dataStr</span>'
        '</div>';
  }).join();
  return '<details open><summary>Breadcrumbs (${crumbs.length})</summary>$items</details>';
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

Future<List<int>> _drain(HttpRequest req) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in req) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
