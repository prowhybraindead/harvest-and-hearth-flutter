# Harvest & Hearth

Ứng dụng Android quản lý thực phẩm thông minh — theo dõi hạn sử dụng, nhận gợi ý công thức nấu ăn từ AI, đồng bộ dữ liệu qua đám mây.

---

## Tính năng

| Tính năng | Mô tả |
|-----------|-------|
| **Kho thực phẩm** | Quản lý theo Tủ lạnh / Ngăn đông. Tìm kiếm, sắp xếp theo tên / hạn sử dụng / ngày thêm. Xem chi tiết và chỉnh sửa trực tiếp. |
| **Cảnh báo hết hạn** | Tự động phát hiện thực phẩm đã hết hạn hoặc sắp hết hạn, hiển thị trên trang chủ. |
| **AI Chef** | Groq AI (Llama 3.3) tự động gợi ý 3 công thức từ nguyên liệu hiện có, ưu tiên đồ sắp hết hạn. Nếu Groq không phản hồi, tự động chuyển sang Gemini. |
| **Khám phá công thức** | Duyệt món ăn Việt Nam từ TheMealDB. Tìm kiếm bất kỳ tên món — kết quả từ TheMealDB và DuckDuckGo đồng thời. |
| **Dịch tức thì** | Dịch tên và mô tả công thức sang tiếng Việt hoặc tiếng Anh ngay trong app. |
| **Đồng bộ đám mây** | Dữ liệu thực phẩm và công thức đã lưu được lưu trên Supabase — đăng nhập từ thiết bị khác vẫn đầy đủ. |
| **Google OAuth** | Đăng nhập bằng tài khoản Google, không cần nhớ mật khẩu. |
| **Đa ngôn ngữ** | Tiếng Việt và tiếng Anh, chuyển đổi tức thì trong Hồ sơ. |
| **Chế độ tối** | Theo Material 3, lưu lại lựa chọn sau khi tắt app. |

---

## Tech Stack

| Thành phần | Công nghệ |
|-----------|-----------|
| Framework | Flutter (Android, min SDK 24) |
| State management | Provider (ChangeNotifier) |
| Backend / Auth | Supabase (PostgreSQL + RLS) |
| AI chính | Groq — `llama-3.3-70b-versatile` |
| AI dự phòng | Google Gemini — `gemini-2.0-flash` |
| Công thức online | TheMealDB API, DuckDuckGo |
| Dịch thuật | Google Translate (unofficial) |

---

## Cài đặt & Setup

### Yêu cầu

