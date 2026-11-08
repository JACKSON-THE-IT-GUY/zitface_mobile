bool isValidCbuStudentSin(String value) {
  return RegExp(r'^(19|2[0-7])[0-9]{6}$').hasMatch(value.trim());
}