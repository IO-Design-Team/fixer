import 'package:fixer/fixer.dart';

void main() {
  fix(
    {'public_member_api_docs': (_, line) => '/// TODO: Document this!\n$line'},
    workingDirectory: '../', // Optional
  );
}
