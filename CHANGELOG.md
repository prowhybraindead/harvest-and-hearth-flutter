# CHANGELOG

Tất cả thay đổi đáng chú ý của dự án **Harvest & Hearth Flutter** sẽ được ghi nhận tại đây.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/).

---

## [b0.1.0] — 2026-04-05

### Thêm mới
- **Xác thực người dùng**: Màn hình đăng nhập / đăng ký với validation. Hỗ trợ tài khoản thử cho phép bỏ qua form để kiểm tra nhanh.
- **Trang chủ (Dashboard)**: Hiển thị lời chào cá nhân hoá, thống kê số lượng thực phẩm, cảnh báo các mặt hàng hết hạn hoặc sắp hết hạn, danh sách 3 mặt hàng vừa thêm gần nhất, và mẹo hàng ngày.
- **Kho thực phẩm (Inventory)**: Quản lý thực phẩm theo hai ngăn — Tủ lạnh và Ngăn đông. Hỗ trợ tìm kiếm theo tên và sắp xếp theo tên / ngày hết hạn / ngày thêm. Xoá mặt hàng với hộp thoại xác nhận.
- **Thêm thực phẩm**: Form nhập liệu đầy đủ gồm tên, danh mục (8 loại), vị trí lưu trữ, số lượng, đơn vị, ngày hết hạn, và số ngày cảnh báo trước. Có nút quét mã vạch giả lập.
- **Công thức nấu ăn (Recipes)**:
  - AI Chef tự động gợi ý 3 công thức dựa trên nguyên liệu hiện có trong tủ, ưu tiên nguyên liệu sắp hết hạn.
  - Xem chi tiết công thức: thành phần, các bước nấu, thời gian, calo, khẩu phần, độ khó.
  - Lưu và bỏ lưu công thức yêu thích.
- **Hồ sơ (Profile)**: Chuyển đổi ngôn ngữ Việt – Anh. Bật/tắt chế độ tối. Xem thống kê cá nhân (số mặt hàng, công thức đã lưu, số hàng hết hạn). Đăng xuất.
- **Hỗ trợ đa ngôn ngữ**: Toàn bộ giao diện hỗ trợ tiếng Việt và tiếng Anh, chuyển đổi tức thời không cần khởi động lại.
- **Chế độ tối**: Chủ đề sáng/tối theo Material 3, lưu lại lựa chọn sau khi tắt app.
- **Lưu trữ cục bộ**: Toàn bộ dữ liệu (thực phẩm, công thức đã lưu, cài đặt) được lưu trên thiết bị qua SharedPreferences và không cần kết nối mạng (trừ tính năng AI).

---

## [b0.1.1] — 2026-04-05

### Sửa lỗi

- **Ứng dụng không khởi động được trên Android**: Lỗi build Gradle ngăn ứng dụng cài lên thiết bị. Đã được vá hoàn toàn, ứng dụng cài và chạy bình thường.

### Cải tiến

- **AI thông minh hơn với hệ thống dự phòng**: Tích hợp thêm Groq AI (Llama 3.3) làm nguồn chính để tạo công thức nhanh hơn. Nếu Groq không phản hồi, ứng dụng tự động chuyển sang Gemini mà người dùng không cần làm gì.
- **Hỗ trợ Android mới nhất (SDK 36)**: Đảm bảo tương thích với các thiết bị Android mới nhất.

---

## [b0.1.2] — 2026-04-05

- **Đăng nhập bằng Google**: Nút "Đăng nhập với Google" trên màn hình xác thực. Ứng dụng mở trình duyệt, người dùng chọn tài khoản Google, rồi tự động quay lại app — không cần nhớ mật khẩu.
- **Lưu trữ đám mây (Supabase)**: Dữ liệu thực phẩm và công thức đã lưu nay được lưu trên cloud thay vì chỉ trong bộ nhớ thiết bị. Đăng nhập trên thiết bị khác vẫn thấy đầy đủ dữ liệu.
- **Tab "Khám phá" trong màn hình Công thức**:
  - Mặc định hiển thị danh sách **món ăn Việt Nam** từ TheMealDB (có ảnh, nhấn để xem chi tiết nguyên liệu và các bước nấu).
  - Thanh tìm kiếm để tra cứu bất kỳ tên món nào — kết quả đến từ TheMealDB và DuckDuckGo cùng lúc.
  - Có thể lưu công thức tìm được vào danh sách yêu thích giống công thức AI.
- **Dịch thuật tức thì**: Mỗi công thức tìm được từ API hoặc DuckDuckGo đều có nút "Dịch" — ứng dụng tự động dịch tên và mô tả sang ngôn ngữ đang dùng (Việt hoặc Anh). Nhấn lại để xem bản gốc.
- **Mở trang web nguồn**: Kết quả tìm từ DuckDuckGo hoặc TheMealDB đều có nút "Mở trang web" để xem bài viết gốc đầy đủ trong trình duyệt.

---

## [b0.1.3] — 2026-04-05

- **Link xác nhận email mở đúng app**: Trước đây nhấn link trong email xác nhận tài khoản sẽ trỏ về localhost. Nay link tự động mở thẳng vào ứng dụng.
- **Đăng nhập Google tải nhanh hơn**: Sau khi xác thực Google, app không còn loading lâu. Dữ liệu người dùng được tải song song thay vì tuần tự.
- **Hồ sơ Google được lưu đúng cách**: Người dùng đăng nhập lần đầu bằng Google nay có hồ sơ được tạo tự động trên hệ thống.
- **Email xác nhận tài khoản**: Giao diện email đẹp với logo và màu sắc của app, gửi khi đăng ký bằng email/mật khẩu.
- **Email xác thực lại (OTP)**: Giao diện email hiển thị mã OTP nổi bật, kèm hướng dẫn bảo mật.

