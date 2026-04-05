# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.7` hoặc `b0.1.10`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.1.10 · Đồ án — APK release
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.1.10` · `1.0.7+8`

### Mục đích
- Bản build phục vụ **đồ án / báo cáo**, đính kèm GitHub Release — **không** phát hành Google Play / App Store.

### Tệp đính kèm
- **`app-release.apk`** — output mặc định của Flutter.
- **`harvestnhearth-b0.1.10.apk`** — bản sao đặt tên theo nhãn `CHANGELOG` (cùng thư mục: `build/app/outputs/flutter-apk/`).

### Chạy thử
1. Sao chép `.env.example` → `.env`, điền Supabase + API (Groq, Gemini).
2. Chạy SQL `supabase/supabase.sql` trên project Supabase.

### Changelog đầy đủ
[Xem CHANGELOG.md](https://github.com/YOUR_ORG/YOUR_REPO/blob/main/CHANGELOG.md) *(thay `YOUR_ORG/YOUR_REPO` bằng repo thật)*.
```

---

## Tài sản đính kèm (Attachments)

| File | Đường dẫn sau khi `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.1.10.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.1.10.apk` |

---

## Gợi ý tag Git

- **Semver:** `v1.0.7` (khớp `versionName` Android).
- **Nhãn sản phẩm:** `b0.1.10` (khớp mục cuối trong `CHANGELOG.md`).
