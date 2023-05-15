import 'dart:io';

import 'package:collection/collection.dart';
import 'package:parselyzer/parselyzer.dart';

typedef Fixer = String Function(AnalyzerDiagnostic diagnostic, String content);
typedef LineFixer = String Function(String line);
typedef RangeFixer = String Function(String range);

Fixer fixLine(LineFixer fixer) => (diagnostic, content) {
      final lines = content.split('\n');
      final lineNumber = diagnostic.location.range.start.line - 1;
      lines[lineNumber] = fixer(lines[lineNumber]);
      return lines.join('\n');
    };

Fixer fixRange(RangeFixer fixer) => (diagnostic, content) {
      final start = diagnostic.location.range.start.offset;
      final end = diagnostic.location.range.end.offset;

      return content.replaceRange(
        start,
        end,
        fixer(content.substring(start, end)),
      );
    };

void fix(Map<String, Fixer> fixers) {
  final result = Process.runSync('dart', ['analyze', '--format=json']);
  final analysis = AnalyzerResult.fromConsole(result.stdout as String);

  if (analysis == null) {
    throw 'Failed to parse lint result. This might mean there are no lint issues.';
  }

  final diagnosticsByFile =
      analysis.diagnostics.groupListsBy((e) => e.location.file);

  for (final entry in diagnosticsByFile.entries) {
    final file = File(entry.key);
    final diagnostics = entry.value;

    var content = file.readAsStringSync();
    for (final diagnostic in diagnostics) {
      final fixer = fixers[diagnostic.code];
      if (fixer == null) continue;
      content = fixer(diagnostic, content);
    }

    file.writeAsStringSync(content);
  }
}
