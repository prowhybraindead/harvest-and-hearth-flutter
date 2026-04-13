# Deploy Harvest & Hearth API trên Pterodactyl Hosting

Hướng dẫn deploy API Node.js lên Pterodactyl Panel (thường dùng cho game servers, nhưng cũng hỗ trợ Node.js apps).

## Yêu cầu

- Pterodactyl Panel với quyền tạo server
- MongoDB Atlas cluster (cloud)
- Clerk Dashboard để lấy Secret Key

---

## Bước 1: Chuẩn bị trên MongoDB Atlas

1. Đăng nhập [MongoDB Atlas](https://cloud.mongodb.com)
2. Tạo cluster hoặc dùng cluster có sẵn
3. **Database Access**:
   - Tạo user database cho app
   - Lưu username và password (password cần URL-encode nếu có ký tự đặc biệt)
4. **Network Access**:
   - Thêm IP `0.0.0.0/0` để cho phép Pterodactyl truy cập
   - Hoặc thêm IP cụ thể của server Pterodactyl nếu biết
5. **Connect** → **Drivers** → Copy connection string
   - Thay `<password>` bằng password user database
   - Example: `mongodb+srv://harvestapp:PASS%40WORD@cluster0.abc12.mongodb.net/harvest_hearth?retryWrites=true&w=majority`

---

## Bước 2: Lấy Clerk Secret Key

1. Đăng nhập [Clerk Dashboard](https://dashboard.clerk.com)
2. Chọn project của bạn
3. **API Keys** → Copy **Secret Key**
   - Format: `sk_live_...` hoặc `sk_test_...`
   - Chỉ dùng trên server, KHÔNG đưa vào app Flutter

---

## Bước 3: Upload code lên Pterodactyl

### Option A: Sử dụng Pterodactyl SFTP

1. Truy cập Pterodactyl Panel → Chọn server
2. **Files** → Upload toàn bộ thư mục `server/`:
   ```
   server/
   ├── package.json
   ├── src/
   │   └── index.js
   └── .env (không cần upload, sẽ dùng env vars)
   ```

### Option B: Git Repository (nếu Pterodactyl hỗ trợ)

1. Push code lên GitHub/GitLab
2. Trên Pterodactyl, cấu hình Git repo URL
3. Pterodactyl sẽ tự động clone khi deploy

---

## Bước 4: Cấu hình file .env trên Pterodactyl

Vì Pterodactyl của bạn sử dụng file `.env` thay vì environment variables trong panel:

1. Truy cập Pterodactyl Panel → Chọn server → **Files**
2. Tìm file `.env.example` trong thư mục server
3. **Rename** hoặc **Copy** thành file `.env`:
   - Đổi tên: `.env.example` → `.env`
   - Hoặc copy và đặt tên `.env`
4. **Edit file `.env`** với các giá trị thật:

```env
# Server Config
PORT=25165
SERVER_PORT=25165
NODE_ENV=production

# ===== CẤU HÌNH CỦA BẠN =====
# MongoDB Atlas Connection String
MONGODB_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/harvest_hearth?retryWrites=true&w=majority

# Clerk Secret Key
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Lưu ý quan trọng:**
- **MONGODB_URI**: Thay `USER` và `PASSWORD` bằng credentials thật
  - Password phải được **URL-encode** nếu có ký tự đặc biệt:
  - `@` → `%40`
  - `#` → `%23`
  - `:` → `%3A`
  - `?` → `%3F`
  - `&` → `%26`
  - Space → `%20`
- **CLERK_SECRET_KEY**: Lấy từ Clerk Dashboard → API Keys
  - Bắt đầu với `sk_live_...` hoặc `sk_test_...`
- **PORT**: Mặc định là `25165` - phải khớp với port trong **Allocations** tab
- **Node.js** sẽ tự động đọc `.env` file khi start (như localhost)

---

## Bước 5: Cấu hình Startup Command

Trên Pterodactyl → Chọn server → **Startup**:

**Startup Command:** (đã bị lock - không cần chỉnh)
```bash
# Pterodactyl sẽ tự động chạy theo cấu hình của bạn
# Command sẽ đọc từ file pterodactyl-egg.json
# Mặc định: npm install && node src/index.js
```

**Installation Directory:** (để trống hoặc cấu hình theo path của bạn)

**Tự động:**
- Khi install/clone server, script sẽ tự tạo file `.env` từ `.env.example`
- Bạn chỉ cần edit file `.env` với giá trị thật
- Restart server để áp dụng thay đổi

---

## Bước 6: Allocation Port

1. Truy cập **Allocations** tab
2. Thêm port `8787` (hoặc port bạn cấu hình ở Bước 4)
3. Lưu lại

---

## Bước 7: Start Server

1. Quay lại console của server
2. Nhấn **Start**
3. Xem logs để xác nhận:
   ```
   [Harvest & Hearth API] Server listening on 0.0.0.0:8787
   [Harvest & Hearth API] Environment: production
   [Harvest & Hearth API] MongoDB: Connected
   ```
4. Kiểm tra health:
   - Mở browser: `http://YOUR_SERVER_IP:8787/health`
   - Phải trả về: `{"ok":true}`

---

## Bước 8: Cấu hình Flask App (client)

Trong file `.env` của app Flutter:

```env
API_BASE_URL=http://YOUR_PTERODACTYL_SERVER_IP:8787
CLERK_PUBLISHABLE_KEY=pk_test_...
```

Nếu có domain, thay `IP:PORT` bằng domain:
```env
API_BASE_URL=https://api.yourdomain.com
```

**Lưu ý:** Nếu dùng SSL/HTTPS, cần cấu hình reverse proxy (nginx) trước Pterodactyl.

---

## Troubleshooting

### 1. MongoDB Connection Error
```
MongoParseError: ...
```
- **Kiểm tra:** MONGODB_URI đúng format, password đã URL-encode
- **Kiểm tra:** File `.env` đã được tạo và edit đúng
- **Kiểm tra:** Network Access trên Atlas có cho phép IP của Pterodactyl
- **Kiểm tra:** User database có quyền truy cập database

### 2. Clerk Authentication Failed
```
Invalid or expired token
```
- **Kiểm tra:** CLERK_SECRET_KEY trong file `.env` đúng
- **Kiểm tra:** Clerk Dashboard xác nhận Secret Key còn hợp lệ
- **Kiểm tra:** Token từ Clerk SDK được gửi đúng format `Bearer <token>`

### 3. Server không start
- **Kiểm tra:** Logs trong Pterodactyl console
- **Kiểm tra:** File `.env` đã tồn tại trong thư mục server
- **Kiểm tra:** Node.js version (cần >= 18)
- **Kiểm tra:** `npm install` có lỗi dependency không
- **Đảm bảo:** PORT trong `.env` khớp với port trong Allocations tab

### 4. Port không accessible
- **Kiểm tra:** Port `25165` đã được thêm vào **Allocations**
- **Kiểm tra:** File `.env` có PORT=25165 không
- **Kiểm tra:** Firewall trên server Pterodactyl mở port đó
- **Kiểm tra:** Server thực sự đang listen trên port đó (view logs)

### 5. Application crash sau khi start
- **Xem logs:** Kiểm tra error messages trong console
- **Common causes:**
  - File `.env` không tồn tại hoặc sai format
  - MONGODB_URI trong file `.env` placeholder chưa thay
  - CLERK_SECRET_KEY trong file `.env` placeholder chưa thay
  - MongoDB connection failed
  - Invalid code syntax

### 6. Status: "Starting" nhưng không hiển thị logs
- **Kiểm tra:** Chờ 1-2 phút vì npm install có thể lâu
- **Kiểm tra:** Storage quota của server Pterodactyl
- **Kiểm tra:** Node modules có cài thành công không (xem logs)

### 7. 404 Not Found khi gọi API
- **Kiểm tra:** API_BASE_URL trong app Flutter đúng format: `http://IP:25165`
- **Kiểm tra:** Server đang chạy (status: Running)
- **Kiểm tra:** Port 25165 đã được add vào Allocations
- **Test health endpoint:** curl http://IP:25165/health

---

## Commands hữu ích

### Restart server
```bash
# Trong Pterodactyl console:
# 1. Stop
# 2. Start
```

### View logs
- Pterodactyl **Console** tab real-time logs
- **Files** → `logs/` (nếu có cấu hình log files)

### Update code
1. Upload file mới qua SFTP hoặc git pull
2. Restart server trong Pterodactyl

---

## Cấu tao Nginx Reverse Proxy (tùy chọn - để dùng HTTPS)

Nếu có domain và muốn dùng HTTPS:

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Sau đó dùng Certbot để lấy SSL:
```bash
sudo certbot --nginx -d api.yourdomain.com
```

Update API_BASE_URL trong app Flutter:
```env
API_BASE_URL=https://api.yourdomain.com
```

---

## Performance Tips

1. **MongoDB Connection Pooling**:
   - Mặc định MongoDB driver giữ 5 connections
   - Tăng nếu cần heavy load
   - Không cần thay đổi cho đồ án sinh viên

2. **Compression**: Đã bật gzip trong code (middleware `compression`)

3. **CORS**: Đã cấu hình cho phép all origins (tweak nếu cần security)

4. **Rate Limiting**: Có thể thêm nếu cần (không bắt buộc cho đồ án)

---

## Security Notes

- ✅ Secrets (MONGODB_URI, CLERK_SECRET_KEY) lưu trong Pterodactyl env vars
- ✅ Không commit `.env` file
- ✅ Clerk Secret key chỉ dùng trên server
- ✅ MongoDB password được URL-encode
- ⚠️ CORS hiện tại cho phép all origins - tighten trong production
- ⚠️ Không có rate limiting - add nếu cần production

---

## So sánh với Render

| Đặc điểm | Pterodactyl | Render |
|---------|-------------|--------|
| Platform | Self-hosted / VPS | Managed PaaS |
| Cost | Phụ thuộc VPS của bạn | Free tier có, paid sau |
| Control | Cao (full server access) | Thấp (managed) |
| Deploy | Manual upload | Git + auto deploy |
| Scaling | Manual | Auto scaling |
| Dễ dùng | Cần config nhiều | Dễ hơn |
| Phù hợp | Đồ án, demo, hobby | Production, startup |

---

## Hỗ trợ

Nếu gặp vấn đề:
1. Check logs trong Pterodactyl console
2. Verify env vars đúng
3. Test MongoDB connection locally
4. Test Clerk token với curl/Postman
5. Review [troubleshooting section](#troubleshooting)

---

Chúc bạn deploy thành công trên Pterodactyl! 🚀
