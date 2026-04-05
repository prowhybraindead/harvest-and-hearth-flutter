# Nội dung gợi ý cho GitHub Release

Sao chép phần dưới khi tạo **Release** (tag ví dụ: `v1.0.5` hoặc `b0.1.8`).

---

## Release title (tiêu đề)

```
Harvest & Hearth b0.1.8 · Performance & docs
```

*(Hoặc tiếng Anh: `Harvest & Hearth b0.1.8 — Performance, README, release build`.)*

---

## Release notes (mô tả — Markdown)

```markdown
## Harvest & Hearth `b0.1.8` · `1.0.5+6`

### Highlights
- **Performance**: `MaterialApp` and app shell avoid unnecessary rebuilds when only inventory or recipe cache updates; light/dark themes use static `ThemeData` instances.
- **Navigation**: Bottom bar labels refresh when the UI language changes, without rebuilding on unrelated data updates.
- **Images**: TheMealDB thumbnails and detail images use decode size hints (`cacheWidth` / `cacheHeight`) for smoother scrolling.
- **Docs**: README restructured (badges, TOC, version table, release build path). This release includes an optimized **release APK** build.

### Install
- **APK**: attach `app-release.apk` from `flutter build apk --release` (`build/app/outputs/flutter-apk/app-release.apk`).
- **Configure**: copy `.env.example` → `.env`, add Supabase + API keys; run `supabase/supabase.sql` on your project.

### Full changelog
See [CHANGELOG.md](https://github.com/YOUR_ORG/YOUR_REPO/blob/main/CHANGELOG.md) in the repository.
```

*(Thay `YOUR_ORG/YOUR_REPO` bằng đường dẫn repo thật.)*

---

## Tài sản đính kèm (Attachments)

| File | Ghi chú |
| --- | --- |
| `app-release.apk` | Sau khi chạy `flutter build apk --release` |

---

## Gợi ý tag Git

- Tag semver: `v1.0.5` (khớp `versionName` Android / tên pubspec không có `+build`).
- Hoặc tag nhãn sản phẩm: `b0.1.8` nếu team dùng song song với semver trong CHANGELOG.
