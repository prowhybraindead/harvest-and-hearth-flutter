# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.8` hoặc `b0.3.0`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.3.0 · API tối ưu + Render Blueprint
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.3.0` · `1.0.8+9`

### Ứng dụng
- Semver build **1.0.8** (`versionCode` **9**).
- Client API: timeout HTTP 45s, phù hợp host free / cold start.

### Backend (`server/`)
- Gzip (`compression`), `trust proxy`, tắt `X-Powered-By`.
- Deploy **Render:** `render.yaml` (Blueprint) hoặc Web Service thủ công — xem `server/README.md`.

### Tệp đính kèm APK (build local)
- **`app-release.apk`**
- **`harvestnhearth-b0.3.0.apk`** (bản sao theo nhãn CHANGELOG mới nhất)

### Cấu hình
1. `.env` app: `CLERK_PUBLISHABLE_KEY`, `API_BASE_URL` (URL Render HTTPS), Groq, Gemini.
2. Secrets API: `MONGODB_URI` (Atlas), `CLERK_SECRET_KEY`.

### Changelog đầy đủ
[Xem CHANGELOG.md](https://github.com/YOUR_ORG/YOUR_REPO/blob/main/CHANGELOG.md) *(thay `YOUR_ORG/YOUR_REPO` bằng repo thật)*.
```

---

## Tài sản đính kèm (Attachments)

| File | Đường dẫn sau khi `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.3.0.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.3.0.apk` |

---

## Gợi ý tag Git

- **Semver:** `v1.0.8` (khớp `versionName` Android).
- **Nhãn sản phẩm:** `b0.3.0` (mục mới nhất trong `CHANGELOG.md`).
