<div align="center">

# Harvest & Hearth

**Ứng dụng Android quản lý thực phẩm thông minh** — theo dõi hạn sử dụng, gợi ý công thức từ AI, đồng bộ dữ liệu qua đám mây.  
Song ngữ **Việt – Anh**, giao diện **Material 3**.

[![Flutter](https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Android-API_24+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)

</div>

---

## Mục lục

- [Tính năng](#features)
- [Tech stack](#tech-stack)
- [Phiên bản](#versioning)
- [Cài đặt nhanh](#quick-start)
- [Build bản phát hành (APK)](#build-release)
- [Cấu trúc dự án](#project-layout)
- [Kiến trúc](#architecture)
- [Backlog](#backlog)
- [Changelog](#changelog)

---

<a id="features"></a>
## Tính năng

| | |
| --- | --- |
| **Kho thực phẩm** | Tủ lạnh / Ngăn đông, tìm kiếm, sắp xếp, xem & chỉnh sửa. **Quét mã vạch / QR** bằng camera (đèn flash). |
| **Cảnh báo hết hạn** | Gom mặt hàng hết hạn & sắp hết hạn trên trang chủ. |
| **AI Chef** | Groq (Llama 3.3) gợi ý 3 công thức từ nguyên liệu trong tủ; fallback **Gemini** nếu Groq lỗi. |
| **Khám phá** | Món Việt Nam (TheMealDB), tìm kiếm TheMealDB + DuckDuckGo, lưu công thức. |
| **Dịch** | Dịch tên/mô tả công thức theo ngôn ngữ đang dùng. |
| **Đám mây** | Supabase — đăng nhập thiết bị khác vẫn đồng bộ kho & công thức đã lưu. |
| **Đăng nhập** | Email/mật khẩu, Google OAuth, tài khoản thử (theo hướng dẫn setup). |
| **Cài đặt** | Sáng / tối, Việt / Anh — lưu cục bộ. |

---

<a id="tech-stack"></a>
## Tech stack

| Lớp | Công nghệ |
| --- | --- |
| UI | Flutter · Material 3 · **Provider** (ChangeNotifier) |
| Backend | **Supabase** (Auth, PostgreSQL, RLS) |
| AI | **Groq** `llama-3.3-70b-versatile` → **Gemini** `gemini-2.0-flash` |
| Công thức ngoài | TheMealDB, DuckDuckGo |
| Dịch | Google Translate (unofficial) |
| Quét mã | **mobile_scanner** (barcode + QR) |

---

<a id="versioning"></a>
## Phiên bản

| Nhãn sản phẩm | `pubspec` | Android `versionName` · `versionCode` |
| --- | --- | --- |
| **b0.1.8** | `1.0.5+6` | `1.0.5` · `6` |

Chi tiết từng bản: [**CHANGELOG.md**](CHANGELOG.md).

---

<a id="quick-start"></a>
## Cài đặt nhanh

**Yêu cầu:** Flutter SDK `>=3.3.0`, Android SDK **24+** (target **36**), tài khoản [Supabase](https://supabase.com), API key **Groq** & **Gemini**.

```bash
git clone <repo-url>
cd harvest-and-hearth-flutter
flutter pub get
```

Tạo `.env` từ `.env.example` và điền:

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
GROQ_API_KEY=<groq-key>
GEMINI_API_KEY=<gemini-key>
```

Chạy SQL `supabase/supabase.sql` trong Supabase SQL Editor. Tuỳ chọn: Google OAuth (Android + Web client), redirect `io.supabase.harvestandhearth://login-callback/`, email templates trong `supabase/email-templates/`.

```bash
flutter run
```

---

<a id="build-release"></a>
## Build bản phát hành (APK)

```bash
flutter build apk --release
```

File đầu ra mặc định:

`build/app/outputs/flutter-apk/app-release.apk`

*(Tuỳ chọn Play Store: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.)*

---

<a id="project-layout"></a>
## Cấu trúc dự án

```
lib/
├── main.dart                    # App + theme tĩnh + Selector routing + MainShell
├── models/
├── providers/                   # AppProvider
├── constants/                   # translations, categories
├── services/                    # Supabase, AI, search, translate
├── utils/
├── screens/                     # auth, dashboard, inventory, recipes, profile, barcode_scanner
└── widgets/                     # add_food_modal, cards, …
```

---

<a id="architecture"></a>
## Kiến trúc

- **Khởi động:** `Supabase.initialize` → `AppProvider.init()` (prefs → session → tải profile/kho/công thức).
- **Điều hướng:** `IndexedStack` + `NavigationBar` — giữ state từng tab; FAB chỉ tab Kho.
- **AI:** `AiService` → thử Groq, lỗi thì Gemini.
- **Hiệu năng (b0.1.8):** `MaterialApp` không rebuild khi chỉ đổi dữ liệu kho/công thức; theme dùng instance tĩnh; ảnh TheMealDB decode có giới hạn kích thước cache.

---

<a id="backlog"></a>
## Backlog

- [x] Quét mã vạch và mã QR thực sự bằng camera
- [ ] Thông báo nhắc nhở thực phẩm sắp hết hạn
- [ ] Danh sách mua sắm tự động từ kho thiếu
- [ ] Ảnh thực phẩm tuỳ chỉnh từ camera
- [ ] Widget màn hình chính Android (cảnh báo)

---

<a id="changelog"></a>
## Changelog

Xem đầy đủ: [**CHANGELOG.md**](CHANGELOG.md).

---

<div align="center">

**Harvest & Hearth** · Quản lý tủ lạnh thông minh

</div>
