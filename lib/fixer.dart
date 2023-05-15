import 'dart:io';

import 'package:collection/collection.dart';
import 'package:parselyzer/parselyzer.dart';
import 'package:path/path.dart';

typedef Fixer = String Function(AnalyzerDiagnostic diagnostic, String content);
typedef LineFixer = String Function(String line);

Fixer fixLine(LineFixer fixer) => (diagnostic, content) {
      final lines = content.split('\n');
      final lineNumber = diagnostic.location.range.start.line - 1;
      lines[lineNumber] = fixer(lines[lineNumber]);
      return lines.join('\n');
    };

void fix(Map<String, Fixer> fixers, {String? workingDirectory}) {
  if (workingDirectory != null) {
    Directory.current = workingDirectory;
  }

  print('Analyzing...');
  final result = Process.runSync('dart', ['analyze', '--format=json']);
  final analysis = AnalyzerResult.fromConsole(result.stdout as String);

  if (analysis == null) {
    throw 'Failed to parse lint result. This might mean there are no lint issues.';
  }

  final diagnosticsByFile =
      analysis.diagnostics.groupListsBy((e) => e.location.file);

  for (final entry in diagnosticsByFile.entries) {
    final file = File(entry.key);
    final relativeFilePath = relative(file.path);
    final diagnostics = entry.value;

    // Don't read the file if there are no diagnostics
    if (diagnostics.isEmpty) continue;

    var content = file.readAsStringSync();
    for (final diagnostic in diagnostics) {
      final fixer = fixers[diagnostic.code];
      if (fixer == null) continue;
      content = fixer(diagnostic, content);
      print(
        'Fixed ${diagnostic.code} in $relativeFilePath on line ${diagnostic.location.range.start.line}',
      );
    }

    file.writeAsStringSync(content);
  }
}
