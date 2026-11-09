enum SuggestionSource { rules, history, cloud }

class Suggestion {
  Suggestion({required this.name, required this.reason, required this.score, required this.source});
  final String name;

  /// Короткое объяснение: «к товару „Гвозди“», «часто покупаете».
  final String reason;
  final double score;
  final SuggestionSource source;
}
