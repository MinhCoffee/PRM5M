# Luồng Hoạt Động Của Ứng Dụng (Function Flow)

Tài liệu này mô tả luồng hoạt động chi tiết của các tính năng và hàm (function) chính trong hệ thống điểm danh FAP Attendance.

## 1. Luồng Khởi động và Đăng nhập (Authentication Flow)
- **Tệp liên quan:** `main.dart`, `login_page.dart`, `google_sheet_service.dart`
- **Quy trình:**
  1. Ứng dụng khởi động, load cấu hình môi trường từ `.env` (client ID, spread sheet ID, endpoint).
  2. Tại `LoginPage`, người dùng (giảng viên) thực hiện đăng nhập thông qua Google OAuth.
  3. `GoogleSheetService.signIn()` được gọi. Quá trình xác thực mở trình duyệt web (Desktop OAuth) hoặc tận dụng Refresh Token có sẵn trong thư mục cục bộ.
  4. Nếu xác thực thành công, điều hướng (navigate) sang trang chủ `/home`.

## 2. Luồng Nạp và Phân Tích Dữ Liệu (Data Initialization Flow)
- **Tệp liên quan:** `attendance_stats_service.dart`, `google_sheet_service.dart`
- **Quy trình:**
  1. Khi vào giao diện chính (`AppShell`), `AttendanceStatsService.load()` được gọi để nạp dữ liệu.
  2. Tải toàn bộ cấu trúc từ Google Sheets:
     - Tải danh sách buổi học (sessions) từ sheet `schedule`.
     - Tải danh sách sinh viên từ sheet `students`.
     - Tải các bản ghi điểm danh hiện có từ sheet `attendance`.
  3. Dữ liệu sau khi nạp được phân tích để tính toán: 
     - Lớp học nào trong ngày.
     - Sinh viên nào đang trong mức cảnh báo vắng mặt (Warning: >15%) hoặc bị cấm thi (Banned: >20%).

## 3. Luồng Điểm Danh (Take Attendance Flow)
- **Tệp liên quan:** `attendance_browse_page.dart`, `attendance_detail_page.dart`
- **Quy trình:**
  1. Tại màn hình danh sách lớp (`AttendanceBrowsePage`), giảng viên chọn một buổi học (session).
  2. Điều hướng vào màn hình chi tiết (`AttendanceDetailPage`). Hệ thống lọc sinh viên thuộc lớp (`class_code`) tương ứng.
  3. Giảng viên thao tác đánh dấu Present (Có mặt) hoặc Absent (Vắng mặt) và thêm ghi chú nếu cần.
  4. **Lưu nháp (Draft):** Có thể lưu cục bộ trạng thái hiện tại mà chưa cần đẩy lên server.
  5. **Nộp (Submit):** `AttendanceRepository.submit()` sẽ đẩy dữ liệu lên Google Sheets sheet `attendance`, đảm bảo không trùng lặp cặp khóa `session_id` + `student_id`. Cập nhật trạng thái thành `submitted`.

## 4. Luồng Báo Cáo và AI Assistant (Reporting & AI Flow)
- **Tệp liên quan:** `reports_page.dart`, `ai_assistant_page.dart`, `attendance_notification_service.dart`
- **Quy trình Báo Cáo:**
  1. Giảng viên mở tab Reports. Ứng dụng kết xuất biểu đồ/bảng Data Table tỷ lệ vắng mặt dựa theo các bộ lọc (Kỳ học, Môn học, Lớp).
  2. Tính năng Export: Dùng package ghi file để tạo và lưu file `.csv` chứa số liệu báo cáo, sau đó lưu vào bộ nhớ thiết bị.
- **Quy trình AI Assistant:**
  1. Nhấn nút quét dữ liệu, AI tính toán lịch sử vắng mặt dựa trên luật (rule-based).
  2. Quét các session đã quá giờ nhưng chưa điểm danh.
  3. Quét các học sinh đạt mức Warning / Banned.
  4. Hệ thống gọi `AttendanceNotificationService.dispatch()` gửi dữ liệu lên Firebase Cloud Function / Backend thông qua `ATTENDANCE_NOTIFICATION_ENDPOINT` để tự động gửi email cảnh báo tự động cho sinh viên.

## 5. Luồng Đồng bộ Dữ liệu (FAP Sync / Export Flow)
- **Tệp liên quan:** `export_page.dart`, `file_service.dart`
- **Quy trình:**
  1. **Import (Nhập dữ liệu):** Cho phép giảng viên Import file CSV hoặc Excel chứa danh sách lớp.
  2. `FileService` sẽ đọc nội dung file, chuẩn hóa và gọi `GoogleSheetService.appendStudents()` để chèn vào sheet `students`.
  3. **Export (Xuất dữ liệu điểm danh):** Xuất toàn bộ dữ liệu điểm danh FAP thành file CSV chuẩn, lưu xuống thư mục Local của hệ điều hành phục vụ việc đồng bộ thủ công vào FAP nội bộ trường.
