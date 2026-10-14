# AttendEase - FPT Academic Attendance & Sync Portal

Flutter cross-platform application (Android & Windows Desktop) using Google Sheets as a database, built for lecturers to manage classroom attendance, sync schedules, and analyze student absence risks.

---

## 📦 Danh mục Artifacts của dự án (Project Artifacts)

### 1. Design & UI/UX Artifacts (`design/`)
Thư mục `design/` lưu trữ toàn bộ đặc tả giao diện (Screen Specs), mã nguồn Tailwind HTML và bản xuất hình ảnh (PNG):

| STT | Artifact Folder | Tên màn hình / Chức năng | Định dạng tệp |
| :---: | :--- | :--- | :--- |
| 1 | `design/attendease_login/` | Màn hình đăng nhập Giảng viên & chứng thực Google OAuth | `code.html`, `screen.png` |
| 2 | `design/attendease_lecturer_dashboard/` | Bảng điều khiển tổng quan (Dashboard), chỉ số sĩ số | `code.html`, `screen.png` |
| 3 | `design/attendease_take_attendance_browse/` | Trình duyệt danh sách ca học / slot điểm danh | `code.html`, `screen.png` |
| 4 | `design/attendease_attendance_detail_marking/` | Giao diện chi tiết điểm danh sinh viên (Present/Absent/Note) | `code.html`, `screen.png` |
| 5 | `design/attendease_weekly_timetable/` | Lịch giảng dạy tuần theo Slot & Phòng học | `code.html`, `screen.png` |
| 6 | `design/attendease_attendance_report/` | Báo cáo tỷ lệ vắng mặt & ngưỡng cảnh báo (15%/20%) | `code.html`, `screen.png` |
| 7 | `design/attendease_fap_sync_center/` | Trung tâm đồng bộ dữ liệu FAP & xuất báo cáo | `code.html`, `screen.png` |
| 8 | `design/attendease_ai_assistant/` | Trợ lý AI phân tích rủi ro & kích hoạt thông báo email | `code.html`, `screen.png` |
| 9 | `design/attendease_settings/` | Cấu hình tham số ngưỡng vắng và kết nối hệ thống | `code.html`, `screen.png` |
| 10 | `design/academic_utility_portal/` | Cổng tiện ích học vụ tổng hợp | `code.html`, `screen.png` |
| 11 | `design/attendease_logo/` | Bộ nhận diện thương hiệu & Logo AttendEase | Asset files |

---

### 2. Design System & Flutter Handoff Artifacts

#### A. Bảng ánh xạ Design Tokens $\rightarrow$ Flutter Theme (`lib/core/theme/app_theme.dart`)
* **Color Tokens:**
  * `primary` (`#005994`) $\rightarrow$ `AppColors.primaryDark` / `ColorScheme.onPrimaryContainer`
  * `primary-container` (`#0072BC`) $\rightarrow$ `AppColors.primary` / `ColorScheme.primary`
  * `secondary` (`#35618D`) $\rightarrow$ `AppColors.secondary` / `ColorScheme.secondary`
  * `tertiary-container` (`#BA4C00`) $\rightarrow$ `AppColors.tertiary` (màu cam FPT)
  * `surface` / `background` (`#F8F9FF`) $\rightarrow$ `AppColors.surface` / `scaffoldBackgroundColor`
  * `surface-container-low` (`#EFF4FF`) $\rightarrow$ `AppColors.surfaceLow` (Breadcrumb, border)
  * `surface-container` (`#E5EEFF`) $\rightarrow$ `AppColors.surfaceContainer`
  * `on-surface` (`#0B1C30`) $\rightarrow$ `AppColors.onSurface`
  * `on-surface-variant` (`#404751`) $\rightarrow$ `AppColors.onSurfaceVariant`
  * `outline-variant` (`#C0C7D3`) $\rightarrow$ `AppColors.outlineVariant`
  * `error` / `error-container` (`#BA1A1A` / `#FCE8E6`) $\rightarrow$ `AppColors.error` / `AppColors.errorContainer`
* **Typography Tokens (`TextTheme`):**
  * `headline-lg` (20px / 28px, w600) $\rightarrow$ `headlineLarge`
  * `headline-md` (16px / 24px, w600) $\rightarrow$ `headlineMedium`
  * `headline-sm` (14px / 20px, w600) $\rightarrow$ `headlineSmall`
  * `body-lg / body-md / body-sm` (15px / 14px / 13px) $\rightarrow$ `bodyLarge / bodyMedium / bodySmall`
  * `label-lg / label-md / label-sm` (13px / 12px / 11px) $\rightarrow$ `labelLarge / labelMedium / labelSmall`
* **Shape & Spacing Tokens:**
  * `borderRadius.xl` (6px) $\rightarrow$ `CardTheme.shape`, `InputDecorationTheme.border`

