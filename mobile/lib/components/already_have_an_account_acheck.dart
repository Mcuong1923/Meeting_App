import 'package:flutter/material.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/providers/theme_provider.dart';

class AlreadyHaveAnAccountCheck extends StatelessWidget {
  final bool login;
  final VoidCallback press;
  final ThemeProvider? themeProvider;

  const AlreadyHaveAnAccountCheck({
    Key? key,
    this.login = true,
    required this.press,
    this.themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = themeProvider?.primaryColor ?? kPrimaryColor;
    final textColor =
        themeProvider?.isDarkMode == true ? Colors.white70 : Colors.black54;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          login ? "Chưa có tài khoản? " : "Đã có tài khoản? ",
          style: TextStyle(color: textColor),
        ),
        GestureDetector(
          onTap: press,
          child: Text(
            login ? "Đăng ký" : "Đăng nhập",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
