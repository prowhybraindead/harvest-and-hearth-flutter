# Thay đổi để hỗ trợ Pterodactyl Hosting

Dưới đây là tóm tắt các thay đổi đã thực hiện để server có thể deploy lên Pterodactyl Hosting.

## Các file đã thay đổi/tạo mới

### 1. ✏️ Đã chỉnh sửa: `server/src/index.js`

**Thay đổi 1: Hỗ trợ cả PORT và SERVER_PORT**
```javascript
// Trước:
const PORT = Number(process.env.PORT) || 8787;

// Sau:
const PORT = Number(process.env.PORT) || Number(process.env.SERVER_PORT) || 8787;
const NODE_ENV = process.env.NODE_ENV || 'production';
```
**Lý do:** Pterodactyl thường dùng `SERVER_PORT`, nên hỗ trợ cả 2 để linh hoạt.

**Thay đổi 2: Bỏ `trust proxy` middleware**
```javascript
// Trước:
app.set('trust proxy', 1);

// Sau: (đã xóa dòng này)
```
**Lý do:** `trust proxy` dùng cho reverse proxy (như Nginx) hoặc cloud platform (như Render). Pterodactyl thường truy cập trực tiếp, nên không cần.

**Thay đổi 3: Thêm graceful shutdown**
```javascript
// Thêm hàm gracefulShutdown và process event listeners
const gracefulShutdown = async (signal) => {
  console.log(`\n[Harvest & Hearth API] ${signal} received, shutting down gracefully...`);
  server.close(async () => {
    console.log('[Harvest & Hearth API] HTTP server closed');
    try {
      if (client) {
        await client.close();
        console.log('[Harvest & Hearth API] MongoDB connection closed');
      }
      process.exit(0);
    } catch (err) {
      console.error('[Harvest & Hearth API] Error during shutdown:', err);
      process.exit(1);
    }
  });

  // Force shutdown sau 10s
  setTimeout(() => {
    console.error('[Harvest & Hearth API] Forcing shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
```
**Lý do:** Pterodactyl gửi SIGTERM khi stop/restart server. Graceful shutdown:
- Đóng HTTP server cleanly
- Đóng MongoDB connection
- Đợi 10s trước khi force kill (để complete in-progress requests)

**Thay đổi 4: Cải thiện logging**
```javascript
// Trước:
console.log(`API listening on 0.0.0.0:${PORT}`);

// Sau:
console.log(`[Harvest & Hearth API] Server listening on 0.0.0.0:${PORT}`);
console.log(`[Harvest & Hearth API] Environment: ${NODE_ENV}`);
console.log(`[Harvest & Hearth API] MongoDB: Connected`);
```
**Lý do:** Logging rõ ràng hơn với prefix, dễ debug trong Pterodactyl console.

**Thay đổi 5: Error logging**
```javascript
// Trước:
console.error(e);

// Sau:
console.error('[Harvest & Hearth API] Fatal error:', e);
```
**Lý do:** Log lỗi rõ ràng hơn để dễ tìm ra vấn đề.

---

### 2. ✨ Đã tạo mới: `server/.env.pterodactyl`

File mẫu cấu hình environment variables cho Pterodactyl:

```env
PORT=8787
SERVER_PORT=8787
NODE_ENV=production
MONGODB_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/harvest_hearth?retryWrites=true&w=majority
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Lưu ý:**
- File này KHÔNG được commit (đã thêm vào .gitignore)
- Copy nội dung vào Pterodactyl Environment Variables panel
- Thay thế các placeholder với giá trị thật

---

### 3. 📖 Đã tạo mới: `server/PTERODACTYL.md`

Hướng dẫn đầy đủ deploy lên Pterodactyl, bao gồm:

- Chuẩn bị MongoDB Atlas
- Lấy Clerk Secret Key
- Upload code lên Pterodactyl (SFTP/Git)
- Cấu hình Environment Variables
- Cấu hình Startup Command
- Allocation Port
- Start server & verify
- Cấu hình Flutter app để connect
- Troubleshooting common issues
- Nginx reverse proxy configuration (tùy chọn)
- Performance & Security notes
- So sánh với Render

---

### 4. 🥚 Đã tạo mới: `server/pterodactyl-egg.json`

Pterodactyl Egg configuration file - template để tạo server tự động trên Pterodactyl.

**Features:**
- Docker image: `node:20-alpine`
- Startup command: `npm install && node src/index.js`
- Pre-configured environment variables:
  - `PORT` (default: 8787)
  - `SERVER_PORT` (default: 8787)
  - `NODE_ENV` (default: production)
  - `MONGODB_URI` (required, secret)
  - `CLERK_SECRET_KEY` (required, secret)

**Cách dùng:**
1. Import file vào Pterodactyl Panel → Eggs
2. Tạo server mới với Egg này
3. Pterodactyl sẽ auto-setup environment variables
4. Chỉ cần điền MONGODB_URI và CLERK_SECRET_KEY
5. Start server

---

### 5. ✏️ Đã cập nhật: `server/README.md`

Thêm section mới:

```markdown
## Deploy Platform

