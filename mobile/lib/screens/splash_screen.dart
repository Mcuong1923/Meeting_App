import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/screens/welcome/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Đang khởi tạo...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _status = 'Đang kiểm tra xác thực...';
      });

      // Đợi một chút để UI render
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Lấy AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      setState(() {
        _status = 'Đang xác thực người dùng...';
      });

      // Kiểm tra trạng thái đăng nhập (AuthProvider tự động check khi khởi tạo)

      setState(() {
        _status = 'Đang chuyển hướng...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate dựa trên trạng thái
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      print('Lỗi khởi tạo: $e');
      setState(() {
        _status = 'Lỗi khởi tạo: $e';
      });

      // Fallback về WelcomeScreen sau 3 giây
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc icon ứng dụng
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.meeting_room,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 30),

            // Tên ứng dụng
            const Text(
              'Meeting App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),

            // Status text
            Text(
              _status,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
