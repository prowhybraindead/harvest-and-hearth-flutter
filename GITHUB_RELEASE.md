# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag gợi ý: `v1.0.10` hoặc `b0.3.3`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.3.3 · Clerk email Revolvapp + tài khoản thử
```

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.3.3` · `1.0.10+11`

### Ứng dụng
- Semver build **1.0.10** (`versionCode` **11**).
- Template email Clerk dạng **Revolvapp** (`clerk/email-templates/invitation.html`, `verification-code.html`); hướng dẫn logo `{{> app_logo}}` trong `clerk/email-templates/README.md`.
- Nút **Dùng tài khoản thử** (khi đặt `TEST_ACCOUNT_EMAIL` + `TEST_ACCOUNT_PASSWORD` trong `.env`); mật khẩu test đề xuất: `!testPassword123!`.
- Trước đó: HTTP client tái sử dụng, bootstrap Clerk tối ưu — xem CHANGELOG đầy đủ.

### Backend (`server/`)
- Không đổi hợp đồng API trong bản build này — xem `server/README.md`, `render.yaml`.

### Tệp đính kèm APK (build local)
- **`app-release.apk`**
- **`harvestnhearth-b0.3.3.apk`**

### Cấu hình
1. `.env` app: `CLERK_PUBLISHABLE_KEY`, `API_BASE_URL`, Groq, Gemini; tuỳ chọn `TEST_ACCOUNT_*` cho nút tài khoản thử.
2. Secrets API: `MONGODB_URI`, `CLERK_SECRET_KEY`.
3. Clerk: Google OAuth + **Allowlist mobile SSO** `com.clerk.flutter://callback` nếu dùng.

### Changelog đầy đủ
[Xem CHANGELOG.md](https://github.com/prowhybraindead/harvest-and-hearth-flutter/blob/main/CHANGELOG.md)
```

---

## Tài sản đính kèm (Attachments)

| File | Đường dẫn sau khi `flutter build apk --release` |
| --- | --- |
| `app-release.apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `harvestnhearth-b0.3.3.apk` | `build/app/outputs/flutter-apk/harvestnhearth-b0.3.3.apk` |

---

## Gợi ý tag Git

- **Semver:** `v1.0.10` (khớp `versionName` Android).
- **Nhãn sản phẩm:** `b0.3.3` (mục mới nhất trong `CHANGELOG.md`).
