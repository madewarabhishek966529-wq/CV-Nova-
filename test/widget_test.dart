import 'package:flutter_test/flutter_test.dart';
import 'package:cvnova/main.dart';
import 'package:cvnova/services/ats_scorer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AtsScorer evaluates resume text correctly', () {
    const sampleResume = '''
John Doe
john.doe@example.com | +1 555-123-4567

Summary
Experienced software engineer with a strong track record.

Experience
• Led architecture of mobile app in Flutter, scaling to 100,000 active users.
• Developed REST APIs with 99.9% uptime and reduced latency by 35%.
• Spearheaded automated test suites and improved developer productivity.

Education
• Bachelor of Science in Computer Science

Skills
• Flutter, Dart, Python, SQL, Git, AWS, Docker, Kubernetes
''';

    final result = AtsScorer.score(sampleResume, targetKeywords: ['flutter', 'python', 'aws']);
    expect(result.wordCount, greaterThan(30));
    expect(result.score.overall, greaterThan(40));
    expect(result.score.keywords, 100);
    expect(result.score.impact, greaterThan(40));
    expect(result.feedback.strengths, isNotEmpty);
  });

  testWidgets('CVNovaApp boots and renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CVNovaApp()));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CVNovaApp), findsOneWidget);
  });
}
