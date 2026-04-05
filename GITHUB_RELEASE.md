# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.14` hoặc `b0.4.2`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.4.2 · Hotfix (email Revolvapp, FAB QA, widget)
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.4.2` · `1.0.14+15`

### Hotfix
- **Email Clerk:** toàn bộ template trong `clerk/email-templates/` dùng định dạng **Revolvapp** (Dashboard) — dán từng file vào đúng template trong **Customization → Emails**.
- **FAB mô phỏng thời gian:** mặc định **hiện** trên release; ẩn bằng `ENABLE_TIME_SIMULATOR=false` trong `.env` khi build (nếu cần).
- **Widget Android:** nhãn/icon trong manifest; thêm widget thủ công từ màn hình chính — xem gợi ý trong **Hồ sơ** / **README**.

### Build
- **1.0.14** (`versionCode` **15**).

### Backend
- Không đổi API — xem `server/README.md`.

### APK
- `app-release.apk` · `harvestnhearth-b0.4.2.apk`

### Changelog
[Xem CHANGELOG.md](https://github.com/prowhybraindead/harvest-and-hearth-flutter/blob/main/CHANGELOG.md)
```

---

## Tài sản đính kèm

| File | Đường dẫn sau `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.4.2.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.4.2.apk` |

---

## Gợi ý tag

- **Semver:** `v1.0.14`
- **Nhãn:** `b0.4.2`
