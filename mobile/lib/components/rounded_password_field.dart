import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/components/text_field_container.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/providers/theme_provider.dart';

class RoundedPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String hintText;

  const RoundedPasswordField({
    Key? key,
    required this.controller,
    this.validator,
    this.hintText = "Mật khẩu",
  }) : super(key: key);

  @override
  _RoundedPasswordFieldState createState() => _RoundedPasswordFieldState();
}

class _RoundedPasswordFieldState extends State<RoundedPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return TextFieldContainer(
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            cursorColor: themeProvider.primaryColor,
            validator: widget.validator,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white54
                    : Colors.grey[600],
              ),
              icon: Icon(
                Icons.lock,
                color: themeProvider.primaryColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: themeProvider.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}
