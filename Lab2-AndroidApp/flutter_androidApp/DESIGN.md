# AI UI Generation & Design Specification

**Dự án:** AttendEase (AttendPass) - FPT Academic Attendance & Sync Portal  
**Nền tảng:** Flutter Mobile App (Android-first, Responsive Desktop)  
**Minh chứng phục vụ:** Slide 05 (AI UI Generation)  
**Figma Canvas URL:** [Figma PRM Design (Node 2:2)](https://www.figma.com/design/3L02La4yWxZ96fvHavz2ws/PRM?node-id=2-2&t=HFkQ5sszMdvBAJUP-1)

---

## 1. Prompt nguyên văn dùng để sinh giao diện AI (Original Prompt)

Để tạo ra bộ thiết kế ban đầu (Initial Stitch / AI UI Generations) tại thư mục `design/` và khớp với wireframe Figma Frame `2:2`, câu lệnh prompt được xây dựng với đầy đủ các thành tố: **Persona, Nhiệm vụ (Task), Nền tảng (Platform), Ràng buộc (Constraints) và Phong cách thẩm mỹ (Visual Style)**:

```text
Act as a Senior UI/UX Designer and Mobile Design System Architect.

1. Target Persona:
University Lecturer (Mr. Minh, 38 years old, Software Engineering faculty at FPT University). He needs to take classroom attendance rapidly within 60 seconds at the start of a 90-minute lecture slot using a smartphone with one-handed operation.

2. Core Task & Screen Scope:
Design a production-grade, enterprise mobile screen for "AttendEase: FPT Academic Attendance & Sync Portal" for Android (viewport width 360dp - 412dp), specifically:
- Lecturer Dashboard with daily slot summary and student risk alerts.
- Quick Attendance Marking screen with responsive student roster card layout.
- Attendance Report & AI Risk Assistant with email notification integration.

3. Platform & Technical Constraints:
- Mobile-first Android design (target touch target minimum 48x48 dp for all primary interactive elements).
- Material Design 3 guidelines with Bottom Navigation and clear status badges.
- Avoid desktop data-grids on mobile: render student rosters as clean vertical cards with instant status toggles (Present / Absent) and note expansion.
- Must include clear feedback states: Default, Loading skeleton, Error/Offline banner, and Empty states.
- High accessibility (WCAG 2.1 AA): Contrast ratio >= 4.5:1, do not rely on color alone (pair colors with clear typography badges and icons for color-blind accessibility).

4. Visual Style & Brand Aesthetics:
- Professional Institutional EdTech aesthetic reflecting FPT University identity.
- Primary colors: Deep Academic Navy (#005994) and Portal Cyan (#0072BC).
- Accent/Brand colors: FPT Heritage Orange (#BA4C00 / #F36F21) and Green (#6CB33F).
- Background: Soft modern tinted surface (#F8F9FF) with crisp white card containers (#FFFFFF) and subtle 1px border (#C0C7D3).
- Clean Inter typography hierarchy with defined scale (headline-lg, headline-md, body-md, label-lg).
- Output: Clean Tailwind CSS markup with exact semantic design tokens and corresponding component structure.
```

---

## 2. Kết quả AI UI Generation & Đối chiếu 11 khung màn hình Figma (Node 2:2)

Dựa trên wireframe chuẩn trên Figma `node-id=2-2` và thư mục `design/`, hệ thống bao gồm đầy đủ **11 khung màn hình & thành phần UX**:

1. **`SCR-01: Login Screen`** (`design/attendease_login/`):
   - Màn hình đăng nhập tối ưu cho mobile, gồm dải màu nhận diện ba màu (Cam - Xanh dương - Xanh lá), thông báo học kỳ Fall 2026 đang hoạt động, bộ chọn cơ sở (Campus selector: HCM, HN, DN, CT, QN) và form xác thực Google Single Sign-On (SSO).
2. **`SCR-02: Lecturer Dashboard`** (`design/attendease_lecturer_dashboard/`):
   - Bảng điều khiển gồm thanh chào giảng viên, 4 chỉ số nhanh (Slots hoàn thành, tỷ lệ có mặt trung bình 92.4%, 3 sinh viên nguy cơ cấm thi, số bản nháp), và danh sách ca học hôm nay (Today's Schedule).
3. **`SCR-03: Weekly Timetable`** (`design/attendease_weekly_timetable/`):
   - Lịch tuần trực quan theo ma trận các Slot học (Slot 1 đến Slot 6) và các thứ trong tuần (Thứ 2 đến Chủ nhật) kèm phòng học và trạng thái ca học.
4. **`SCR-04: My Courses / Session Browser`** (`design/attendease_take_attendance_browse/`):
   - Danh sách các lớp học phần và ca học được phân công giảng dạy, hiển thị tiến độ buổi học và số buổi vắng tối đa cho phép.
5. **`SCR-05: Take Attendance Session Selector`** (`design/attendease_take_attendance_browse/`):
   - Bộ lọc ca học theo ngày (Today, Tomorrow, Pick Date), phân loại trạng thái ca học (Chưa điểm danh `NOT TAKEN`, Đang mở, Đã nộp `SUBMITTED`).
6. **`SCR-06: Attendance Detail & Marking Roster`** (`design/attendease_attendance_detail_marking/`):
   - Danh sách sinh viên theo dạng thẻ hàng dọc (List Cards), mỗi thẻ gồm ảnh đại diện, họ tên, mã số sinh viên (Roll number), nút chuyển nhanh Có mặt/Vắng mặt to bản dễ bấm ngón tay cái ($\ge 48\times 48\text{dp}$), và ô ghi chú lý do vắng.
7. **`SCR-07: FAP Sync & Export Center`** (`design/attendease_fap_sync_center/`):
   - Trạng thái đồng bộ thời gian thực với cổng FAP, nút xuất báo cáo CSV/Excel và đối soát dữ liệu điểm danh.
8. **`SCR-08: AI Risk Assistant`** (`design/attendease_ai_assistant/`):
   - Giao diện trợ lý phân tích rủi ro chuyên cần, tự động phát hiện sinh viên chạm ngưỡng 15%/20% và soạn thảo email cảnh báo gửi học vụ/phụ huynh.
9. **`SCR-09: Attendance Reports & Analytics`** (`design/attendease_attendance_report/`):
   - Biểu đồ phân bố chuyên cần theo học kỳ/môn học và bảng phân tích sinh viên vượt ngưỡng cảnh báo vắng.
10. **`SCR-10: Supporting UX States`** (`design/academic_utility_portal/`):
    - Hệ thống các trạng thái giao diện hỗ trợ: **Skeleton Loading** (tải dữ liệu), **Empty State** (ngày không có lịch), **Offline/Error Banner** (mất kết nối mạng kèm nút thử lại), và **Modal Dialogs** (xác nhận nộp điểm danh, xác nhận đăng xuất).
11. **`SCR-11: Settings`** (`design/attendease_settings/`):
    - Quản lý cấu hình hệ thống: ngưỡng cảnh báo vắng (15% nhắc nhở, 20% cấm thi), tần suất đồng bộ tự động, lựa chọn campus mặc định và thông tin tài khoản giảng viên.

---

## 3. Nguyên tắc thiết kế cốt lõi (Design Principles)

1. **Mobile-First & Thumb-Friendly:** Các nút bấm thao tác nhiều nhất (Present, Absent, Submit) đặt ở nửa dưới màn hình để giảng viên dễ thao tác bằng 1 tay khi đang cầm điện thoại đứng trên bục giảng.
2. **Instant Status Feedback:** Đổi trạng thái tức thì không cần chờ mạng; sử dụng hiệu ứng viền và màu nền nhẹ nhàng, không gây chói mắt.
3. **No Dead Ends (Không ngõ cụt):** Luôn có nút quay lại (Back navigation), nút thoát khỏi modal và tùy chọn thử lại (Retry) khi phát sinh lỗi.