---

## [b0.1.4] — 2026-04-05

- **Màn hình đăng nhập hiện nhanh hơn**: Splash screen không còn đứng yên chờ tải dữ liệu. Nếu chưa đăng nhập, app vào màn hình đăng nhập ngay lập tức. Nếu đã đăng nhập, splash giữ trong lúc tải dữ liệu ngầm rồi vào thẳng app — không còn màn hình trắng hay loading lâu.

---

## [b0.1.5] — 2026-04-05

- **Chi tiết và chỉnh sửa thực phẩm**: Nhấn vào bất kỳ mặt hàng nào trong kho để xem đầy đủ thông tin (danh mục, số lượng, ngày hết hạn) và chỉnh sửa trực tiếp. Không cần xoá rồi thêm lại.
- **Card thực phẩm cải tiến**: Mỗi card nay hiển thị nhãn danh mục màu sắc, ngày hết hạn cụ thể (dd/mm/yyyy) kèm nhãn tương đối ("5 ngày còn lại"), và nút chỉnh sửa riêng.
- **Xoá ngày hết hạn**: Khi chỉnh sửa, có thể xoá ngày hết hạn nếu không cần theo dõi.
- **Tối ưu hiệu năng**: Màn hình Khám phá không tải lại danh sách món Việt Nam mỗi lần chuyển tab. Kho thực phẩm chỉ rebuild khi dữ liệu kho thay đổi, không bị ảnh hưởng bởi cập nhật công thức.

---

## [b0.1.6] — 2026-04-05

- **Độ khó công thức theo ngôn ngữ**: Nhãn Dễ / Trung bình / Khó (hoặc Easy / Medium / Hard) trên chip độ khó và đơn vị năng lượng hiển thị đúng bản dịch đang chọn.
- **Kiểm thử & phân tích**: Bộ test mặc định kiểm tra bản dịch thay cho màn hình counter mẫu; `flutter analyze` sạch lỗi/cảnh báo liên quan các thay đổi này.
- **Tài liệu quy ước**: Cập nhật `RULES.md` cho khớp thực tế codebase (đã hoàn thành trước bản này).

---

## [b0.1.7] — 2026-04-05

- **Quét mã vạch & QR bằng camera**: Khi thêm thực phẩm, mở màn hình quét thật (hỗ trợ nhiều định dạng mã vạch và QR). Giá trị quét được điền vào ô tên; có nút đèn flash và hướng dẫn trên màn hình. Thay thế hoàn toàn chế độ giả lập trước đây.

---

## [b0.1.8] — 2026-04-05

### Hiệu năng

- **MaterialApp & theme**: Chỉ rebuild khi đổi theme / splash / auth / shell (không rebuild khi chỉ cập nhật kho hoặc công thức). Theme sáng/tối dùng instance tĩnh, tránh tạo lại `ThemeData` không cần thiết.
- **Thanh điều hướng**: `MainShell` chỉ rebuild nhãn tab khi đổi ngôn ngữ, không khi dữ liệu kho hay cache công thức thay đổi.
- **Ảnh công thức (TheMealDB)**: `Image.network` dùng `cacheWidth` / `cacheHeight` để giảm bộ nhớ decode khi cuộn danh sách và xem chi tiết.

### Tài liệu

- **README**: Bố cục lại cho dễ đọc (badge, mục lục, bảng phiên bản, hướng dẫn build release).
- **GitHub Release**: Thêm file `GITHUB_RELEASE.md` — nội dung gợi ý để dán khi tạo release.

### Build (Android)

- **`android/gradle.properties`**: `kotlin.incremental=false` để tránh lỗi biên dịch Kotlin khi thư mục project và pub-cache nằm khác ổ đĩa (Windows).

---

## [b0.1.9] — 2026-04-05

- **Icon ứng dụng**: Logo nguồn tại `code/app_icon.png`; tạo icon Android (adaptive) và iOS bằng `flutter_launcher_icons`. Thay file PNG trong `code/` rồi chạy `dart run flutter_launcher_icons` để cập nhật.
- **Tên file APK release**: Sau `flutter build apk --release`, thêm bản sao `harvestnhearth-<nhãn_CHANGELOG>.apk` trong cùng thư mục với `app-release.apk` (nhãn = mục `## [b0.x.x]` **cuối cùng** trong `CHANGELOG.md`).

---

## [b0.1.10] — 2026-04-05

- **Bản build đồ án / GitHub Release**: APK release (`app-release.apk` và `harvestnhearth-b0.1.10.apk`) dùng để nộp báo cáo và đính kèm release; không phát hành lên store.

---

## Sắp ra mắt (Backlog)

- [x] Quét mã vạch và mã QR thực sự bằng camera.
- [ ] Thông báo nhắc nhở khi thực phẩm sắp hết hạn.
- [ ] Danh sách mua sắm tự động từ kho thiếu.
- [x] Đồng bộ dữ liệu qua Supabase. ✓ Hoàn thành ở v1.2.0
- [ ] Ảnh thực phẩm tùy chỉnh từ camera.
- [ ] Widget màn hình chính (Android home screen widget) hiển thị cảnh báo.
