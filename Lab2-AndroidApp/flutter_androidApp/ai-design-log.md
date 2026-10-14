# AI Iterations, Critique & Mobile UX Refinement Log

**Dự án:** AttendEase (AttendPass) - FPT Academic Attendance & Sync Portal (PRM393 Lab 2)  
**Minh chứng phục vụ:** Slide 05 & Slide 06 (AI Iterations & Critique)  
**Figma Canvas URL:** [Figma PRM Design (Node 2:2)](https://www.figma.com/design/3L02La4yWxZ96fvHavz2ws/PRM?node-id=2-2&t=HFkQ5sszMdvBAJUP-1)  
**Bằng chứng đối chiếu:** Commit `4ca954b` (Design alignment), Commit `329a973` (Android adaptation), và các tệp trong `design/`

---

## 1. Ba lần tinh chỉnh AI với mục tiêu KHÁC NHAU (3 Distinct AI Iterations)

### 🔄 Iteration 1: Thích ứng di động & Tái cấu trúc danh sách điểm danh (Mobile Adaptation & Card Roster)
* **Mục tiêu:** Chuyển đổi toàn diện trải nghiệm từ màn hình Desktop/Web (bảng ngang nhiều cột) sang màn hình di động Android (360dp – 412dp) có thể thao tác bằng một ngón tay cái.
* **Vấn đề thực tế ban đầu (Before):**
  - Giao diện Stitch ban đầu và bản Lab 1 Desktop hiển thị bảng danh sách sinh viên dưới dạng `DataTable` ngang rộng 1280px.
  - Trên màn hình Android, giảng viên buộc phải cuộn ngang liên tục để tìm cột đánh dấu Có mặt/Vắng mặt; các nút thao tác quá nhỏ ($< 28\text{dp}$) gây bấm nhầm nghiêm trọng.
* **Giải pháp tinh chỉnh thực tế (After - Commit `329a973`):**
  - Viết lại `attendance_detail_page.dart` (thêm 276 dòng code mới) hỗ trợ bố cục kép theo breakpoint `< 700px`:
    - **Trên Phone (< 700px):** Chuyển sang danh sách thẻ học viên độc lập (`per-student roster cards`), mỗi thẻ gồm avatar, mã sinh viên, họ tên và hai nút bấm Present/Absent to bản ($\ge 48\text{dp}$).
    - Ô nhập ghi chú lý do vắng tự động co giãn ngay trong thẻ thay vì nằm ở cột xa bên phải.

---

### 🔄 Iteration 2: Khả năng tiếp cận, Loại bỏ UI giả mạo & Tối ưu luồng tương tác (Integrity & Accessibility)
* **Mục tiêu:** Loại bỏ các thành phần UI gây nhiễu, làm sạch dữ liệu hiển thị và nâng cao tính minh bạch trạng thái theo chuẩn WCAG 2.1 AA.
* **Vấn đề thực tế ban đầu (Before):**
  - Trên màn hình điểm danh có 2 nút điều hướng cứng `"Previous Class"` / `"Next Class"` không có dữ liệu thực, dễ khiến giảng viên bấm nhầm làm mất dữ liệu đang chấm dở.
  - Tồn tại dòng chữ giả lập `"Draft auto-saved"` dù hệ thống chưa hề lưu dữ liệu vào bộ nhớ.
  - Tỷ lệ tương phản chữ trên nền cũ chưa đạt chuẩn tiếp cận cho người khiếm thị màu sắc.
* **Giải pháp tinh chỉnh thực tế (After - Commit `329a973` & `4ca954b`):**
  - Xóa bỏ hoàn toàn 2 nút Previous/Next giả mạo; xóa dòng chữ tự động lưu nháp ảo.
  - Tích hợp nút **"Save Draft"** thật sự và nút **"Reset"** trạng thái ban đầu có dialog cảnh báo.
  - Bổ sung `StatusChip` đa thành tố: Màu nền nhạt + Viền tương phản + Biểu tượng cảnh báo + Chữ viết hoa (`PRESENT`, `ABSENT`), tương phản chữ đạt **15.2:1**.

---

### 🔄 Iteration 3: Tối ưu nền tảng Android Native & Cơ chế phục hồi lỗi (Native Platform & Offline Recovery)
* **Mục tiêu:** Giải quyết các rào cản đặc thù của hệ điều hành Android (Background network throttling, Mobile File Sharing, Quản lý vòng đời ứng dụng).
* **Vấn đề thực tế ban đầu (Before):**
  - Quy trình Google OAuth tiêu chuẩn mở Chrome làm app bị đẩy xuống nền (background); Android lập tức đóng socket khiến việc trao đổi token OAuth bị lỗi `"Failed host lookup oauth2.googleapis.com"`.
  - Nút xuất file báo cáo gọi hàm mở thư mục `"Open Folder"`, lệnh này chỉ chạy trên Windows và gây crash trên Android.
* **Giải pháp tinh chỉnh thực tế (After - Commit `329a973`):**
  - Tái cấu trúc hàm `_requestMobileUserClient` trong `google_sheet_service.dart`: nhận mã ủy quyền qua loopback server cục bộ, tích hợp `AppLifecycleListener` để đợi app trở lại foreground trước khi thực hiện trao đổi token PKCE.
  - Viết lại `FileService.saveTextFile`: sử dụng Android File Picker chuẩn di động để giảng viên lưu hoặc chia sẻ file CSV qua Zalo/Drive mà không phụ thuộc vào hệ thống tệp Windows.

---

## 2. Nhật ký phát hiện & Khắc phục $\ge 5$ vấn đề UX cụ thể trên màn hình thực tế

| STT | Màn hình cụ thể | Vấn đề UX phát hiện (Critique) | Bằng chứng mã nguồn & Commit | Giải pháp thiết kế khắc phục |
| :---: | :--- | :--- | :--- | :--- |
| **01** | `SCR-10: Attendance Detail` | Bảng điểm danh ngang bị tràn màn hình điện thoại | Commit `329a973` tại `attendance_detail_page.dart` | Thay bằng danh sách thẻ dọc `per-student roster cards`, thao tác 1 ngón tay cái. |
| **02** | `SCR-10: Attendance Detail` | Nút Previous/Next và nhãn "Draft auto-saved" ảo | Commit `329a973` | Gỡ bỏ triệt để các phần tử giả mạo; thay bằng nút Save Draft và Reset có xác nhận thật. |
| **03** | `SCR-01: Login Screen` | Đăng nhập Google bị văng lỗi mạng khi chuyển sang Chrome | Commit `329a973` tại `google_sheet_service.dart` | Cơ chế loopback server + chờ `AppLifecycleListener` resume app rồi mới trao đổi token. |
| **04** | `SCR-02: Dashboard` | Thẻ thống kê 4 cột bị co rúm, chữ tràn ra ngoài trên mobile | Commit `329a973` tại `home_page.dart` | Bố cục lại thành thẻ thống kê 2 cột (two-column stat cards) có Safe Area header. |
| **05** | `SCR-07: FAP Sync / Export`| Nút "Open Folder" gây lỗi trên Android | Commit `329a973` tại `file_service.dart` | Chỉ hiện "Open Folder" trên Windows; trên Android hiển thị Mobile File Picker để lưu/chia sẻ. |
| **06** | `SCR-08: AI Assistant` | Nhầm lẫn AI Assistant là Chatbot tự do vô hướng | Commit `4ca954b` và `1f665cc` | Định vị rõ: AI Assistant là **Rule-based Risk Engine** phân tích ngưỡng vắng 15%/20% và trigger email qua Cloud Function. |

---

## 3. Bảng đối chiếu Before (Stitch Mockup / Desktop) vs After (Android App)

| Đặc điểm UX | Bản gốc Stitch / Desktop (Before) | Bản hoàn thiện trên Android (After) |
| :--- | :--- | :--- |
| **Bố cục điểm danh** | Bảng `DataTable` 1280px, cuộn ngang phức tạp | Thẻ sinh viên dọc (`AttendanceCard`), vừa vặn 360–412dp |
| **Vùng bấm trạng thái** | Checkbox nhỏ 20px, dễ bấm nhầm | Nút bấm lớn $\ge 48\times 48\text{ dp}$, phân định màu + icon |
| **Đăng nhập Google** | Mở trình duyệt ngoài, dễ crash socket nền | Loopback server + `AppLifecycleListener` foreground sync |
| **Xuất file báo cáo** | Mở thư mục Windows Explorer | Hộp thoại chọn vị trí lưu tệp Android File Picker |
| **Hiển thị thống kê** | 4 thẻ dàn hàng ngang | Lưới 2 cột thích ứng màn hình hẹp kèm padding an toàn |
| **Độ chân thực dữ liệu**| Chứa nút giả (Prev/Next) và chữ auto-save ảo | 100% dữ liệu thực liên kết Google Sheets API v4 |
