import 'dart:io';

import 'package:collection/collection.dart';
import 'package:parselyzer/parselyzer.dart';

/// A function that fixes an analysis issue on a line
typedef Fixer = String Function(AnalyzerDiagnostic diagnostic, String line);

/// Fix all files in the current directory or [workingDirectory] if provided
///
/// [fixers] is a map of [Fixer]s keyed by the lint code they fix
void fix(Map<String, Fixer> fixers, {String? workingDirectory}) {
  if (workingDirectory != null) {
    Directory.current = workingDirectory;
  }

  final result = Process.runSync('dart', ['analyze', '--format=json']);
  final analysis = AnalyzerResult.fromConsole(result.stdout as String);

  if (analysis == null) {
    throw 'Failed to parse lint result. This might mean there are no lint issues.';
  }

  final diagnosticsByFile =
      analysis.diagnostics.groupListsBy((e) => e.location.file);

  for (final entry in diagnosticsByFile.entries) {
    final file = File(entry.key);
    final diagnosticsByLine = {
      for (final diagnostic in entry.value)
        diagnostic.location.range.start.line: diagnostic,
    };

    // Don't read the file if there are no diagnostics
    if (diagnosticsByLine.isEmpty) continue;

    final content = file.readAsLinesSync().mapIndexed((index, line) {
      final diagnostic = diagnosticsByLine[index + 1];
      if (diagnostic == null) return line;

      final fixer = fixers[diagnostic.code];
      if (fixer == null) return line;

      return fixer(diagnostic, line);
    }).join('\n');

    file.writeAsStringSync(content);
  }
}
