# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.13` hoặc `b0.4.1`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.4.1 · Console mô phỏng thời gian (QA thông báo)
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.4.1` · `1.0.13+14`

### Ứng dụng
- **Thông báo & widget (như b0.4.0):** tóm tắt ~9:00 khi có món sắp hết / hết hạn; widget Android; bật/tắt trong **Hồ sơ**.
- **Console mô phỏng thời gian (QA):** FAB góc trái — tua nhanh **+1 / +3 / +7 ngày** (cộng dồn), reset về giờ thực, **gửi thông báo thử ngay**. Trong release APK: đặt `ENABLE_TIME_SIMULATOR=true` trong `.env` nếu cần (mặc định chỉ bật sẵn trong debug).
- Build **1.0.13** (`versionCode` **14**).

### Backend
- Không đổi API — xem `server/README.md`.

### APK
- `app-release.apk` · `harvestnhearth-b0.4.1.apk`

### Changelog
[Xem CHANGELOG.md](https://github.com/prowhybraindead/harvest-and-hearth-flutter/blob/main/CHANGELOG.md)
```

---

## Tài sản đính kèm

| File | Đường dẫn sau `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.4.1.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.4.1.apk` |

---

## Gợi ý tag

- **Semver:** `v1.0.13`
- **Nhãn:** `b0.4.1`
