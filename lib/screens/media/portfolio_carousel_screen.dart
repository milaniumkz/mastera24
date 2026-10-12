import 'package:flutter/material.dart';

import '../../widgets/safe_network_image.dart';

class PortfolioCarouselScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const PortfolioCarouselScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<PortfolioCarouselScreen> createState() =>
      _PortfolioCarouselScreenState();
}

class _PortfolioCarouselScreenState extends State<PortfolioCarouselScreen> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Портфолио')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final url = widget.images[index];
                return Center(
                  child: InteractiveViewer(
                    child: SafeNetworkImage(imageUrl: url, fit: BoxFit.contain),
                  ),
                );
              },
            ),
          ),
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black26,
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