### Option 1: Pterodactyl Hosting (Khuyên dùng cho đồ án/Hobby)
Xem hướng dẫn chi tiết: [PTERODACTYL.md](PTERODACTYL.md)

### Option 2: Render (Cloud PaaS)
...
```

Giúp người dùng dễ chọn loại platform phù hợp.

---

## Kiểm tra trước khi deploy

### Local test (không cần Pterodactyl):

```bash
cd server

# Cài dependencies
npm install

# Cấu hình env (tạo file .env.local)
cp .env.pterodactyl .env.local
# Edit .env.local với giá trị thật

# Start server
npm start

# Test health endpoint
curl http://localhost:8787/health
# Expected: {"ok":true}
```

### Pterodactyl test sau khi deploy:

1. Đăng nhập Pterodactyl Panel → Chọn server
2. **Console** tab → Nhấn **Start**
3. Xem logs:
   ```
   Installing dependencies...
   [Harvest & Hearth API] Server listening on 0.0.0.0:8787
   [Harvest & Hearth API] Environment: production
   [Harvest & Hearth API] MongoDB: Connected
   ```
4. Mở browser: `http://YOUR_SERVER_IP:8787/health`
   - Must return: `{"ok":true}`

---

## Environment Variables Reference

| Variable | Required | Default | Description | Secret |
|----------|----------|---------|-------------|--------|
| `PORT` | No | `8787` | Port cho API | No |
| `SERVER_PORT` | No | `8787` | Pterodactyl port (cùng PORT) | No |
| `NODE_ENV` | No | `production` | Environment mode | No |
| `MONGODB_URI` | **Yes** | - | MongoDB connection string | **Yes** |
| `CLERK_SECRET_KEY` | **Yes** | - | Clerk Secret Key | **Yes** |

**Notes:**
- MONGODB_URI: Password phải URL-encode nếu có ký tự đặc biệt
- CLERK_SECRET_KEY: Lấy từ Clerk Dashboard, bắt đầu với `sk_test_...` hoặc `sk_live_...`

---

## Tương thích ngược

✅ **NO BREAKING CHANGES** - Mọi thay đổi đều backward compatible:

- Server vẫn hoạt động bình thường trên Render (nếu dùng `PORT` env var)
- Server vẫn hoạt động khi deploy local (không cần env vars, dùng defaults)
- Flutter app không cần thay đổi gì (vẫn dùng `API_BASE_URL` để connect)

---

## So sánh: Pterodactyl vs Render

| Đặc điểm | Pterodactyl | Render |
|---------|-------------|--------|
| **Cấu hình server** | Thủ công hơn | Tự động hơn |
| **Environment vars** | Manual panel | Auto inject |
| **Deploy** | Upload/ Git push + restart | Tự động sau git push |
| **Startup command** | Manual: `npm install && npm start` | Auto: Dockerfile |
| **Shutdown handling** | Graceful (SIGTERM/SIGINT) | Container runtime |
| **Cost** | Miễn phí (nếu có VPS) | Free tier + paid plans |
| **Dễ dùng** | Cần kiến thức server | Dùng cho mọi người |
| **Flexible** | Cao - có thể custom nhiều | Thấp - managed |
| **Phù hợp** | Đồ án, demo, hobby projects | Production, startup |

---

## Next Steps

Sau khi server đã deploy lên Pterodactyl thành công:

1. **Cấu hình Flutter app:**
   ```env
   # Trong .env của app Flutter
   API_BASE_URL=http://YOUR_PTERODACTYL_IP:8787
   CLERK_PUBLISHABLE_KEY=pk_test_...
   ```

2. **Test connectivity:**
   - Build Flutter APK
   - Install trên device/emulator
   - Test: Login → Add food item → View inventory
   - Check server logs trong Pterodactyl console

3. ** Nếu có domain:**
   - Cấu hình Nginx reverse proxy
   - Setup SSL với Certbot
   - Update `API_BASE_URL` thành `https://api.yourdomain.com`

4. **Monitor:**
   - Xem logs trong Pterodactyl console регулярно
   - Check MongoDB Atlas metrics
   - Monitor Clerk Dashboard usage

---

## Cần hỗ trợ?

Nếu bạn gặp vấn đề khi deploy lên Pterodactyl:

1. **Check logs** trong Pterodactyl console đầu tiên
2. **Review** [PTERODACTYL.md](PTERODACTYL.md) - Troubleshooting section
3. **Verify** environment variables đúng (đặc biệt MONGODB_URI và CLERK_SECRET_KEY)
4. **Test** MongoDB connection từ local bằng MongoDB Compass
5. **Test** Clerk token với curl/Postman

---

**Xong!** Server đã sẵn sàng deploy lên Pterodactyl. 🚀

Chúc bạn thành công với đồ án!
