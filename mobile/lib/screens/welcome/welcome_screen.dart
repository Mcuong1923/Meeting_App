import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../login_screen.dart';
import '../signup_screen.dart';
import '../../components/background.dart';
import '../../constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Background(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "WELCOME TO MEETING APP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                SvgPicture.asset(
                  "assets/icons/chat.svg",
                  height: size.height * 0.45,
                ),
                SizedBox(height: size.height * 0.05),
                Container(
                  width: size.width * 0.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return LoginScreen();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 40),
                      ),
                      child: const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: size.width * 0.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return SignUpScreen();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryLightColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 40),
                      ),
                      child: const Text(
                        "ĐĂNG KÝ",
                        style: TextStyle(color: kTextColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
