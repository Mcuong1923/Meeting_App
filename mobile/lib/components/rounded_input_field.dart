import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/components/text_field_container.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/providers/theme_provider.dart';

class RoundedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;

  const RoundedInputField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.icon = Icons.person,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return TextFieldContainer(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            cursorColor: themeProvider.primaryColor,
            validator: validator,
            maxLines: maxLines,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              icon: Icon(
                icon,
                color: themeProvider.primaryColor,
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white54
                    : Colors.grey[600],
              ),
              border: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}
