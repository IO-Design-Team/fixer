A framework to make large analysis options migrations easier

## Why

The `dart fix --apply` command can't fix everything, and fixing analysis issues by hand is a pain. The `fixer` package allows you to easily create your own fixers.

## How

Create and run a dart script containing your fixers:

<!-- embedme example/example.dart -->
```dart
import 'package:fixer/fixer.dart';

void main() {
  fix(
    {'public_member_api_docs': (_, line) => '/// TODO: Document this!\n$line'},
    workingDirectory: '../', // Optional
  );
}

```

This example adds placeholder doc comments to all public members. This would be useful if you just enabled the `public_member_api_docs` analysis option in a large project with minimal existing documentation.
