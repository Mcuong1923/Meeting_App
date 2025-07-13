import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/providers/theme_provider.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/screens/login_screen.dart' show LoginScreen;
import 'package:metting_app/components/already_have_an_account_acheck.dart';
import 'package:metting_app/components/or_divider.dart';
import 'package:metting_app/components/social_icon.dart';
import 'package:metting_app/components/social_signup.dart';
import 'package:metting_app/components/rounded_input_field.dart';
import 'package:metting_app/components/rounded_password_field.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor:
              themeProvider.isDarkMode ? const Color(0xFF000000) : Colors.white,
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                SignUpScreenTopImage(themeProvider: themeProvider),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SignUpForm(themeProvider: themeProvider),
                ),
                SocialSignUp(themeProvider: themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SignUpScreenTopImage extends StatelessWidget {
  final ThemeProvider themeProvider;

  const SignUpScreenTopImage({
    Key? key,
    required this.themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "MEETING APP".toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: defaultPadding),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: SvgPicture.asset(
                "assets/icons/signup.svg",
                colorFilter: themeProvider.isDarkMode
                    ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                    : null,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding),
      ],
    );
  }
}

class SignUpForm extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SignUpForm({
    Key? key,
    required this.themeProvider,
  }) : super(key: key);

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              RoundedInputField(
                controller: emailController,
                hintText: "Email của bạn",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              RoundedPasswordField(
                controller: passwordController,
                hintText: "Mật khẩu của bạn",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu tối thiểu 6 ký tự';
                  }
                  return null;
                },
              ),
              RoundedPasswordField(
                controller: confirmPasswordController,
                hintText: "Nhập lại mật khẩu",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập lại mật khẩu';
                  }
                  if (value != passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: defaultPadding / 2),
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          try {
                            await authProvider.signup(email, password);

                            if (!mounted) return;

                            // Chuyển đến màn hình đăng nhập với thông tin vừa đăng ký
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(
                                  initialEmail: email,
                                  initialPassword: password,
                                  showSuccessSnackbar: true,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeProvider.primaryColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "ĐĂNG KÝ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: defaultPadding),
              AlreadyHaveAnAccountCheck(
                login: false,
                themeProvider: widget.themeProvider,
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
