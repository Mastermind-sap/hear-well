import 'package:echo_aid/core/utils/services/validation/validation.dart';
import 'package:flutter/material.dart';

class SignUpInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final FormFieldValidator<String>? validator;

  const SignUpInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        obscureText: isPassword ? obscureText : false,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          fillColor: isDark ? Color(0xFF303030) : Colors.white,
          filled: true,
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: isPassword && suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixIconPressed,
                  icon: Icon(
                    suffixIcon,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