- Flutter SDK `>=3.3.0`
- Android SDK 24+ (target SDK 36)
- Tài khoản [Supabase](https://supabase.com)
- API key: Groq và Gemini

### 1 — Clone và cài dependencies

```bash
git clone <repo-url>
cd harvest-and-hearth-flutter
flutter pub get
```

### 2 — Tạo file `.env`

Sao chép `.env.example` thành `.env` và điền đầy đủ:

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
GROQ_API_KEY=<groq-key>
GEMINI_API_KEY=<gemini-key>
```

### 3 — Tạo database trên Supabase

Mở **Supabase Dashboard → SQL Editor** và chạy toàn bộ nội dung file `supabase/supabase.sql`. File này tạo các bảng `profiles`, `food_items`, `saved_recipes` cùng Row Level Security.

### 4 — Cài đặt Google OAuth (tuỳ chọn)

1. Google Cloud Console → tạo **Android OAuth Client** (SHA-1 debug + package `com.harvestandhearth.app`).
2. Google Cloud Console → tạo **Web OAuth Client** (Redirect URI = `https://<project-ref>.supabase.co/auth/v1/callback`).
3. Supabase Dashboard → **Authentication → Providers → Google** → điền Web Client ID + Secret.
4. Supabase Dashboard → **Authentication → URL Configuration** → thêm `io.supabase.harvestandhearth://login-callback/` vào Redirect URLs.

### 5 — Tạo tài khoản test (tuỳ chọn)

Vào Supabase Dashboard → Authentication → Users → Add User:
- Email: `test@harvestandhearth.app`
- Password: `testPassword123!`

### 6 — Cài đặt email templates (tuỳ chọn)

Supabase Dashboard → Authentication → Email Templates:
- **Confirm signup**: dán nội dung `supabase/email-templates/confirm-signup.html`
- **Reauthentication**: dán nội dung `supabase/email-templates/reauthentication.html`

### 7 — Chạy ứng dụng

```bash
flutter run
```

---

## Cấu trúc dự án

```
lib/
├── main.dart                    # Entry point, MaterialApp, MainShell (IndexedStack nav)
├── models/
│   ├── food_item.dart           # FoodItem, FoodCategory, StorageType
│   ├── recipe.dart              # Recipe, RecipeDifficulty
│   └── user.dart                # AppUser
├── providers/
│   └── app_provider.dart        # ChangeNotifier — toàn bộ app state
├── constants/
│   ├── translations.dart        # Bản dịch VIE/ENG (static map)
│   └── categories.dart          # AppCategories — icon, màu, translation key
├── services/
│   ├── supabase_service.dart    # Auth, profile, CRUD food & recipes
│   ├── ai_service.dart          # Facade: Groq → Gemini fallback
│   ├── groq_service.dart        # Groq API (primary AI)
│   ├── gemini_service.dart      # Google Gemini (fallback AI)
│   ├── translate_service.dart   # Google Translate (unofficial)
│   └── recipe_search_service.dart # TheMealDB + DuckDuckGo
├── utils/
│   └── date_helper.dart         # format(), relativeLabel()
├── screens/
│   ├── auth_screen.dart         # Login / Register / Google OAuth
│   ├── dashboard_screen.dart    # Trang chủ: banner, cảnh báo, gần đây, tip
│   ├── inventory_screen.dart    # Kho: Tủ lạnh / Ngăn đông, tìm kiếm, sắp xếp
│   ├── recipes_screen.dart      # AI Chef / Khám phá / Đã lưu
│   └── profile_screen.dart      # Hồ sơ: ngôn ngữ, theme, thống kê, đăng xuất
└── widgets/
    ├── add_food_modal.dart       # Bottom sheet thêm / chỉnh sửa thực phẩm
    ├── food_item_card.dart       # Card thực phẩm với category chip + expiry label
    └── recipe_card.dart         # Card công thức + detail sheet
```

---

## Kiến trúc

### Startup flow

```
main() → Supabase.initialize() → runApp()
  └─ AppProvider.init()
       ├─ đọc SharedPreferences (language, isDark) — instant
       ├─ set _isInitialized = true → splash biến mất
       ├─ nếu có session → giữ splash (_isLoadingUser = true)
       │    └─ Future.wait([getProfile, getFoodItems, getSavedRecipes])
       │         └─ xong → vào MainShell
       └─ subscribe onAuthStateChange
```

### Navigation

`IndexedStack` + `NavigationBar` — giữ state tất cả tabs khi chuyển. FAB chỉ hiện ở tab Inventory.

### AI fallback

```
AiService.generateRecipes()
  ├─ try: GroqService (llama-3.3-70b-versatile) — nhanh
  └─ catch: GeminiService (gemini-2.0-flash) — dự phòng
```

---

## Phiên bản

Xem [CHANGELOG.md](CHANGELOG.md) để biết lịch sử thay đổi.

Phiên bản hiện tại: **b0.1.5**

---

## Backlog

- [ ] Quét mã vạch thực sự bằng camera
- [ ] Thông báo nhắc nhở thực phẩm sắp hết hạn
- [ ] Danh sách mua sắm tự động từ kho thiếu
- [ ] Ảnh thực phẩm tuỳ chỉnh từ camera
- [ ] Widget màn hình chính Android hiển thị cảnh báo
