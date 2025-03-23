class Validator {

  static String? validateEmail(String? value) {
    if(value == null) {
      return 'Email cannot be empty';
    }
    if (value.isEmpty) {
      return 'Email cannot be empty';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }


  static String? validateUsername(String? value) 
  {
    if(value == null) {
      return 'Email cannot be empty';
    }

    if (value.isEmpty) {
      return 'Username cannot be empty';
    }
    
    if (value.length > 10) {
      return 'Username should be less than 10 characters';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if(value == null) {
      return 'Email cannot be empty';
    }
    
    if (value.isEmpty) {
      return 'Password cannot be empty';
    }
    
    if (value.length < 8) {
      return 'Password should be at least 8 characters';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    if (!hasUppercase) {
      return 'Password should contain at least one uppercase letter';
    }

    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    if (!hasLowercase) {
      return 'Password should contain at least one lowercase letter';
    }

    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    if (!hasDigit) {
      return 'Password should contain at least one numeric digit';
    }

    final hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    if (!hasSymbol) {
      return 'Password should contain at least one symbol';
    }
    
    return null;
  }
}