#### B. Bảng ánh xạ Components $\rightarrow$ Flutter Widgets (`lib/core/widgets/`)
| Component (Figma/Design) | Biến thể / Trạng thái (Variants/States) | Flutter Widget tương ứng | Đường dẫn mã nguồn |
| :--- | :--- | :--- | :--- |
| **Status Chip** | Present, Absent, Warning, Neutral; with/without Icon | `StatusChip` | `lib/core/widgets/status_chip.dart` |
| **Navigation Bar** | Desktop SideBar $\leftrightarrow$ Mobile BottomBar; Active/Inactive | `NavBar`, `MobileNavBar` | `lib/core/widgets/nav_bar.dart` |
| **Breadcrumb Bar** | Home $\rightarrow$ Path items | `BreadcrumbBar` | `lib/core/widgets/breadcrumb_bar.dart` |
| **App Header** | Logo, Term badge, User Avatar, Logout | `AppHeader` | `lib/core/widgets/app_header.dart` |
| **App Shell** | Responsive split layout ($< 700\text{px} \rightarrow \text{Mobile}$) | `AppShell` | `lib/core/widgets/app_shell.dart` |
| **Attendance Card / Row**| Unmarked, Present, Absent, Edit Note | `AttendanceCard` / `DataRow` | `lib/features/attendance/attendance_page.dart` |

---

### 3. Source Code & Architecture Artifacts (`lib/`)

- **Composition Root & Routing:** `lib/main.dart` thiết lập Dependency Injection và định tuyến `go_router` qua `AppShell`.
- **Feature Modules (`lib/features/`):**
  - `auth/`: Đăng nhập Google OAuth (hỗ trợ Android PKCE qua loopback server và Desktop browser callback).
  - `home/`: Dashboard thống kê slot trong ngày và tổng số lớp học.
  - `attendance/`: Duyệt ca học (`SessionBrowserPage`) và điểm danh chi tiết (`AttendancePage`). Hỗ trợ lưu nháp, chặn gửi trùng lặp.
  - `classes/`: Danh sách các lớp học phần được phân công (`MyClassesPage`).
  - `timetable/`: Lịch dạy tuần học trực quan theo slot (`TimetablePage`).
  - `reports/`: Báo cáo vắng học & phát hiện sinh viên vượt ngưỡng 15%/20% (`AttendanceReportPage`).
  - `export/`: Xuất báo cáo và đối soát đồng bộ hệ thống FAP (`ExportPage`).
  - `ai_assistant/`: Trợ lý điểm danh & kích hoạt gửi mail cảnh báo vắng (`AIAssistantPage`).
  - `settings/`: Cấu hình hệ thống, ngưỡng vắng (`SettingsPage`).
- **Core Services (`lib/services/`):**
  - `google_sheet_service.dart`: Quản lý OAuth 2.0, refresh token cache, xác thực cấu trúc bảng tính (schema validation), đọc/ghi dữ liệu.
  - `attendance_stats_service.dart`: Xử lý tính toán thống kê, phân loại nguy cơ (`ok`, `warning`, `banned`).
  - `attendance_notification_service.dart`: Gửi cảnh báo nguy cơ qua endpoint Firebase Cloud Function và deduplicate qua `shared_preferences`.

---

### 4. Data & Testing Artifacts

- **Google Sheets Database Schema:** Bảng tính Google Sheets gồm 3 tab chuẩn:
  - `students`: `student_id`, `roll_number`, `full_name`, `class_code`, `email`
  - `schedule`: `session_id`, `class_code`, `course_code`, `date`, `slot`, `room`, `status`
  - `attendance`: `session_id`, `student_id`, `status`, `note`, `updated_at`
- **Sample Data:** `test_samples/sample_students_SE1801.csv` phục vụ kiểm thử nạp danh sách lớp.
- **Automated Tests:** `test/widget_test.dart` kiểm tra rendering và tương tác widget.

---

### 5. Documentation Artifacts

- `README.md`: Hướng dẫn tổng quan dự án, danh mục artifacts, cấu hình và khởi chạy.
- `CLAUDE.md`: Hướng dẫn kiến trúc, thiết lập môi trường Android/Desktop và quy chuẩn phát triển.
- `PRIVACY.md`: Chính sách bảo mật thông tin và quyền hạn truy cập dữ liệu Google Sheets.
- `docs/firebase-email-notifications.md`: Đặc tả API contract cho Firebase Cloud Functions gửi email cảnh báo.

---

## ⚙️ Yêu cầu & Cấu hình môi trường

### Yêu cầu tiên quyết
- Flutter SDK `^3.13.3` trở lên.
- Android SDK (API 34+ hoặc thiết bị/máy ảo Android) hoặc Visual Studio C++ (nếu chạy Desktop Windows).
- Google Cloud Project bật **Google Sheets API** và tạo OAuth Client ID.

### Cấu hình `.env`
Tạo file `.env` tại thư mục gốc của project:
```env
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id
ATTENDANCE_NOTIFICATION_ENDPOINT=https://your-cloud-function-url
ATTENDANCE_TEACHER_EMAIL=lecturer@university.edu
```

---

## 🚀 Hướng dẫn khởi chạy & Kiểm thử

1. **Cài đặt thư viện:**
   ```powershell
   flutter pub get
   ```

2. **Kiểm tra cú pháp & phân tích tĩnh:**
   ```powershell
   flutter analyze lib
   ```

3. **Chạy kiểm thử tự động:**
   ```powershell
   flutter test
   ```

4. **Khởi chạy ứng dụng:**
   - Trên Android:
     ```powershell
     flutter run -d <android-device-id>
     ```
   - Trên Windows Desktop:
     ```powershell
     flutter run -d windows
     ```

5. **Build gói cài đặt:**
   ```powershell
   flutter build apk        # Xuất file APK cho Android
   flutter build windows    # Xuất file chạy cho Windows Desktop
   ```
