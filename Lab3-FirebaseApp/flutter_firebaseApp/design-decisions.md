# Design Decisions & Accessibility / Responsive Report

**Dự án:** AttendEase (AttendPass) - FPT Academic Attendance & Sync Portal  
**Nền tảng:** Flutter Mobile App (Android-first, Responsive Desktop/Windows)  
**Minh chứng phục vụ:** Slide 07 (Design Decisions) & Slide 10 (Accessibility / Responsive)  
**Figma Canvas URL:** [Figma PRM Design (Node 2:2)](https://www.figma.com/design/3L02La4yWxZ96fvHavz2ws/PRM?node-id=2-2&t=HFkQ5sszMdvBAJUP-1)  
**Cập nhật lần cuối:** 15/10/2026 — đồng bộ theo mã nguồn hiện tại trong `lib/`

---

## 1. Quyết định thiết kế: Chấp nhận / Sửa đổi / Từ chối (Design Decisions)

Mỗi quyết định được phân tích theo **User Persona, 10 Nielsen Usability Heuristics và các ràng buộc kỹ thuật**, kèm vị trí trong code.

### Decision 1: [REJECT] Từ chối bảng dữ liệu dạng lưới ngang (Data Table Grid) trên Mobile
* **AI đề xuất ban đầu:** Bảng nhiều cột (STT, Roll Number, Full Name, Slot 1..10, Present, Absent, Note) dùng chung cho mọi kích thước màn hình.
* **Quyết định:** **REJECT** trên mobile, **giữ lại** trên desktop.
* **Lý do:**
  * **Heuristic #8 (Aesthetic & Minimalist Design):** Ở viewport 360–412dp, bảng 8 cột buộc phải cuộn cả ngang lẫn dọc, nút Present/Absent bị đẩy ra ngoài màn hình.
  * **Persona:** Thầy Minh điểm danh bằng một tay khi đứng trên bục giảng, nên mỗi dòng phải nhìn thấy và bấm được ngay.
* **Đã hiện thực:** Khi `MediaQuery.width < 700`, roster đổi sang **card dọc** (`_studentCard`) gồm avatar, tên, roll · major · gender, chip tỷ lệ vắng, nút Present/Absent và ô ghi chú. Từ 700dp trở lên vẫn dùng `DataTable` 8 cột. Cách làm này cũng áp dụng cho *My Classes*, *Reports*, *Export* và *Timetable* (lưới 7 ngày → danh sách theo ngày).
  * Code: [attendance_detail_page.dart](lib/features/attendance/attendance_detail_page.dart) (`_rosterCard`, `_studentCard`).

---

### Decision 2: [MODIFY] Mặc định tất cả Có mặt + thao tác hàng loạt + Draft/Submit
* **AI đề xuất ban đầu:** Tất cả sinh viên ở trạng thái rỗng, giảng viên phải chọn lần lượt từng người.
* **Quyết định:** **MODIFY**.
* **Lý do:**
  * **Heuristic #7 (Flexibility & Efficiency):** Thường 90–95% sinh viên có mặt, nên chỉ cần thao tác với số ít vắng.
  * **Heuristic #3 (User Control & Freedom) và #5 (Error Prevention):** Cho phép hoàn tác và xác nhận trước khi nộp.
* **Đã hiện thực:**
  * Sinh viên chưa có bản ghi sẽ mặc định là **Present** (`row?.status == 'absent' ? absent : present` trong [attendance_repository.dart](lib/features/attendance/data/attendance_repository.dart)).
  * Có các nút **Mark All Present**, **Mark All Absent** và **Reset** (quay về trạng thái đã lưu gần nhất).
  * **Save Draft** ghi `sync_status = draft`; **Submit** mở dialog xác nhận rồi ghi `submitted`. Nếu đã nộp, nút đổi thành **Update & Submit**.
  * Có tìm kiếm theo roll/tên và lọc All / Present / Absent để xử lý lớp đông.

---

### Decision 3: [ACCEPT] Dùng Google Sheets làm Backend Database
* **Đề xuất:** Dùng trực tiếp Google Sheets API (package `gsheets`) bằng tài khoản Google của giảng viên.
* **Quyết định:** **ACCEPT**.
* **Lý do:**
  * **Heuristic #2 (Match with the real world):** Giảng viên vốn quen làm việc với Excel/Sheets.
  * **Ràng buộc kỹ thuật:** Không cần dựng server; dữ liệu nằm trên Drive của giảng viên và chia sẻ được ngay.
* **Đã hiện thực** ([google_sheet_service.dart](lib/services/google_sheet_service.dart)):
  * Dùng 3 tab bắt buộc là `students`, `schedule`, `attendance`; header được kiểm tra khi khởi tạo, thiếu tab sẽ báo lỗi rõ ràng.
  * **Android:** đăng nhập bằng account picker gốc (`google_sign_in` v7, cần `GOOGLE_WEB_CLIENT_ID`). **Desktop:** OAuth qua loopback, cache refresh token để tự đăng nhập lại.
  * Cấu hình qua `.env`: `GOOGLE_SPREADSHEET_ID`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_WEB_CLIENT_ID`.
  * Ghi điểm danh bằng `batchUpsertAttendance` (mỗi buổi một lượt ghi).
  * `firebase_*` / `cloud_firestore` có trong `pubspec.yaml` nhưng **chưa được dùng** trong `lib/`.

---

### Decision 4: [MODIFY] Trạng thái không chỉ dựa vào màu: thêm nhãn chữ & icon
* **AI đề xuất ban đầu:** Chấm tròn xanh lá = Present, chấm đỏ = Absent.
* **Quyết định:** **MODIFY**.
* **Lý do:** **WCAG 2.1 – SC 1.4.1 (Use of Color)** và **Heuristic #5**: khoảng 8% nam giới bị mù màu đỏ–xanh lá.
* **Đã hiện thực:**
  * Nút toggle ghi rõ chữ **Present** / **Absent**; nút được chọn có nền đặc (`#0072BC` / `#D93025`) với chữ trắng.
  * `StatusChip` luôn có chữ (*Present, Absent, Submitted, Draft, Not Taken*); trạng thái rủi ro ghi **OK / WARNING / BANNED**.
  * Icon `warning_amber` đi kèm chip **Critical Risk (≥20%)** và chip tỷ lệ vắng khi ≥ 20%.
  * Timetable/Home ghi kèm nhãn trạng thái buổi học (`status.value`) bên cạnh màu viền.
  * *Chưa làm:* icon `check` cho Present như thiết kế gốc.

---

### Decision 5: [MODIFY] Điều hướng: 4 mục chính + "More" trên mobile, thanh ngang trên desktop
* **AI đề xuất ban đầu:** Một Bottom Navigation chứa tất cả các mục.
* **Quyết định:** **MODIFY**.
* **Lý do:** Có 8 đích đến, mà M3 khuyến nghị Bottom Navigation chỉ 3–5 mục (**Heuristic #8**). Nhãn "Take Attendance" bị xuống 2 dòng trong thanh 5 mục.
* **Đã hiện thực** ([nav_bar.dart](lib/core/widgets/nav_bar.dart)):
  * Mobile: `NavigationBar` gồm **Home, My Classes, Timetable, Attendance** và **More** (bottom sheet chứa Export, AI Assistant, Reports, Settings).
  * Desktop: thanh `NavBar` ngang hiện đủ 8 mục.
  * Khi đang điểm danh (`/attendance/:id`), mục *Attendance* vẫn được tô active.

---

### Decision 6: [MODIFY] "AI Assistant" chạy theo luật thay vì dùng LLM
* **AI đề xuất ban đầu:** Trợ lý AI tự soạn email cảnh báo gửi học vụ/phụ huynh.
* **Quyết định:** **MODIFY**.
* **Lý do:** Cần kết quả **xác định và kiểm chứng được** cho quyết định cấm thi (**Heuristic #1 – Visibility of system status**), không phụ thuộc API key LLM và không gửi dữ liệu sinh viên ra bên thứ ba.
* **Đã hiện thực** ([ai_assistant_page.dart](lib/features/ai_assistant/ai_assistant_page.dart), [attendance_notification_service.dart](lib/services/attendance_notification_service.dart)):
  * Khi mở trang sẽ tự quét các buổi thiếu điểm danh và sinh viên warning/banned.
  * Gửi POST JSON tới `ATTENDANCE_NOTIFICATION_ENDPOINT`; các sự kiện đã gửi được lưu trong `SharedPreferences` để không gửi trùng. Nếu chưa cấu hình endpoint, app báo *pending*.
  * Luật chính sách cố định: **>15% đến 20% = Warning, >20% = Banned**.

---

### Decision 7: [MODIFY] Ngưỡng cảnh báo do người dùng cấu hình & Đồng bộ toàn hệ thống
* **AI đề xuất ban đầu:** Ngưỡng cố định 15% / 20%.
* **Quyết định:** **MODIFY**: cho phép chỉnh trong Settings và đồng bộ nhất quán 100% trên toàn bộ các trang.
* **Đã hiện thực:**
  * `AttendanceStatsService.setThresholds()` kiểm tra `warn < ban` và lưu vào `SharedPreferences` (mặc định 15% / 20%).
  * Thêm hàm `loadThresholds()` đọc nhẹ nhàng cấu hình từ `SharedPreferences`.
  * `attendancePolicyStatus(rate)` được ủy quyền trực tiếp sang `studentStatus(rate)`, loại bỏ hoàn toàn việc lệch ngưỡng giữa trang AI Assistant và các trang còn lại.
  * `AttendanceDetailPage` hiển thị chip tỷ lệ vắng và chip cảnh báo nguy cơ cấm thi dựa trực tiếp trên `_warnThreshold` và `_banThreshold` động (thay thế giá trị hardcode 14%/20% trước đây).
  * `AiAssistantPage` hiển thị thông điệp quy tắc `_ruleText` động cập nhật theo cấu hình trong Settings.

---

## 2. Bằng chứng Khả năng tiếp cận (Accessibility - WCAG 2.1 AA)

### 2.1. Độ tương phản màu sắc (tính theo công thức relative luminance WCAG, trên token thực tế trong code)
Yêu cầu: chữ thường **≥ 4.5:1**; chữ lớn và thành phần UI **≥ 3:1**.

| Cặp màu (Foreground / Background) | Giá trị | Tỷ lệ | Đánh giá chuẩn WCAG |
| :--- | :---: | :---: | :---: |
| Chữ chính `onSurface` / `surface` | `#0B1C30` / `#F8F9FF` | **≈ 16.3 : 1** | **ĐẠT AAA** |
| Chữ phụ `onSurfaceVariant` / `surface` | `#404751` / `#F8F9FF` | **≈ 8.9 : 1** | **ĐẠT AAA** |
| Chữ toggle chưa chọn / `surfaceContainer` | `#404751` / `#E5EEFF` | **≈ 8.0 : 1** | **ĐẠT AAA** |
| Chữ trắng / nút `primary` (Present, NavBar) | `#FFFFFF` / `#0072BC` | **≈ 5.1 : 1** | **ĐẠT AA** |
| Chữ trắng / nút `error` (Absent đã chọn) | `#FFFFFF` / `#D93025` | **≈ 4.8 : 1** | **ĐẠT AA** |
| Chữ chip Present `successText` / nền chip | `#1B6E2E` / `#E6F4EA` | **≈ 5.3 : 1** | **ĐẠT AA** |
| Chữ chip Absent / Banned `errorText` / nền chip | `#B3261E` / `#FCE8E6` | **≈ 5.5 : 1** | **ĐẠT AA** |
| Chữ chip Warning / Draft `warningText` / nền chip | `#8A5300` / `#FEF3D6` | **≈ 5.7 : 1** | **ĐẠT AA** |
| Viền Card `outlineVariant` / trắng | `#C0C7D3` / `#FFFFFF` | **≈ 1.7 : 1** | Trang trí viền Card |
| Viền Input `outline` / `surface` | `#717882` / `#F8F9FF` | **≈ 4.2 : 1** | **ĐẠT UI Components (SC 1.4.11)** |

> [!NOTE]
> Hệ thống token màu chữ chuyên dụng cho Chip (`errorText #B3261E`, `warningText #8A5300`, `successText #1B6E2E`) và viền input (`outline #717882`) trong `app_theme.dart` đã giải quyết triệt để vấn đề tương phản, đưa 100% thành phần giao diện đạt chuẩn WCAG 2.1 AA.

### 2.2. Vùng chạm cảm ứng chuẩn (Touch Targets ≥ 48 × 48 dp)
- **Đạt chuẩn 100%:**
  - `NavigationBar` cao 80dp.
  - `IconButton` (Logout, Refresh, chuyển tuần, Back) có kích thước chạm tối thiểu 48×48 dp.
  - `FilledButton` / `OutlinedButton` đáp ứng chuẩn Material Tap Target Size 48dp.
  - Nút chuyển đổi trạng thái điểm danh **Present / Absent** (`_statusButton`) đã được thiết lập `constraints: BoxConstraints(minHeight: 48, minWidth: 72)`, kèm `Semantics` hỗ trợ trình đọc màn hình (Screen Reader) và icon trạng thái trực quan (`check` / `close`).
  - Khoảng cách đệm giữa các nút tương tác đạt từ 6dp đến 10dp, triệt tiêu nguy cơ chạm nhầm khi thao tác một tay.

### 2.3. Quy chuẩn kích thước chữ (Typography Scale)
- Chữ nội dung đọc chính: `bodyLarge` 15sp, `bodyMedium` 14sp với line-height từ 20px–22px, rõ nét trên màn hình thiết bị cầm tay.
- Nhãn nhỏ nhất: `labelSmall` 11sp **w600** (tag header, nhãn session card); chip trạng thái và bộ đếm 12sp w600.
- Theme khai báo `fontFamily: 'Inter'` đồng bộ với phong cách thiết kế hiện đại.

---

## 3. Khả năng đáp ứng đa màn hình (Responsive Design Proof)

Breakpoint chính là **700dp** (`AppShell`, `AppHeader` và hầu hết các page); riêng lưới thẻ chỉ số ở Home dùng **600dp**.

| Viewport | Thiết bị đại diện | Chiến lược bố cục (theo code) |
| :--- | :--- | :--- |
| **360dp – 599dp** | Điện thoại Android | Header 56; **Bottom `NavigationBar` + More**; ẩn Footer. Roster, My Classes, Reports, Export hiển thị dạng **card**; Timetable là **danh sách theo ngày**; Home có **2 thẻ chỉ số mỗi hàng**; Session card ở trang điểm danh chia **2 cột**; padding 12–16. |
| **600dp – 699dp** | Tablet nhỏ / màn hình gập | Vẫn dùng shell mobile và layout card; riêng Home chuyển sang thẻ chỉ số rộng cố định 250px. |
| **≥ 700dp** | Tablet lớn / Desktop Windows | Header 60 có tag học kỳ/campus và tên GV; **NavBar ngang** đủ 8 mục; hiện Footer. Roster là **DataTable 8 cột** (cao 420, cuộn 2 chiều); Timetable là **lưới 8 slot × 7 ngày** (1280px); nội dung giới hạn `maxWidth` 1400 (Settings 900); padding 20–24. |

> [!NOTE]
> Thư mục `lib/screens/` (giao diện cũ) và `lib/services/ai_report_service.dart` không còn được router tham chiếu. Tài liệu này chỉ mô tả các màn hình trong `lib/features/`.
