/// Form validators — all validation logic in one place
class AyushValidators {
  AyushValidators._();

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    // Remove spaces/dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    // Expect +91 followed by 10 digits
    if (!RegExp(r'^\+91\d{10}$').hasMatch(cleaned)) {
      return 'Enter a valid Indian phone number (+91XXXXXXXXXX)';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  /// Password strength: 0=empty, 1=weak, 2=fair, 3=strong
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 1) return 1; // Weak
    if (score <= 2) return 2; // Fair
    return 3; // Strong
  }
}
