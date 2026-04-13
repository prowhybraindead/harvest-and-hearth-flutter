# Quick Start - Pterodactyl Deploy (File .env Mode)

Hướng dẫn nhanh deploy lên Pterodactyl với file `.env`.

---

## ✅ Đã config sẵn

Dự án đã được cấu hình để deploy lên Pterodactyl với file `.env`:

1. ✅ **[package.json](package.json)** - Đã thêm `dotenv` dependency
2. ✅ **[src/index.js](src/index.js)** - Đã thêm `import 'dotenv/config'` để đọc file `.env`
3. ✅ **[.env.example](.env.example)** - File mẫu với PORT=25165
4. ✅ **[pterodactyl-egg.json](pterodactyl-egg.json)** - Pterodactyl Egg template (sẽ tự tạo .env)
5. ✅ **[PTERODACTYL.md](PTERODACTYL.md)** - Hướng dẫn chi tiết

---

## 🚀 5 Bước Deploy Nhanh

### Bước 1: Upload Code
- Upload toàn bộ thư mục `server/` lên Pterodactyl (SFTP hoặc Git)

### Bước 2: Tạo file .env
- Vào **Files** tab trong Pterodactyl
- Tìm file `.env.example`
- Copy → Rename thành `.env`
- (Nếu dùng Egg, file sẽ tự tạo sau install)

### Bước 3: Edit file .env
Mở file `.env` và thay thế các placeholder:

```env
# PORT đã sẵn là 25165 (đừng đổi)
PORT=25165
SERVER_PORT=25165
NODE_ENV=production

# Thay thành MongoDB URI của bạn
MONGODB_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/harvest_hearth?retryWrites=true&w=majority

# Thay thành Clerk Secret Key của bạn
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Lưu ý:**
- MongoDB password phải URL-encode nếu có ký tự đặc biệt
- Không có khoảng trắng xung quanh dấu `=`

### Bước 4: Add Port
- Vào **Allocations** tab
- Thêm port: `25165`
- Lưu lại

### Bước 5: Start Server
- Quay lại Console
- Nhấn **Start**
- Chờ vài giây...

---

## ✅ Kiểm tra Deploy Thành Công

### 1. View Logs
Console phải hiển thị:

```
Installing dependencies...
[Harvest & Hearth API] Server listening on 0.0.0.0:25165
[Harvest & Hearth API] Environment: production
[Harvest & Hearth API] MongoDB: Connected
```

### 2. Test Health Endpoint
Open trình duyệt hoặc curl:

```bash
curl http://YOUR_SERVER_IP:25165/health
```

Expected response:
```json
{"ok":true}
```

### 3. Configure Flutter App
Trong file `.env` của app Flutter:

```env
API_BASE_URL=http://YOUR_PTERODACTYL_IP:25165
CLERK_PUBLISHABLE_KEY=pk_test_...
```

Build và install APK → test đăng nhập, thêm thực phẩm, etc.

---

## 🔧 Common Issues & Fixes

### ❌ Server không start hostname / CONNECT timeout
**Lỗi:** `MongoServerError: getaddrinfo ENOTFOUND cluster0.xxxxx.mongodb.net`
**Fix:**
- Kiểm tra file `.env` đã tạo chưa
- Kiểm tra MONGODB_URI đúng format
- Kiểm tra Network Access trên Atlas (cho 0.0.0.0/0)

### ❌ Port không thể truy cập
**Lỗi:** `curl: (7) Failed to connect to xxx.xxx.xxx.xxx port 25165: Connection refused`
**Fix:**
- Kiểm tra port 25165 đã thêm vào Allocations chưa
- Kiểm tra PORT trong file `.env` = 25165
- Restart server

### ❌ Clerk authentication failed
**Lỗi:** `Invalid or expired token`
**Fix:**
- Kiểm tra CLERK_SECRET_KEY trong file `.env`
- Lấy lại key từ Clerk Dashboard → API Keys

### ❌ File .env không tìm thấy
**Lỗi:** `MongoServerError: Missing MONGODB_URI`
**Fix:**
- Vào Files tab, tạo file `.env` nếu chưa có
- Copy nội dung từ `.env.example` vào `.env`
- Điền giá trị thật

### ❌ Nhập sai giá trị trong .env
**Lỗi:** Server crash với error log
**Fix:**
- Đảm bảo không có khoảng trắng xung quanh dấu `=`
- Đảm bảo MongoDB URI đúng format
- Đảm bảo không có ký tự đặc biệt chưa URL-encode trong password

---

## 📝 File .env mẫu hoàn chỉnh

```env
# ================== SERVER CONFIG ==================
PORT=25165
SERVER_PORT=25165
NODE_ENV=production

# ================== DATABASE CONFIG ==================
# MongoDB Atlas Connection String
# Password URL-encode nếu có ký tự đặc biệt:
# @ → %40, # → %23, : → %3A, ? → %3F, & → %26, space → %20
MONGODB_URI=mongodb+srv://harvestapp:PASS%40WORD@cluster0.abc12.mongodb.net/harvest_hearth?retryWrites=true&w=majority

# ================== AUTHENTICATION ==================
# Clerk Secret Key
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 🎯 Tips

1. **Đừng đổi PORT = 25165** - nó đã được config sẵn
2. **Backup file .env** trước khi sửa
3. **Test MongoDB connection** với MongoDB Compass trước khi deploy
4. **Test Clerk Secret Key** bằng cách tạo test user trong Clerk Dashboard
5. **Xem logs** trong Pterodactyl console nếu có vấn đề

---

## 📚 Documents chi tiết

- [PTERODACTYL.md](PTERODACTYL.md) - Hướng dẫn đầy đủ với troubleshooting
- [PTERODACTYL_CHANGES.md](../PTERODACTYL_CHANGES.md) - Tóm tắt các thay đổi
- [pterodactyl-egg.json](pterodactyl-egg.json) - Egg template (nếu cần import)

---

**Xong!** Server đã sẵn sàng deploy lên Pterodactyl với file `.env` 🚀

Nếu cần hỗ trợ, check [PTERODACTYL.md#troubleshooting](PTERODACTYL.md#troubleshooting)
