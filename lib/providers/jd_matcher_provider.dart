import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/jd_match_result.dart';
import '../services/jd_matcher.dart';
import '../services/resume_service.dart';

class JdMatcherState {
  const JdMatcherState({
    this.selectedResumeId,
    this.result,
    this.isMatching = false,
    this.error,
  });

  final String? selectedResumeId;
  final JdMatchResult? result;
  final bool isMatching;
  final String? error;

  JdMatcherState copyWith({
    String? selectedResumeId,
    JdMatchResult? result,
    bool clearResult = false,
    bool? isMatching,
    String? error,
    bool clearError = false,
  }) =>
      JdMatcherState(
        selectedResumeId: selectedResumeId ?? this.selectedResumeId,
        result: clearResult ? null : (result ?? this.result),
        isMatching: isMatching ?? this.isMatching,
        error: clearError ? null : (error ?? this.error),
      );
}

class JdMatcherNotifier extends StateNotifier<JdMatcherState> {
  JdMatcherNotifier(this._resumeService) : super(const JdMatcherState());

  final ResumeService _resumeService;

  void selectResume(String resumeId) {
    state = state.copyWith(selectedResumeId: resumeId);
  }

  Future<void> matchJobDescription({
    required String jobDescription,
    required String resumeId,
    String jobTitle = '',
    String companyName = '',
  }) async {
    if (jobDescription.trim().isEmpty) {
      state = state.copyWith(error: 'Please paste a job description.');
      return;
    }

    state = state.copyWith(isMatching: true, clearError: true);
    try {
      final resume = await _resumeService.get(resumeId);
      final result = JdMatcher.match(
        jobDescription: jobDescription,
        resume: resume,
        jobTitle: jobTitle,
        companyName: companyName,
      );
      state = state.copyWith(
        selectedResumeId: resumeId,
        result: result,
        isMatching: false,
      );
    } catch (e) {
      state = state.copyWith(isMatching: false, error: e.toString());
    }
  }

  /// 1-Tap "Add Missing Skill": Adds the skill directly into the user's resume!
  Future<bool> addSkillToResume(String skill) async {
    final resumeId = state.selectedResumeId;
    if (resumeId == null) return false;

    try {
      final resume = await _resumeService.get(resumeId);
      if (!resume.skills.contains(skill)) {
        final updatedSkills = List<String>.from(resume.skills)..add(skill);
        final updatedResume = resume.copyWith(skills: updatedSkills);
        await _resumeService.update(updatedResume);

        // Update local result to move skill from missing to matched
        if (state.result != null) {
          final res = state.result!;
          final newMissing = List<String>.from(res.missingSkills)..remove(skill);
          final newMatched = List<String>.from(res.matchedSkills)..add(skill);
          final newScore = (res.matchScore + 5).clamp(0, 100);

          state = state.copyWith(
            result: JdMatchResult(
              matchScore: newScore,
              matchedSkills: newMatched,
              missingSkills: newMissing,
              jobTitle: res.jobTitle,
              companyName: res.companyName,
              recommendations: res.recommendations,
              analyzedAt: res.analyzedAt,
            ),
          );
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final jdMatcherProvider =
    StateNotifierProvider<JdMatcherNotifier, JdMatcherState>((ref) {
  return JdMatcherNotifier(ResumeService());
});
