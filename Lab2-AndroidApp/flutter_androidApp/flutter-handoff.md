# Flutter Design Handoff & Technical Summary

**Dự án:** AttendEase - FPT Academic Attendance & Sync Portal (PRM393 - Lab 2 Android App)  
**Nhóm phát triển:**
- **Hồ Minh** (MinhCoffee) - System Architecture & Alignment
- **Lâm Thiên Hải Anh** - Android Native Adaptation & Responsive UI
**Kho mã nguồn GitHub:** [https://github.com/MinhCoffee/PRM5M.git](https://github.com/MinhCoffee/PRM5M.git) (Nhánh `main`)  
**Minh chứng phục vụ:** Slide 12 (Flutter Handoff / Summary)

---

## 1. Đặc tả Handoff chuẩn 6 mục theo từng màn hình thực tế (Screen Spec Handoff)

### 📱 SCR-01: Login Screen
1. **Screen Name & Route:** `LoginPage` (`/login`), file: `lib/features/auth/login_page.dart`
2. **Layout & Responsive Behavior:** Căn giữa màn hình (`Center`), giới hạn chiều rộng tối đa `maxWidth: 420` bằng `ConstrainedBox` trên cả Mobile lẫn Desktop.
3. **Design Tokens Applied:** `AppColors.surface` (`#F8F9FF`), `AppColors.primary` (`#0072BC`), `TextTheme.headlineLarge`, bo góc `6px`.
4. **Widgets & Components:** `Scaffold`, `Card`, `FilledButton.icon`, `CircularProgressIndicator`, biểu tượng trường học `Icons.school_outlined`.
5. **Interactive States:** Normal, Loading (vòng xoay vô hiệu hóa nút), Error (dòng chữ đỏ cảnh báo lỗi kết nối).
6. **Edge Cases & Error Handling:** Tự động đăng nhập lại bằng cached refresh token (`fap_attendance_oauth.json`); nếu người dùng bấm Logout, thêm cờ `logout=1` để xóa token.

---

### 📱 SCR-02: Lecturer Dashboard
1. **Screen Name & Route:** `HomePage` (`/home`), file: `lib/features/home/home_page.dart`
2. **Layout & Responsive Behavior:** Trên Mobile (< 700px): Thẻ thống kê dàn 2 cột (`two-column stat cards`) kèm Safe Area header; trên Desktop: dàn 4 cột ngang.
3. **Design Tokens Applied:** `AppColors.surfaceLow`, `AppColors.primaryDark`, `TextTheme.headlineMedium`, `AppColors.green` (`#6CB33F`).
4. **Widgets & Components:** `AppShell`, `Card`, Thẻ Metric (Slots hôm nay, sĩ số có mặt, sinh viên bị cấm thi, số bản nháp), `StatusChip`.
5. **Interactive States:** Skeleton khi đang tải dữ liệu từ Google Sheets; chạm vào ca học để mở nhanh màn hình điểm danh.
6. **Edge Cases & Error Handling:** Ngày không có ca học $\rightarrow$ Hiển thị Empty State thông báo *"Hôm nay thầy không có lịch giảng dạy"*.

---

### 📱 SCR-03: Take Attendance Session Browser
1. **Screen Name & Route:** `AttendanceBrowsePage` (`/take-attendance`), file: `lib/features/attendance/attendance_browse_page.dart`
2. **Layout & Responsive Behavior:** Nhóm thẻ ca học theo hàng "Hôm nay" và "Sắp tới"; hỗ trợ cuộn kéo chuột/cảm ứng (drag scrolling) và nút mũi tên.
3. **Design Tokens Applied:** `AppColors.primaryContainer`, `AppColors.outlineVariant`, `TextTheme.labelLarge`.
4. **Widgets & Components:** `Card`, `StatusChip`, nút chuyển ngày/tuần, nút "Seed sample data" có xác nhận hủy an toàn.
5. **Interactive States:** Ca học đã nộp hiển thị badge xanh lá `SUBMITTED`, ca chưa điểm danh hiển thị `NOT TAKEN`.
6. **Edge Cases & Error Handling:** Trống dữ liệu ca học $\rightarrow$ Nút khôi phục dữ liệu mẫu an toàn chỉ thêm dòng `SAMPLE-`, không ghi đè dữ liệu thật.

---

### 📱 SCR-10: Attendance Detail Marking (Màn hình trọng tâm)
1. **Screen Name & Route:** `AttendanceDetailPage` (`/attendance/:sessionId`), file: `lib/features/attendance/attendance_detail_page.dart`
2. **Layout & Responsive Behavior:** Tái cấu trúc kép theo breakpoint 700px (Commit `329a973`):
   - **Phone (< 700px):** Danh sách thẻ dọc từng sinh viên (`per-student roster cards`), các nút Present/Absent to bản dễ chạm ngón cái.
   - **Desktop ($\ge 700\text{px}$):** Bảng `DataTable` đầy đủ cột có tìm kiếm và phân trang.
3. **Design Tokens Applied:** `AppColors.errorContainer`, `AppColors.error`, `AppColors.green`, `CardTheme` viền `6px`.
4. **Widgets & Components:** `AttendanceCard`, `StatusChip`, ô tìm kiếm tên/mã sinh viên, nút "Mark All Present", "Save Draft", "Reset", và "Submit".
5. **Interactive States:** Trạng thái chuyển mượt giữa Present (xanh nhạt) và Absent (hồng cam); ô nhập ghi chú mở rộng trực tiếp trong thẻ; Dialog xác nhận sĩ số trước khi nộp.
6. **Edge Cases & Error Handling:** Chặn nộp trùng lặp `session_id` + `student_id`; mất mạng tự động lưu nháp cục bộ vào `shared_preferences`.

---

### 📱 SCR-07: FAP Sync & Export Center
1. **Screen Name & Route:** `ExportPage` (Route `/fap-sync`, nhãn menu: `Export`), file: `lib/features/export/export_page.dart`
2. **Layout & Responsive Behavior:** Bộ lọc lớp/ngày phía trên, bảng đối soát trạng thái phía dưới.
3. **Design Tokens Applied:** `AppColors.secondary`, `AppColors.surfaceContainer`, `TextTheme.bodyMedium`.
4. **Widgets & Components:** `FilterChip`, nút xuất CSV, nút nhập danh sách sinh viên bằng CSV/Excel, `StatusChip`.
5. **Interactive States:** Trạng thái tải file (Exporting/Importing); thông báo kết quả xuất file thành công.
6. **Edge Cases & Error Handling:** Gọi qua `FileService.saveTextFile`: Mở hộp thoại lưu tệp native trên Android, mở thư mục "Open Folder" trên Windows Desktop.

---

### 📱 SCR-08: AI Risk Assistant
1. **Screen Name & Route:** `AIAssistantPage` (`/ai-assistant`), file: `lib/features/ai_assistant/ai_assistant_page.dart`
2. **Layout & Responsive Behavior:** Danh sách sinh viên vượt ngưỡng cảnh báo (15%/20%) kèm khung soạn thảo email thông báo học vụ.
3. **Design Tokens Applied:** `AppColors.surfaceContainer`, `AppColors.primary`, `AppColors.error`.
4. **Widgets & Components:** Thẻ rủi ro sinh viên, khung xem trước email (`TextFormField`), nút kích hoạt gửi thông báo.
5. **Interactive States:** Loading khi phân tích luật chuyên cần; dialog xác nhận danh sách sinh viên nhận cảnh báo trước khi gửi.
6. **Edge Cases & Error Handling:** Tránh trùng lặp thông báo (deduplication) thông qua khóa sự kiện lưu trong `shared_preferences`; gửi qua endpoint Firebase Cloud Function.

---

## 2. Bảng ánh xạ Design Tokens $\rightarrow$ Flutter Theme (`lib/core/theme/app_theme.dart`)

| Design Token (Figma/Tailwind) | Hex / Quy chuẩn | Ánh xạ mã nguồn Flutter | Vai trò & Sử dụng thực tế |
| :--- | :---: | :--- | :--- |
| `primary` | `#005994` | `AppColors.primaryDark` / `ColorScheme.onPrimaryContainer` | Màu nhấn thương hiệu chính |
| `primary-container` | `#0072BC` | `AppColors.primary` / `ColorScheme.primary` | Nền nút bấm chính, dải nhận diện |
| `secondary` | `#35618D` | `AppColors.secondary` / `ColorScheme.secondary` | Tiêu đề phụ, nhãn thứ cấp |
| `tertiary-container` | `#BA4C00` | `AppColors.tertiary` | Màu cam nhận diện Đại học FPT |
| `surface` | `#F8F9FF` | `AppColors.surface` / `scaffoldBackgroundColor` | Nền tổng thể ứng dụng |
| `surface-container-low` | `#EFF4FF` | `AppColors.surfaceLow` | Nền thanh Breadcrumb, header |
| `surface-container-lowest`| `#FFFFFF`| `Colors.white` / `CardTheme.color` | Nền các thẻ Card nội dung |
| `on-surface` | `#0B1C30` | `AppColors.onSurface` | Màu chữ tiêu đề (Tương phản 15.2:1) |
| `on-surface-variant` | `#404751` | `AppColors.onSurfaceVariant` | Màu chữ phụ, caption |
| `outline-variant` | `#C0C7D3` | `AppColors.outlineVariant` | Đường viền thẻ Card, ô nhập liệu |
| `error` | `#D93025` / `#BA1A1A` | `AppColors.error` / `ColorScheme.error` | Trạng thái vắng mặt, cảnh báo rủi ro |
| `error-container` | `#FCE8E6` | `AppColors.errorContainer` | Nền chip cảnh báo/vắng mặt |
| `green` | `#6CB33F` | `AppColors.green` | Dải nhận diện ba màu, trạng thái Có mặt |
| `headline-lg` | 20px / Line 28px / w600 | `Theme.of(context).textTheme.headlineLarge` | Tiêu đề trang |
| `headline-md` | 16px / Line 24px / w600 | `Theme.of(context).textTheme.headlineMedium` | Tiêu đề Card |
| `body-md` | 14px / Line 20px / w400 | `Theme.of(context).textTheme.bodyMedium` | Chữ nội dung thông thường |
| `borderRadius.xl` | 6px | `BorderRadius.circular(6)` | Bo góc thống nhất toàn ứng dụng |

---

## 3. Bảng ánh xạ Components $\rightarrow$ Flutter Widgets (`lib/core/widgets/`)

| Master Component (Figma/Design) | Biến thể (Variants) | Flutter Widget tương ứng | Tệp mã nguồn |
| :--- | :--- | :--- | :--- |
| **Status Chip** | `Present`, `Absent`, `Warning`, `Neutral`; `WithIcon` | `StatusChip` | `lib/core/widgets/status_chip.dart` |
| **Navigation Bar** | Responsive: Desktop SideBar $\leftrightarrow$ Mobile BottomBar | `NavBar`, `MobileNavBar` | `lib/core/widgets/nav_bar.dart` |
| **Breadcrumb Bar** | Path: `FU - HCM > Academic Attendance Workbench` | `BreadcrumbBar` | `lib/core/widgets/breadcrumb_bar.dart` |
| **Top App Header** | Dải 3 màu cam/xanh/lá, User Avatar, Logout | `AppHeader` | `lib/core/widgets/app_header.dart` |
| **Responsive Shell** | Tự động hoán chuyển bố cục tại điểm gãy 700px | `AppShell` | `lib/core/widgets/app_shell.dart` |
| **Per-Student Roster Card**| `Present`, `Absent`, mở rộng ghi chú lý do | `AttendanceCard` | `lib/features/attendance/attendance_detail_page.dart` |

---

## 4. Kết quả đạt được & Định hướng tiếp theo

### ✅ Kết quả đạt được (Code-Confirmed)
1. **Hoạt động trơn tru trên Android Native (Commit `329a973`):** Giải quyết dứt điểm lỗi OAuth do Android đóng kết nối ngầm bằng cơ chế loopback + `AppLifecycleListener`; hỗ trợ chia sẻ tệp qua Mobile File Picker.
2. **Bố cục Responsive hai chiều:** Tối ưu hóa trải nghiệm di động với danh sách thẻ học viên thao tác 1 ngón tay, đồng thời giữ nguyên bảng rộng khi dùng trên màn hình lớn.
3. **Bảo toàn dữ liệu học vụ:** Tích hợp trực tiếp Google Sheets API v4 (3 sheets `students`, `schedule`, `attendance`), cơ chế lưu nháp ngoại tuyến và kiểm tra chống ghi đè trùng lặp.
4. **Phân tích rủi ro chuyên cần chính xác:** Động cơ Rule-based quét đúng hai ngưỡng cảnh báo 15% (nhắc nhở) và 20% (cấm thi).

### ⚠️ Định hướng phát triển tiếp theo
1. **Chuyển đổi hoàn toàn sang Firebase Firestore:** Thay thế hoàn toàn cơ chế lưu trùng lặp cục bộ `shared_preferences` bằng Firestore Database theo thiết kế kiến trúc tại `docs/firebase-email-notifications.md`.
2. **Điểm danh sinh viên bằng mã QR động:** Giảng viên phát mã QR trên màn hình điện thoại để sinh viên tự quét xác nhận vị trí trong phòng học.

---

## 5. Thông tin bàn giao dự án (Deliverables & Submission Links)
* **Kho lưu trữ GitHub:** [https://github.com/MinhCoffee/PRM5M.git](https://github.com/MinhCoffee/PRM5M.git)
* **Nhánh kiểm tra:** `main` (commit mới nhất: `d502843` & `329a973`)
* **Thư mục dự án:** `Lab2-AndroidApp/flutter_androidApp`
