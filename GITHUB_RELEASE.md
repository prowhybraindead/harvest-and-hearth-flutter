# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.17` hoặc `b0.4.5`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.4.5 · Realtime Recipe + Notification Logs + Widget nâng cấp
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.4.5` · `1.0.17+18`

### Thêm mới
- **Notification logs theo từng user (MongoDB)**: Lưu và truy vấn lịch sử thông báo (`title`, `message`, `type`, `isRead`, `createdAt`) qua backend API.
- **Dashboard cập nhật theo góp ý**: Quét barcode trực tiếp từ Home và thêm khu vực gợi ý công thức theo thời gian thực.
- **Recipe đa nguồn + dịch tiếng Việt**: Gộp dữ liệu từ TheMealDB + DummyJSON, dịch EN -> VI cho tên/mô tả/nguyên liệu/các bước nấu.
- **Android Home Widget nâng cấp**: Thêm compact/ultra-compact mode, status chip, thời điểm cập nhật, nền đổi theo mức cảnh báo.

### Cải tiến
- **Màu cảnh báo trong Home** được làm dịu theo feedback để giảm chói.
- **Card công thức hiển thị nguồn** (`TheMealDB`, `DummyJSON`, `AI Chef`) để minh bạch dữ liệu.

### Sửa lỗi
- **Barcode từ Dashboard**: Sửa điều hướng route không tồn tại, chuyển sang mở scanner trực tiếp.
- **Stability/lint fixes**: Sửa lỗi regex literal và tham số notification icon để bản release sạch analyzer.

### Build
- **1.0.17** (`versionCode` **18**).

### Backend
- Có cập nhật API notifications — xem `server/README.md` và `server/src/index.js`.

### APK
- `app-release.apk` · `harvestnhearth-b0.4.5.apk`

### Changelog
[Xem CHANGELOG.md](https://github.com/prowhybraindead/harvest-and-hearth-flutter/blob/main/CHANGELOG.md)
```

---

## Tài sản đính kèm

| File | Đường dẫn sau `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.4.5.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.4.5.apk` |

---

## Gợi ý tag

- **Semver:** `v1.0.17`
- **Nhãn:** `b0.4.5`
