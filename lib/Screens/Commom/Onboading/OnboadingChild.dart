import 'package:flutter/material.dart';
import 'package:house_pal/ultils/enum/OnboardingPosition.dart';

class OnboadingChildScreen extends StatelessWidget {
  final Onboardingposition onboardingposition;
  final VoidCallback handleSkip;
  final VoidCallback handleNext;
  final VoidCallback handleBack;

  const OnboadingChildScreen({
    super.key,
    required this.onboardingposition,
    required this.handleSkip,
    required this.handleNext,
    required this.handleBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 252, 252, 252),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildButtonSkip(),
              _buildImage(),
              _buildDots(),
              _buildContent(),
              _buildItem(),
              _buildButtonBottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonSkip() {
    return Align(
      alignment: Alignment.topLeft,
      child: TextButton(
        onPressed: () {
          handleSkip();
        },
        child: const Text(
          'Bỏ qua',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image(
      image: AssetImage(onboardingposition.getPathImage()), // không có / đầu
      fit: BoxFit.contain,
      width: 271,
      height: 296,
    );
  }

  Widget _buildDots() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 7,
        children: [
          Container(
            height: 4,
            width: 26,
            decoration: BoxDecoration(
              color: onboardingposition == Onboardingposition.page1
                  ? Colors.white
                  : Colors.grey,
            ),
          ),
          Container(
            height: 4,
            width: 26,
            decoration: BoxDecoration(
              color: onboardingposition == Onboardingposition.page2
                  ? Colors.white
                  : Colors.grey,
            ),
          ),
          Container(
            height: 4,
            width: 26,
            decoration: BoxDecoration(
              color: onboardingposition == Onboardingposition.page3
                  ? Colors.white
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            onboardingposition.getTitle(),
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 26,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            onboardingposition.getDescription(),
            style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildItem() {
    final items = onboardingposition.getContent();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 50),

                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    size: 16,
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 200,
                  child: Text(
                    item['text'] as String,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtonBottom() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
      child: Row(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: TextButton(
              onPressed: () {
                handleBack();
              },
              child: const Text(
                'Trở về',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const Spacer(),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                handleNext();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                onboardingposition == Onboardingposition.page3
                    ? 'Bắt đầu'
                    : 'Tiếp theo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
