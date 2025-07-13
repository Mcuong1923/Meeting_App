import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/providers/theme_provider.dart';

class TextFieldContainer extends StatelessWidget {
  final Widget child;

  const TextFieldContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: size.width * 0.9,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color(0xFF2C2C2E)
                : kPrimaryLightColor,
            borderRadius: BorderRadius.circular(29),
            border: themeProvider.isDarkMode
                ? Border.all(color: const Color(0xFF38383A))
                : null,
          ),
          child: this.child,
        );
      },
    );
  }
}
