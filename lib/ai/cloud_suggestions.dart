import 'dart:convert';

import 'package:http/http.dart' as http;

import 'suggestion.dart';

/// Клиент облачного ассистента. Ключ LLM-провайдера НИКОГДА не хранится в приложении:
/// запрос идёт на ваш сервер (см. папку server/), который уже обращается к модели.
///
/// Адрес сервера задаётся при сборке: --dart-define=AI_ENDPOINT=https://...
class CloudSuggestionClient {
  CloudSuggestionClient({String? endpoint, this.appToken = const String.fromEnvironment('AI_APP_TOKEN')})
      : endpoint = endpoint ?? const String.fromEnvironment('AI_ENDPOINT');

  final String endpoint;
  final String appToken;

  bool get isConfigured => endpoint.isNotEmpty;

  Future<List<Suggestion>> suggest({required String category, required List<String> items}) async {
    try {
      final resp = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              if (appToken.isNotEmpty) 'X-App-Token': appToken,
            },
            body: jsonEncode({'category': category, 'items': items, 'lang': 'ru'}),
          )
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final list = (data['suggestions'] as List? ?? const []);
      return list
          .whereType<Map<String, dynamic>>()
          .where((m) => (m['name'] as String?)?.isNotEmpty ?? false)
          .take(6)
          .map((m) => Suggestion(
                name: m['name'] as String,
                reason: (m['reason'] as String?) ?? 'совет ассистента',
                score: 2.5,
                source: SuggestionSource.cloud,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
