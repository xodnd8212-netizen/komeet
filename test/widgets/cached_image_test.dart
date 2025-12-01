import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:komeet/widgets/cached_image.dart';

void main() {
  testWidgets('CachedImage displays placeholder while loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CachedImage(
            imageUrl: 'https://example.com/image.jpg',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );

    // Placeholder가 표시되는지 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CachedImage applies borderRadius', (WidgetTester tester) async {
    const borderRadius = BorderRadius.all(Radius.circular(8));
    
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CachedImage(
            imageUrl: 'https://example.com/image.jpg',
            borderRadius: borderRadius,
          ),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
  });
}

