// pages/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_difmo/pages/auth_screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    // {
    //   'image': 'assets/images/logo.png',
    //   'title': 'Seamless Design',
    //   'desc': 'Simplify your HR processes with flexibility.',
    // },
    {
      'image': 'assets/images/logo2.png',
      'title': 'Boost Productivity',
      'desc': 'Automate your daily workflow efficiently.',
    },
    {
      'image': 'assets/images/logo3.png',
      'title': 'All in One',
      'desc': 'Manage attendance, payroll, and more.',
    },
    {
      'image': 'assets/images/logo4.png',
      'title': 'Stay Notified',
      'desc': 'Get real-time updates and alerts.',
    },
    // {
    //   'image': 'assets/images/logo.png',
    //   'title': 'Collaborate Easily',
    //   'desc': 'Work together with your team seamlessly.',
    // },
    // {
    //   'image': 'assets/images/logo.png',
    //   'title': 'Let’s Get Started',
    //   'desc': 'Login and elevate your employee experience.',
    // },
  ];

  void _nextPage() {
    if (_currentPage == onboardingData.length - 1) {
      // Navigate to Login Screen
      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,

      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _skip,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      "Skip",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.asset(data['image']!, height: 250),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['title']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['desc']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Page Indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                onboardingData.length,
                                (dotIndex) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  height: 6,
                                  width: _currentPage == dotIndex ? 25 : 8,
                                  decoration: BoxDecoration(
                                    color: _currentPage == dotIndex
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Next / Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _nextPage,
                                child: Text(
                                  _currentPage == onboardingData.length - 1
                                      ? "Login"
                                      : "Next",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
