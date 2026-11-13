# UX Research: Problem Statement & User Persona

**Dự án:** AttendEase - FPT Academic Attendance & Sync Portal (PRM393 - Lab 2 Android App)  
**Nhóm phát triển:**
- **Hồ Minh** (MinhCoffee) - Project Architecture, Git & Flutter System Alignment
- **Lâm Thiên Hải Anh** - Android Native Adaptation, Responsive Layouts & OAuth PKCE Loopback
**Kho mã nguồn:** [https://github.com/MinhCoffee/PRM5M.git](https://github.com/MinhCoffee/PRM5M.git)  
**Minh chứng phục vụ:** Slide 01 (Project Overview) & Slide 02 (Problem & Persona)

---

## 1. Bối cảnh dự án & Vấn đề thực tế (Context & Reality)
* **Bối cảnh môn học:** Đồ án Lab 2 (PRM393), chuyển đổi và tối ưu hóa hệ thống điểm danh từ ứng dụng Desktop Windows (Lab 1) sang ứng dụng di động **Android Native** phục vụ giảng viên Đại học FPT TP.HCM.
* **Thực tế giảng dạy:** Giảng viên phụ trách 3–5 lớp học phần (mỗi lớp 25–35 sinh viên), giảng dạy 4–6 slot/ngày. Quy chế học vụ bắt buộc điểm danh trong 15–20 phút đầu giờ học.
* **Bất cập thực tế:**
  1. Cổng FAP web trường thường xuyên nghẽn mạng vào các khung giờ bắt đầu ca học.
  2. Mang laptop lên giảng đường hoặc mở trình duyệt web trên điện thoại rất cồng kềnh; bảng dữ liệu web ngang khiến giảng viên dễ click nhầm sinh viên giữa các dòng.
  3. Khi chuyển ứng dụng sang điện thoại, Android tự động đóng kết nối mạng nền (background network freeze) làm hỏng luồng đăng nhập Google OAuth thông thường.
  4. Quy chế sinh viên vắng $\ge 20\%$ sẽ bị cấm thi (banned), nhưng giảng viên không có công cụ tự động cảnh báo sớm ở mốc $15\%$ (warning), dẫn đến sinh viên bị cấm thi bất ngờ.

---

## 2. User Persona

### 👤 Giảng viên: Thầy Nguyễn Văn Minh
- **Tuổi:** 38
- **Vai trò:** Giảng viên Bộ môn Kỹ thuật Phần mềm (Software Engineering), Đại học FPT
- **Quy mô giảng dạy:** 4 lớp/học kỳ (SE1801, SE1802, SE1803, SE1804 ~ 130 sinh viên)
- **Thiết bị:** Smartphone Android (Pixel 7 / Galaxy S22 - viewport 412dp) và Laptop Windows
- **Môi trường hoạt động:** Thường xuyên di chuyển giữa các phòng học, giảng đường; mạng Wi-Fi trường đôi lúc suy giảm băng thông giờ cao điểm.

### 🎯 Mục tiêu (Goals)
1. Hoàn tất điểm danh cả lớp trong **dưới 45 giây** ngay trên điện thoại khi đứng trên bục giảng.
2. Thao tác chính xác bằng một tay, triệt tiêu việc bấm nhầm giữa Có mặt (Present) và Vắng mặt (Absent).
3. Tự động nhận diện sinh viên vắng $\ge 15\%$ để nhắc nhở hoặc kích hoạt gửi email cảnh báo học vụ.
4. Lưu nháp an toàn, không bị mất bản ghi điểm danh khi mạng Wi-Fi chập chờn.

### ⚠️ Nỗi đau (Pain Points)
- **Giao diện bảng ngang Desktop không phù hợp di động:** Cần cuộn ngang liên tục để thấy nút trạng thái; nút nhỏ dễ bấm trượt.
- **Trục trặc đăng nhập OAuth trên Android:** Khi Chrome mở lên xác thực, app Android bị đưa về chế độ background và đứt kết nối mạng trao đổi token.
- **Dữ liệu giả mạo/chưa chuẩn hóa:** Các nút chuyển lớp ("Previous/Next") hoặc dòng chữ "Draft auto-saved" ảo trên bản cũ gây hiểu lầm trạng thái thực của dữ liệu.
- **Khó khăn khi xuất file trên điện thoại:** Không thể dùng lệnh mở thư mục cục bộ ("Open Folder") như trên Windows.

---

## 3. Tuyên bố bài toán (Problem Statement)

> **"Làm thế nào để chuyển đổi và tối ưu hóa hệ thống điểm danh từ Desktop sang ứng dụng Android di động cho giảng viên Đại học FPT, đảm bảo đăng nhập OAuth ổn định, điểm danh bằng một tay chính xác < 45 giây, và tự động cảnh báo sinh viên nguy cơ cấm thi dựa trên luật quy chế học vụ?"**

---

## 4. Chỉ số thành công đo được (Measurable Success Metrics / KPIs)

| Chỉ số (KPI) | Baseline (Cũ) | Mục tiêu Lab 2 Android | Bằng chứng mã nguồn đạt được |
| :--- | :---: | :---: | :--- |
| **Thời gian điểm danh 1 lớp (30 SV)** | ~180 giây (FAP web/Desktop) | **< 45 giây** | Thẻ dọc `AttendanceCard` chọn 1 chạm, mặc định Present |
| **Tỷ lệ thao tác bấm nhầm** | 8% - 12% | **< 1%** | Nút trạng thái $\ge 48\text{dp}$, tách biệt màu sắc & icon cảnh báo |
| **Tỷ lệ đăng nhập OAuth thành công trên Android** | 0% (Lỗi socket background) | **100% ổn định** | Loopback server + `AppLifecycleListener` đợi app quay lại foreground |
| **Phát hiện sinh viên nguy cơ cấm thi** | Rà soát thủ công | **100% tự động** | `AttendanceStatsService` quét ngưỡng $15\%$ (warn) và $20\%$ (ban) |
| **Lưu xuất tệp trên thiết bị di động** | Lỗi mở thư mục Desktop | **100% tương thích** | `FileService.saveTextFile` tích hợp Mobile File Picker |
