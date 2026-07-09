import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatNotifier(apiClient);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final _apiClient;

  ChatNotifier(this._apiClient) : super([]);

  Future<void> sendMessage(String text, {String? context}) async {
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final aiLoadingMessage = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    // Append user message and loading indicator
    state = [...state, userMessage, aiLoadingMessage];

    try {
      final response = await _apiClient.post('/ai/chat', data: {
        'message': text,
        'context': context,
      });

      if (response.statusCode == 200) {
        final answer = response.data['response'] as String;
        final aiMessage = ChatMessage(
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
        );
        // Replace loading message with the AI answer
        state = [...state.sublist(0, state.length - 1), aiMessage];
      } else {
        _setErrorMessage('Server returned error status: ${response.statusCode}');
      }
    } catch (e) {
      _setErrorMessage('Network timeout. Unable to reach local Qwen3:8B engine.');
    }
  }

  void _setErrorMessage(String error) {
    final aiErrorMessage = ChatMessage(
      text: error,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state.sublist(0, state.length - 1), aiErrorMessage];
  }

  void clearHistory() {
    state = [];
  }
}
