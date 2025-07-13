import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/providers/theme_provider.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/components/or_divider.dart';
import 'package:metting_app/components/social_icon.dart';

class SocialSignUp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const SocialSignUp({
    Key? key,
    required this.themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OrDivider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SocialIcon(
              iconSrc: "assets/icons/facebook.svg",
              press: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            SocialIcon(
              iconSrc: "assets/icons/twitter.svg",
              press: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            Consumer<app_auth.AuthProvider>(
              builder: (context, authProvider, child) => SocialIcon(
                iconSrc: "assets/icons/google-plus.svg",
                press: () async {
                  try {
                    await authProvider.signInWithGoogle();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng nhập với Google thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
