# RULES.md — Quy tắc code cho dự án Harvest & Hearth Flutter

> Tài liệu này áp dụng cho **tất cả** người đóng góp vào dự án, bao gồm cả AI assistant.  
> Mọi thay đổi code phải tuân thủ các quy tắc dưới đây.

---

## 1. Bảo mật & Tệp nhạy cảm

### 1.1 CẤM TUYỆT ĐỐI đọc, ghi, log hoặc in ra nội dung của:
- `.env` và mọi biến thể (`.env.local`, `.env.production`, `.env.test`, …)
- Bất kỳ file chứa API key, secret, token, password
- `*.key`, `*.pem`, `*.p12`, `*.keystore`
- `google-services.json`, `GoogleService-Info.plist`
- `key.properties`, `local.properties`
- Bất kỳ file nào có tên hoặc nội dung liên quan đến credential

### 1.2 API key và secret
- **Không bao giờ** hardcode API key vào source code.
- Luôn đọc từ `dotenv.maybeGet('KEY')` và xử lý trường hợp trả về null.
- Không log giá trị API key dù trong debug mode.

### 1.3 Git
- `.env` phải nằm trong `.gitignore`. Kiểm tra trước khi commit.
- `AI.md` không được push lên remote (đã có trong `.gitignore`).
- Không commit file binary lớn (ảnh, video, apk, …).

---

## 2. Kiến trúc & Cấu trúc code

### 2.1 Phân tầng
```
models/      ← Data structures, không phụ thuộc Flutter
providers/   ← Business logic, state management
services/    ← External API, I/O
constants/   ← Hằng số, translations, config tĩnh
utils/       ← Hàm tiện ích thuần Dart
screens/     ← Màn hình (Widget cấp cao, StatefulWidget khi cần local state)
widgets/     ← Thành phần UI tái sử dụng
```

### 2.2 State management
- Chỉ dùng **Provider (ChangeNotifier)** — không trộn lẫn StatefulWidget state với Provider state cho cùng một dữ liệu.
- Mutations phải đi qua method của `AppProvider`.
- Widget chỉ đọc state, không tự sửa state bằng cách trực tiếp.
- Dùng `context.watch<T>()` khi cần rebuild, `context.read<T>()` trong callbacks.

### 2.3 Models
- Models là **immutable** — dùng `copyWith` để tạo bản sao thay đổi.
- Mọi model phải có `toJson()` và `fromJson()`.
- Không để business logic trong model (trừ computed properties đơn giản).

---

## 3. Dart / Flutter Code Style

