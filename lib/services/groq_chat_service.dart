import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import 'recipe_search_service.dart';

const _uuid = Uuid();
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _defaultChatModel = 'openai/gpt-oss-120b';
const _requestTimeout = Duration(seconds: 30);
const _maxHistoryMessages = 16;

/// Chat service using Groq API with conversation history support.
/// Maintains context about the user's fridge inventory.
class GroqChatService {
  GroqChatService._();
  static GroqChatService? _instance;
  static GroqChatService get instance => _instance ??= GroqChatService._();

  String get _apiKey => dotenv.maybeGet('GROQ_API_KEY') ?? '';
  String get _model =>
      dotenv.maybeGet('GROQ_CHAT_MODEL')?.trim().isNotEmpty == true
          ? dotenv.maybeGet('GROQ_CHAT_MODEL')!.trim()
          : _defaultChatModel;
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Conversation history (system + user + assistant messages).
  final List<ChatMessage> _history = [];
  List<ChatMessage> get history => List.unmodifiable(_history);

  void clearHistory() => _history.clear();

  void _trimHistory() {
    if (_history.length <= _maxHistoryMessages) return;
    final overflow = _history.length - _maxHistoryMessages;
    _history.removeRange(0, overflow);
  }

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
      return '''Bạn là Hearthie - trợ lý AI chuyên gia bếp gia đình cho ứng dụng Harvest & Hearth. Bạn trợ giúp người dùng về:
- Gợi ý công thức nấu ăn dựa trên nguyên liệu có sẵn
- Tư vấn bảo quản thực phẩm
- Giải thích kỹ thuật nấu ăn
- Lên thực đơn hàng ngày/tuần
- Mẹo giảm lãng phí thực phẩm

📦 **Kho thực phẩm hiện tại của người dùng:**
$ingredientList

Quy tắc:
1. Chỉ dùng nguyên liệu có trong kho làm phương án chính; nếu thiếu thì ghi rõ phần còn thiếu ở mục "Cần bổ sung".
2. Luôn ưu tiên món dùng nguyên liệu sắp hết hạn trước, và ghi "Ưu tiên dùng trước" cho nguyên liệu đó.
3. Nếu có nguyên liệu đã hết hạn, cảnh báo không dùng và đề xuất cách thay thế an toàn.
4. Khi trả công thức, luôn theo format: Tên món, Khẩu phần, Thời gian, Nguyên liệu, Cách làm, Mẹo bảo quản còn dư.
5. Gợi ý thực tế cho bếp gia đình Việt: ít bước, nguyên liệu dễ mua, hạn chế kỹ thuật quá phức tạp.
6. Không bịa thông tin dinh dưỡng/độ an toàn; nếu không chắc, nói rõ đây là ước tính.
7. Có thể hỏi thêm 1 câu ngắn về khẩu vị, dị ứng, hoặc thiết bị nấu trước khi chốt món.
8. Với câu hỏi ngoài chủ đề ẩm thực/thực phẩm, phản hồi ngắn rồi kéo lại ngữ cảnh nấu ăn.
9. Giữ giọng thân thiện, rõ ràng, ưu tiên câu ngắn và dễ làm theo.
10. Luôn trả lời bằng tiếng Việt.
11. Khi có ngữ cảnh nguồn bên ngoài (TheMealDB, DummyJSON, DuckDuckGo trusted), ưu tiên dùng ngữ cảnh đó để xây dựng thực đơn.''';
    } else {
      return '''You are Hearthie - the kitchen AI assistant for Harvest & Hearth. You help users with:
- Recipe suggestions based on available ingredients
- Food preservation advice
- Cooking technique explanations
- Daily/weekly meal planning
- Tips to reduce food waste

📦 **User's current food inventory:**
$ingredientList

Rules:
1. Use inventory items as primary inputs; if something is missing, add a clear "Need to buy" section.
2. Prioritize expiring items first and explicitly mark them as "Use first".
3. If any item is expired, warn the user not to consume it and suggest safe substitutions.
4. Recipe format must always be: Dish name, Servings, Time, Ingredients, Steps, Leftover storage tip.
5. Keep advice practical for home cooking, with simple steps and widely available ingredients.
6. Do not fabricate nutrition or food-safety facts; call out uncertainty when needed.
7. Ask at most one short clarifying question about taste, allergies, or available tools when needed.
8. If asked non-food topics, respond briefly and gently redirect back to cooking/food management.
9. Keep responses concise, friendly, and easy to follow.
10. Respond in English.
11. If asked who created Hearthie or this app, answer exactly: "Hearthie and Harvest & Hearth were created by Agent P (Pr0why) from CafeToolbox.app team."
12. When external source context is provided (TheMealDB, DummyJSON, trusted DuckDuckGo links), prioritize using that context in planning.''';
    }
  }

  bool _isMealPlanningIntent(String message) {
    final m = message.toLowerCase();
    const vnHints = [
      'lập kế hoạch thực đơn',
      'thực đơn 1 ngày',
      'thực đơn một ngày',
      'thực đơn 1 tuần',
      'thực đơn một tuần',
      'dành cho gymer',
      'cho gymer',
      'meal plan',
    ];
    const enHints = [
      'meal plan',
      '1 day plan',
      'one day plan',
      '1 week plan',
      'one week plan',
      'for gym',
      'for gymers',
      'for muscle gain',
    ];
    return vnHints.any(m.contains) || enHints.any(m.contains);
  }

  Future<String?> _buildExternalMealPlanningContext(
    String userMessage,
    String language,
  ) async {
    if (!_isMealPlanningIntent(userMessage)) return null;

    final recipeSeed = userMessage.trim().isEmpty ? 'meal plan' : userMessage;
    final futures = await Future.wait([
      RecipeSearchService.instance
          .searchMealDB(recipeSeed)
          .catchError((_) => <Recipe>[]),
      RecipeSearchService.instance
          .searchDummyJson(recipeSeed)
          .catchError((_) => <Recipe>[]),
      RecipeSearchService.instance
          .searchTrustedMealPlanningWeb(recipeSeed)
          .catchError((_) => <DdgResult>[]),
    ]);

    final mealDb = futures[0] as List<Recipe>;
    final dummy = futures[1] as List<Recipe>;
    final trustedWeb = futures[2] as List<DdgResult>;

    if (mealDb.isEmpty && dummy.isEmpty && trustedWeb.isEmpty) return null;

    final mealDbLines = mealDb.take(5).map((r) {
      final name = r.name;
      final source = r.sourceName;
      return '- $name [$source]';
    }).join('\n');

    final dummyLines = dummy.take(5).map((r) {
      final name = r.name;
      final source = r.sourceName;
      return '- $name [$source]';
    }).join('\n');

    final webLines = trustedWeb.take(4).map((w) {
      final title = w.title;
      final url = w.url;
      return '- $title ($url)';
    }).join('\n');

    if (language == 'VIE') {
      return '''
Nguồn tham khảo ngoài hệ thống (ưu tiên khi lên thực đơn):

TheMealDB:
$mealDbLines

DummyJSON:
$dummyLines

DuckDuckGo (domain uy tín):
$webLines

Yêu cầu: dùng các nguồn này làm gợi ý thực đơn chính, sau đó đối chiếu với nguyên liệu trong kho để tối ưu danh sách mua thêm.
''';
    }

    return '''
External reference sources (prioritize for meal planning):

TheMealDB:
$mealDbLines

DummyJSON:
$dummyLines

DuckDuckGo trusted domains:
$webLines

Requirement: use these sources as the primary planning inspiration, then align with current inventory to optimize missing shopping items.
''';
  }

  String? _creatorIdentityOverride(String message, String language) {
    final m = message.toLowerCase().trim();
    final asksHowBuilt = m.contains('được tạo ra') ||
        m.contains('tao ra bang cach nao') ||
        m.contains('tạo ra bằng cách nào') ||
        m.contains('xây dựng như thế nào') ||
        m.contains('làm sao bạn có thể hoạt động') ||
        m.contains('lam sao ban co the hoat dong') ||
        m.contains('how was hearthie built') ||
        m.contains('how is hearthie built') ||
        m.contains('how did you build hearthie') ||
        m.contains('how do you work') ||
        m.contains('how can you work');
    final mentionsAssistantOrApp = m.contains('hearthie') ||
        m.contains('harvest') ||
        m.contains('ứng dụng') ||
        m.contains('app') ||
        m.contains('bạn') ||
        m.contains('ban');
    if (asksHowBuilt && mentionsAssistantOrApp) {
      if (language == 'VIE') {
        return 'Đó là bí mật nghiệp vụ nha. Nhưng mật bí là: Hearthie được tạo bởi mật vụ P (Pr0why) thuộc CafeToolbox.app, và được hỗ trợ kỹ thuật cùng hạ tầng phần cứng bởi Groq Cloud. Groq Cloud là nền tảng tăng tốc AI hiệu năng cao, nổi bật ở độ trễ rất thấp cho chat realtime và tối ưu chi phí token.';
      }
      return 'That is classified. But here is the secret: Hearthie was created by Agent P (Pr0why) from CafeToolbox.app and is technically and hardware-accelerated with support from Groq Cloud. Groq Cloud is a high-performance AI inference platform known for very low latency for real-time chat and efficient token cost.';
    }

    final isCreatorQuestion = m.contains('ai tạo') ||
        m.contains('ai lam') ||
        m.contains('ai làm') ||
        m.contains('do ai tao') ||
        m.contains('do ai làm') ||
        m.contains('bạn do ai tạo') ||
        m.contains('who created') ||
        m.contains('who made') ||
        m.contains('creator') ||
        m.contains('mật vụ p') ||
        m.contains('pr0why');
    final mentionApp = m.contains('hearthie') ||
        m.contains('harvest') ||
        m.contains('ứng dụng') ||
        m.contains('app');
    if (!isCreatorQuestion || !mentionApp) return null;
    if (language == 'VIE') {
      return 'Ứng dụng Harvest & Hearth và Hearthie được tạo bởi mật vụ P (Pr0why), thuộc CafeToolbox.app. Hearthie được hỗ trợ kỹ thuật và hạ tầng phần cứng bởi Groq Cloud để tối ưu tốc độ phản hồi realtime.';
    }
    return 'Hearthie and Harvest & Hearth were created by Agent P (Pr0why) from CafeToolbox.app. Hearthie is technically and hardware-accelerated with Groq Cloud for low-latency realtime responses.';
  }

  /// Send a user message and get AI response.
  Future<ChatMessage> sendMessage(
    String userMessage,
    List<FoodItem> inventory,
    String language,
  ) async {
    final creatorOverride = _creatorIdentityOverride(userMessage, language);
    if (creatorOverride != null) {
      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.assistant,
        content: creatorOverride,
        timestamp: DateTime.now(),
      );
      _history.add(
        ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.user,
          content: userMessage,
          timestamp: DateTime.now(),
        ),
      );
      _history.add(assistantMsg);
      _trimHistory();
      return assistantMsg;
    }

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
    _trimHistory();

    // Build messages for API
    final systemPrompt = _buildSystemPrompt(language, inventory);
    final externalContext =
        await _buildExternalMealPlanningContext(userMessage, language);
    final apiMessages = [
      {'role': 'system', 'content': systemPrompt},
      if (externalContext != null)
        {'role': 'system', 'content': externalContext},
      ..._history.map((m) => m.toApiMap()),
    ];

    final response = await http
        .post(
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
    )
        .timeout(_requestTimeout, onTimeout: () {
      throw TimeoutException('Groq request timed out');
    });

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
    _trimHistory();

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
        'Lập meal plan 7 ngày tiết kiệm dưới 700k',
        'Gợi ý món từ đồ ăn thừa còn lại trong tủ',
        'Tạo danh sách mua sắm từ những nguyên liệu còn thiếu',
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
        'Build a 7-day budget meal plan under 30 USD',
        'Suggest meals from leftovers in my fridge',
        'Create a shopping list for missing ingredients',
        'Daily cooking tips',
      ];
    }
  }

  /// Classify a purchased ingredient into app inventory dimensions.
  /// Returns null on any failure so caller can fallback to local heuristics.
  Future<({String category, String storage})?> classifyPurchasedIngredient(
    String ingredientName,
    String language,
  ) async {
    if (!isConfigured || ingredientName.trim().isEmpty) return null;
    final prompt = language == 'VIE'
        ? 'Phân loại nguyên liệu sau vào category và storage cho app quản lý kho.\n'
            'Nguyên liệu: "$ingredientName"\n'
            'Category chỉ được chọn 1 trong: vegetables, fruits, meat, dairy, seafood, drinks, snacks, other.\n'
            'Storage chỉ được chọn 1 trong: fridge, freezer, pantry.\n'
            'Chỉ trả về JSON thuần: {"category":"...","storage":"..."}'
        : 'Classify this ingredient for an inventory app.\n'
            'Ingredient: "$ingredientName"\n'
            'Category must be one of: vegetables, fruits, meat, dairy, seafood, drinks, snacks, other.\n'
            'Storage must be one of: fridge, freezer, pantry.\n'
            'Return strict JSON only: {"category":"...","storage":"..."}';

    try {
      final response = await http
          .post(
            Uri.parse(_groqEndpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0,
              'max_tokens': 120,
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          (body['choices'] as List)[0]['message']['content'] as String;
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      if (jsonStart < 0 || jsonEnd <= jsonStart) return null;
      final raw = content.substring(jsonStart, jsonEnd + 1);
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final c = (parsed['category'] as String? ?? '').trim();
      final s = (parsed['storage'] as String? ?? '').trim();
      if (c.isEmpty || s.isEmpty) return null;
      return (category: c, storage: s);
    } catch (_) {
      return null;
    }
  }
}
