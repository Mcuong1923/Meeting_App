import 'package:flutter/material.dart';
import 'package:metting_app/components/text_field_container.dart';
import 'package:metting_app/constants.dart';

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
    return TextFieldContainer(
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        cursorColor: kPrimaryColor,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hintText,
          icon: const Icon(
            Icons.lock,
            color: kPrimaryColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: kPrimaryColor,
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
  }
}
