<div align="center">

# Harvest & Hearth

**Ứng dụng Android quản lý thực phẩm thông minh** — theo dõi hạn sử dụng, gợi ý công thức từ AI, đồng bộ dữ liệu qua đám mây.  
Song ngữ **Việt – Anh**, giao diện **Material 3**.

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Android-API_24+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Clerk](https://img.shields.io/badge/Auth-Clerk-6C47FF)](https://clerk.com)
[![MongoDB](https://img.shields.io/badge/DB-MongoDB-47A248?logo=mongodb&logoColor=white)](https://mongodb.com)

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
| **Đám mây** | **MongoDB** qua API Node (`server/`) — đồng bộ kho & công thức đã lưu. |
| **Đăng nhập** | **Clerk** (email, OAuth… bật trong Clerk Dashboard; UI từ `clerk_flutter`). |
| **Cài đặt** | Sáng / tối, Việt / Anh — lưu cục bộ. |

---

<a id="tech-stack"></a>
## Tech stack

| Lớp | Công nghệ |
| --- | --- |
| UI | Flutter · Material 3 · **Provider** (ChangeNotifier) |
| Backend | **MongoDB** + REST API (`server/`) · **Clerk** JWT |
| AI | **Groq** `llama-3.3-70b-versatile` → **Gemini** `gemini-2.0-flash` |
| Công thức ngoài | TheMealDB, DuckDuckGo |
| Dịch | Google Translate (unofficial) |
| Quét mã | **mobile_scanner** (barcode + QR) |

---

<a id="versioning"></a>
## Phiên bản

| Nhãn sản phẩm | `pubspec` | Android `versionName` · `versionCode` |
| --- | --- | --- |
| **b0.3.0** | `1.0.8+9` | `1.0.8` · `9` |

Chi tiết từng bản: [**CHANGELOG.md**](CHANGELOG.md).

---

<a id="quick-start"></a>
## Cài đặt nhanh

**Yêu cầu:** Flutter SDK `>=3.6.2`, Android SDK **24+** (target **36**), project [Clerk](https://clerk.com), cluster [MongoDB](https://mongodb.com), API key **Groq** & **Gemini**.

```bash
git clone <repo-url>
cd harvest-and-hearth-flutter
flutter pub get
```

### 1. Backend API (MongoDB Atlas)

Trên [Atlas](https://cloud.mongodb.com) lấy **connection string** (`mongodb+srv://…`) và điền vào **`MONGODB_URI`** trong `server/.env` (sao chép từ `server/.env.example`).

```bash
cd server
cp .env.example .env   # MONGODB_URI=... (Atlas) + CLERK_SECRET_KEY — chi tiết: server/README.md
npm install
npm start
```

**Deploy cloud (Render):** xem **`server/README.md`** — mục *Deploy trên Render* (`Dockerfile`, **Root Directory** = `server`, secrets `MONGODB_URI` / `CLERK_SECRET_KEY`).

### 2. App Flutter

Tạo `.env` từ `.env.example` và điền:

```env
CLERK_PUBLISHABLE_KEY=pk_test_...
API_BASE_URL=http://localhost:8787
GROQ_API_KEY=<groq-key>
GEMINI_API_KEY=<gemini-key>
```

Trên **Android emulator**, `localhost` trỏ vào máy dev — dùng `http://10.0.2.2:8787` thay cho `localhost` nếu API chạy trên máy host.

```bash
flutter run
```

---

<a id="build-release"></a>
## Build bản phát hành (APK)

```bash
flutter build apk --release
```

**Đầu ra APK** (`build/app/outputs/flutter-apk/`):

| File | Mô tả |
| --- | --- |
| `app-release.apk` | Bản build mặc định của Flutter |
| `harvestnhearth-<changelog>.apk` | Bản sao đặt tên theo **nhãn mới nhất** trong `CHANGELOG.md` (ví dụ `harvestnhearth-b0.3.0.apk`) |

**Icon launcher:** đặt PNG vuông tại [`code/app_icon.png`](code/app_icon.png), sau đó:

```bash
dart run flutter_launcher_icons
```

*(Tuỳ chọn Play Store: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.)*

---

<a id="project-layout"></a>
## Cấu trúc dự án

```
lib/
├── main.dart                    # App + ClerkAuth + theme tĩnh + MainShell
├── models/
├── providers/                   # AppProvider
├── constants/                   # translations, categories
├── services/                    # backend_api (HTTP + Clerk token), AI, search, translate
├── utils/
├── screens/                     # auth, dashboard, inventory, recipes, profile, barcode_scanner
└── widgets/                     # add_food_modal, cards, …
server/                          # API Node (MongoDB + Clerk JWT) — xem server/README.md
render.yaml                      # Render Blueprint (tuỳ chọn) — deploy Docker từ server/
```

---

<a id="architecture"></a>
## Kiến trúc

- **Khởi động:** `ClerkAuth` → `AppProvider.init()` (prefs) → sau khi đăng nhập Clerk, `BackendApiService` gọi API với JWT session (HTTP có **timeout** cho cloud/cold start).
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
