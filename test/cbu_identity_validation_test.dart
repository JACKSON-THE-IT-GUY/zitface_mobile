import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/services/cbu_identity_validation.dart';

void main() {
  test('accepts eight-digit SINs with two-digit years from 19 through 27', () {
    expect(isValidCbuStudentSin('19125724'), isTrue);
    expect(isValidCbuStudentSin('20125724'), isTrue);
    expect(isValidCbuStudentSin('23125724'), isTrue);
    expect(isValidCbuStudentSin('27125724'), isTrue);
  });

  test('rejects SINs outside the year range or eight-digit format', () {
    expect(isValidCbuStudentSin('18125724'), isFalse);
    expect(isValidCbuStudentSin('28125724'), isFalse);
    expect(isValidCbuStudentSin('2012572'), isFalse);
    expect(isValidCbuStudentSin('201257245'), isFalse);
    expect(isValidCbuStudentSin('2A125724'), isFalse);
  });
}