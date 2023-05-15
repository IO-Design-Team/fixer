import 'package:fixer/fixer.dart';
import 'package:test/test.dart';

void main() {
  fix({
    'public_member_api_docs': (line) => line,
  });
}
