import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/food_item.dart';

const _uuid = Uuid();
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _model = 'llama-3.3-70b-versatile';

/// Chat service using Groq API with conversation history support.
/// Maintains context about the user's fridge inventory.
class GroqChatService {
  GroqChatService._();
  static GroqChatService? _instance;
  static GroqChatService get instance => _instance ??= GroqChatService._();

  String get _apiKey => dotenv.maybeGet('GROQ_API_KEY') ?? '';
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Conversation history (system + user + assistant messages).
  final List<ChatMessage> _history = [];
  List<ChatMessage> get history => List.unmodifiable(_history);

  void clearHistory() => _history.clear();

  /// System prompt with optional inventory context.
  String _buildSystemPrompt(String language, List<FoodItem> inventory) {
    final ingredientList = inventory.isEmpty
        ? (language == 'VIE'
            ? 'Người dùng chưa có thực phẩm nào trong kho.'
            : 'The user has no food items in their inventory.')
        : inventory.map((item) {
            final expiry = item.daysUntilExpiry;
            final expiryNote = expiry != null
                ? (language == 'VIE'
                    ? ' (còn ${expiry < 0 ? 'đã hết hạn' : '$expiry ngày'})'
                    : ' (${expiry < 0 ? 'expired' : '$expiry days left'})')
                : '';
            return '- ${item.name}: ${item.quantity} ${item.unit}$expiryNote [${item.category.value}]';
          }).join('\n');

    if (language == 'VIE') {
      return '''Bạn là AI Chef - một đầu bếp AI thân thiện thông qua trò chuyện, chuyên gia về ẩm thực đặc biệt là món Việt Nam. Bạn trợ giúp người dùng về:
- Gợi ý công thức nấu ăn dựa trên nguyên liệu có sẵn
- Tư vấn bảo quản thực phẩm
- Giải thích kỹ thuật nấu ăn
- Lên thực đơn hàng ngày/tuần
- Mẹo giảm lãng phí thực phẩm

📦 **Kho thực phẩm hiện tại của người dùng:**
$ingredientList

Quy tắc:
1. Luôn tham khảo nguyên liệu trong kho để gợi ý phù hợp.
2. Ưu tiên sử dụng nguyên liệu sắp hết hạn.
3. Trả lời thân thiện, dễ hiểu với emoji phù hợp.
4. Nếu gợi ý công thức, trình bày rõ: tên món, nguyên liệu, các bước ngắn gọn.
5. Có thể hỏi thêm về sở thích, dị ứng, khẩu phần.
6. Nếu người dùng hỏi ngoài phạm vi nấu ăn, hãy nhẹ nhàng hướng trở lại chủ đề thực phẩm/nấu ăn.
7. Trả lời bằng tiếng Việt.''';
    } else {
      return '''You are AI Chef - a friendly conversational AI chef, an expert in cooking especially Vietnamese cuisine. You help users with:
- Recipe suggestions based on available ingredients
- Food preservation advice
- Cooking technique explanations
- Daily/weekly meal planning
- Tips to reduce food waste

📦 **User's current food inventory:**
$ingredientList

Rules:
1. Always reference the inventory when suggesting recipes.
2. Prioritize ingredients that are expiring soon.
3. Be friendly, clear, and use appropriate emojis.
4. When suggesting a recipe, clearly state: name, ingredients, brief steps.
5. You may ask about preferences, allergies, or serving sizes.
6. If asked about non-food topics, gently redirect to food/cooking.
7. Respond in English.''';
    }
  }

  /// Send a user message and get AI response.
  Future<ChatMessage> sendMessage(
    String userMessage,
    List<FoodItem> inventory,
    String language,
  ) async {
    if (!isConfigured) {
      throw Exception('Groq API key not configured');
    }

    // Add user message to history
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: userMessage,
      timestamp: DateTime.now(),
    );
    _history.add(userMsg);

    // Build messages for API
    final systemPrompt = _buildSystemPrompt(language, inventory);
    final apiMessages = [
      {'role': 'system', 'content': systemPrompt},
      ..._history.map((m) => m.toApiMap()),
    ];

    final response = await http.post(
      Uri.parse(_groqEndpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': apiMessages,
        'temperature': 0.8,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (body['choices'] as List)[0]['message']['content'] as String;

    // Add assistant response to history
    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    _history.add(assistantMsg);

    return assistantMsg;
  }

  /// Quick prompt suggestions based on inventory state.
  List<String> getQuickPrompts(String language, List<FoodItem> inventory) {
    final expiring =
        inventory.where((i) => i.isExpiringSoon || i.isExpired).toList();

    if (language == 'VIE') {
      return [
        if (inventory.isEmpty)
          'Gợi ý món ăn đơn giản cho người mới bắt đầu'
        else
          'Gợi ý món ăn từ tủ lạnh của tôi',
        if (expiring.isNotEmpty)
          'Làm món gì với ${expiring.first.name} sắp hết hạn?'
        else
          'Cách bảo quản rau củ tươi lâu hơn?',
        'Gợi ý thực đơn cho 3 ngày',
        'Mẹo nấu ăn hàng ngày',
      ];
    } else {
      return [
        if (inventory.isEmpty)
          'Suggest simple recipes for beginners'
        else
          'Suggest recipes from my fridge',
        if (expiring.isNotEmpty)
          'What to cook with ${expiring.first.name} expiring soon?'
        else
          'How to keep vegetables fresh longer?',
        'Suggest a 3-day meal plan',
        'Daily cooking tips',
      ];
    }
  }
}
