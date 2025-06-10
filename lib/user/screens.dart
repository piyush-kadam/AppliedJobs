import 'package:appliedjobs/user/start.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreensPage extends StatefulWidget {
  const ScreensPage({super.key});

  @override
  State<ScreensPage> createState() => _ScreensPageState();
}

class _ScreensPageState extends State<ScreensPage> {
  final List<String> images = [
    'assets/images/pos.jpg',
    'assets/images/pus.jpg',
  ];

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _navigateToStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const StartPage()),
    );
  }

  void _onNext() {
    if (_currentIndex < images.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.asset(
                    images[index],
                    fit:
                        BoxFit
                            .cover, // This makes image fill the space from top
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),
          ),
          // Button section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _currentIndex == 0 ? _onNext : _navigateToStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3D47D1),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
              ),
              child: Text(
                _currentIndex == 0 ? "Next" : "Let's Go",
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
