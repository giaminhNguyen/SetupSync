@echo off
:: Kiểm tra quyền Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Script cần quyền quản trị. Đang yêu cầu quyền...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Thiết lập môi trường
chcp 65001 >nul
color 0A

:start
cls
set /p folder=Nhập đường dẫn thư mục cần thao tác: 
if not exist "%folder%" (
    echo Thư mục không tồn tại. Vui lòng thử lại.
    pause
    goto start
)

:menu
cls
echo.
echo =================== MENU ===================
echo Đường dẫn đang chọn: %folder%
echo --------------------------------------------
echo [0] Liệt kê các đuôi mở rộng
echo [1] Xóa file theo đuôi mở rộng
echo [2] Chọn đường dẫn khác
echo ============================================
set /p choice=Nhập lựa chọn của bạn: 

if "%choice%"=="0" goto list_extensions
if "%choice%"=="1" goto delete_files
if "%choice%"=="2" goto start
goto menu

:: Nếu nhập sai lựa chọn, quay lại menu
echo Lựa chọn không hợp lệ.
pause
goto menu

:list_extensions
cls
echo Đang kiểm tra các đuôi mở rộng trong thư mục...
:: Làm sạch file tạm
if exist temp_list.txt del temp_list.txt
if exist sorted_final.txt del sorted_final.txt

for /r "%folder%" %%f in (*) do (
    for %%x in (%%~xf) do (
        echo %%x >> temp_list.txt
    )
)

sort temp_list.txt | findstr /v "^$" | findstr /v "temp_list.txt" > sorted_extensions.txt
del temp_list.txt

:: Loại bỏ trùng lặp
for /f "delims=" %%e in (sorted_extensions.txt) do (
    find /c "%%e" sorted_final.txt >nul 2>&1 || echo %%e >> sorted_final.txt
)
del sorted_extensions.txt

if not exist sorted_final.txt (
    echo Không tìm thấy file nào trong thư mục.
    pause
    goto menu
)

echo Các đuôi mở rộng trong thư mục:
type sorted_final.txt
del sorted_final.txt

echo.
pause
goto menu

:delete_files
cls
echo Đang làm việc với thư mục: %folder%
set /p ext=Nhập đuôi mở rộng cần xóa (ví dụ: .txt): 

echo Đang tìm các file có đuôi mở rộng "%ext%"...
if exist files_to_delete.txt del files_to_delete.txt

for /r "%folder%" %%f in (*%ext%) do (
    echo %%~f >> files_to_delete.txt
)

if not exist files_to_delete.txt (
    echo Không tìm thấy file nào với đuôi mở rộng "%ext%".
    pause
    goto menu
)

echo Các file tìm thấy:
type files_to_delete.txt
set /p confirm=Bạn có chắc chắn muốn xóa các file này? (Y/N/X): 

if /i "%confirm%"=="y" (
    for /f "delims=" %%f in (files_to_delete.txt) do del "%%f"
    echo Đã xóa các file.
) else if /i "%confirm%"=="n" (
    echo Đã hủy thao tác.
) else (
    goto menu
)

del files_to_delete.txt
pause
goto menu
