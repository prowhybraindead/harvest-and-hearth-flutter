# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.18` hoặc `b0.4.6`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.4.6 · Hotfix MongoDB + Widget + Inventory Restore
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.4.6` · `1.0.18+19`

### Sửa lỗi
- **MongoDB nhầm DB `test`**: backend ép dùng `harvest_and_hearth` (hoặc `MONGODB_DB_NAME`) để tránh ghi sai database.
- **Inventory mất sau khi mở lại app**: tách xử lý lỗi bootstrap theo từng API, không để lỗi phụ chặn nạp `food-items`.
- **Widget Android `Can't load widget`**: thêm fallback render để widget không crash khi runtime lỗi.

### Build
- **1.0.18** (`versionCode` **19**).

### Backend
- Có cập nhật logic chọn database MongoDB — xem `server/src/index.js`.

### APK
- `app-release.apk` · `harvestnhearth-b0.4.6.apk`

### Changelog
[Xem CHANGELOG.md](https://github.com/prowhybraindead/harvest-and-hearth-flutter/blob/main/CHANGELOG.md)
```

---

## Tài sản đính kèm

| File | Đường dẫn sau `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.4.6.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.4.6.apk` |

---

## Gợi ý tag

- **Semver:** `v1.0.18`
- **Nhãn:** `b0.4.6`
