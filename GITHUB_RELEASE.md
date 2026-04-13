# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.16` hoặc `b0.4.4`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.4.4 · Dashboard mới + AI Chat + fix Widget
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.4.4` · `1.0.16+17`

### Thêm mới
- **Trang chủ thiết kế mới**: Lời chào theo thời gian, thẻ thống kê màu sắc, nút hành động nhanh, xem trước AI Chat.
- **AI Chat công thức**: Trò chuyện nhiều lượt với AI Chef — hiểu nguyên liệu trong tủ, gợi ý prompt nhanh.
- **Kho thực phẩm mới**: Tab Tủ lạnh/Ngăn đông, tìm kiếm, sắp xếp nhiều tiêu chí.

### Sửa lỗi
- **Widget Android không tải được:** Fix lỗi xung đột `build.gradle` khiến widget class không tìm thấy.

### Build
- **1.0.16** (`versionCode` **17**).

### Backend
- Không đổi API — xem `server/README.md`.

### APK
- `app-release.apk` · `harvestnhearth-b0.4.4.apk`

### Changelog
[Xem CHANGELOG.md](https://github.com/prowhybraindead/harvest-and-hearth-flutter/blob/main/CHANGELOG.md)
```

---

## Tài sản đính kèm

| File | Đường dẫn sau `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.4.4.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.4.4.apk` |

---

## Gợi ý tag

- **Semver:** `v1.0.16`
- **Nhãn:** `b0.4.4`