### 3.1 Tổng quát
- Tuân theo [Effective Dart](https://dart.dev/effective-dart) và `flutter_lints`.
- Không tắt lint rules (`// ignore:`) trừ khi có lý do rõ ràng và được comment giải thích.
- Tên class: `UpperCamelCase`. Tên biến/method: `lowerCamelCase`. Hằng: `lowerCamelCase` hoặc `UPPER_SNAKE_CASE` cho static const.

### 3.2 Widget
- Ưu tiên `StatelessWidget`. Dùng `StatefulWidget` chỉ khi thực sự cần local UI state (form, animation, tab controller).
- Tách widget nhỏ thành class riêng thay vì build method khổng lồ.
- Không đặt logic phức tạp trong `build()`.
- Luôn dùng `const` constructor khi có thể.

### 3.3 Async
- Luôn kiểm tra `if (mounted)` sau `await` trong `StatefulWidget`.
- Không bỏ qua `Future` (không dùng `unawaited` trừ trường hợp đặc biệt).
- Wrap async call trong `try/catch` và hiển thị lỗi cho user.

### 3.4 Không làm
- Không dùng `print()` trong production code — dùng `debugPrint()` hoặc logging library.
- Không dùng `dynamic` khi có thể dùng kiểu cụ thể.
- Không dùng `!` (null assertion) trừ khi chắc chắn 100% không null.
- Không hardcode string UI — phải đi qua `provider.t('key')`.
- Không import file từ package khác vào models/ (giữ models thuần Dart).

---

## 4. Internationalisation (i18n)

- Mọi string hiển thị cho user **phải** có trong `Translations` class.
- Thêm key vào **cả hai** map `_vie` và `_eng` cùng lúc.
- Format key: `snake_case`, nhóm theo màn hình (ví dụ: `inventory_search`, `auth_login`).
- Không hardcode tiếng Việt hoặc tiếng Anh trực tiếp trong widget.

---

## 5. Xử lý lỗi & UX

- Mọi thao tác async có thể thất bại phải hiển thị `SnackBar` hoặc `AlertDialog` cho người dùng.
- Loading state phải hiển thị `CircularProgressIndicator` và disable button tương ứng.
- Empty state phải có icon minh hoạ và text hướng dẫn.
- Confirm dialog bắt buộc trước khi xoá dữ liệu.

---

## 6. Naming Conventions

| Loại | Quy tắc | Ví dụ |
|------|---------|-------|
| Files | `snake_case.dart` | `food_item_card.dart` |
| Classes | `UpperCamelCase` | `FoodItemCard` |
| Enums | `UpperCamelCase` | `FoodCategory` |
| Enum values | `camelCase` | `FoodCategory.vegetables` |
| Methods | `camelCase` | `addFood()` |
| Private variables | `_camelCase` | `_isLoading` |
| Static const | `camelCase` | `AppCategories.all` |
| Translation keys | `group_name` | `inventory_search` |

---

## 7. Git Workflow

- **Không commit trực tiếp lên `main`**.
- Branch naming: `feature/tên-tính-năng`, `fix/mô-tả-lỗi`, `refactor/mô-tả`.
- Commit message: ngắn gọn, tiếng Việt hoặc tiếng Anh, dùng imperative (ví dụ: `Add barcode scanning`, `Fix expiry date calculation`).
- Không commit file được sinh tự động (`build/`, `.dart_tool/`, …).

---

## 8. Kiểm thử

- Mọi logic tính toán trong `utils/` và `models/` nên có unit test.
- `AppProvider` methods nên có widget test cơ bản.
- Chạy `flutter analyze` trước khi tạo Pull Request — không được có lỗi hoặc warning.
- Chạy `flutter test` và đảm bảo tất cả tests pass.

---

## 9. Performance

- Dùng `IndexedStack` cho bottom navigation để giữ state khi chuyển tab.
- Không gọi API trong `build()`.
- Dùng `const` constructor để tránh rebuild không cần thiết.
- Tránh rebuild widget tree lớn khi chỉ thay đổi nhỏ — chia nhỏ widget.

---

## 10. Tài liệu & Versioning

- Mỗi public method/class quan trọng nên có doc comment (`///`).
- `RULES.md` được cập nhật khi có quy ước mới được thống nhất trong team.

### 10.1 Quy tắc versioning

Dự án dùng định dạng `MAJOR.MINOR.PATCH` (ví dụ: `0.1.3`):

| Loại thay đổi | Tăng | Ví dụ |
| --- | --- | --- |
| Tính năng mới, thay đổi lớn về UX hoặc kiến trúc | `+0.1.0` | `0.1.2` → `0.2.0` |
| Sửa lỗi, cải tiến nhỏ, thêm email template, tối ưu | `+0.0.1` | `0.1.2` → `0.1.3` |

- **Không dùng hậu tố** `-beta`, `-b1`, `-rc` trong version string.
- Cập nhật version ở **3 nơi** đồng thời: `pubspec.yaml`, `android/app/build.gradle` (`versionCode` tăng 1, `versionName` theo version), và changelog.
- `versionCode` trong `build.gradle` là số nguyên tăng dần liên tục (không reset khi tăng version).

### 10.2 Bắt buộc cập nhật changelog sau mỗi thay đổi

Sau **mỗi lần** thay đổi code có ý nghĩa, phải cập nhật **cả hai** file sau:

**`CHANGELOG.md`** — dành cho người dùng đọc:

- Viết theo ngôn ngữ tự nhiên, không đề cập tên file hay method.
- Chỉ mô tả **tính năng / trải nghiệm** thay đổi.
- Dùng bullet point ngắn gọn, bắt đầu bằng **tên tính năng in đậm**.

**`AI.md`** — dành cho dev và AI đọc:

- Ghi đầy đủ: file bị sửa, method bị thêm/đổi, nguyên nhân kỹ thuật, cấu trúc mới.
- Dùng bảng để liệt kê bug + nguyên nhân khi có sửa lỗi nhiều chỗ.
- Ghi rõ breaking changes nếu có (đổi tên method, thay đổi schema DB, …).
