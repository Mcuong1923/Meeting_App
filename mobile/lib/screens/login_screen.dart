import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/providers/theme_provider.dart';
import 'package:metting_app/components/background.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/screens/signup_screen.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/components/already_have_an_account_acheck.dart';
import 'package:metting_app/components/or_divider.dart';
import 'package:metting_app/components/social_icon.dart';
import 'package:metting_app/components/social_signup.dart';
import 'package:metting_app/components/rounded_input_field.dart';
import 'package:metting_app/components/rounded_password_field.dart';

class LoginScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;
  final bool showSuccessSnackbar;

  const LoginScreen({
    Key? key,
    this.initialEmail,
    this.initialPassword,
    this.showSuccessSnackbar = false,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showSuccessSnackbar) {
      // Ensure the snackbar is shown after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor:
              themeProvider.isDarkMode ? const Color(0xFF000000) : Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  LoginScreenTopImage(themeProvider: themeProvider),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: LoginForm(
                      initialEmail: widget.initialEmail,
                      initialPassword: widget.initialPassword,
                      themeProvider: themeProvider,
                    ),
                  ),
                  SocialSignUp(themeProvider: themeProvider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoginScreenTopImage extends StatelessWidget {
  final ThemeProvider themeProvider;

  const LoginScreenTopImage({
    Key? key,
    required this.themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "MEETING APP",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: SvgPicture.asset(
                "assets/icons/login.svg",
                colorFilter: themeProvider.isDarkMode
                    ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                    : null,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;
  final ThemeProvider themeProvider;

  const LoginForm({
    Key? key,
    this.initialEmail,
    this.initialPassword,
    required this.themeProvider,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
    passwordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              RoundedInputField(
                hintText: "Email của bạn",
                controller: emailController,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await authProvider.login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );

                            if (!mounted) return;

                            // Chuyển đến màn hình chính sau khi đăng nhập thành công
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );

                            // Không cần snackbar ở đây nữa vì màn hình đã chuyển
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Đăng nhập",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: defaultPadding),
              AlreadyHaveAnAccountCheck(
                themeProvider: widget.themeProvider,
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
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
