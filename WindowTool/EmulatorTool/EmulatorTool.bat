@echo off
:: Cài đặt đường dẫn SDK emulator
set SDK_PATH=C:\Users\GiaMing\AppData\Local\Android\Sdk\emulator

:: Kiểm tra tồn tại của emulator.exe
if not exist "%SDK_PATH%\emulator.exe" (
    echo [Lỗi] Không tìm thấy emulator.exe trong đường dẫn SDK.
    pause
    exit /b
)
chcp 65001 >nul
color 0A 
:menu
cls
call :list_emulators

:: Hiển thị menu
echo.
echo ============= MENU =============
echo 0. Khởi chạy emulator
echo 1. Xóa dữ liệu emulator
echo 2. Đóng emulator
echo 3. Xóa dữ liệu toàn bộ emulator
echo 4. Đóng toàn bộ emulator
echo ==================================
echo.

set /p choice="Nhập lựa chọn của bạn: "

if "%choice%"=="0" call :launch_emulator
if "%choice%"=="1" call :wipe_data_emulator
if "%choice%"=="2" call :kill_emulator
if "%choice%"=="3" call :wipe_all_data
if "%choice%"=="4" call :kill_all_emulators

goto menu

:list_emulators
:: Lấy danh sách AVD
setlocal enabledelayedexpansion
set i=0
for /f "tokens=*" %%a in ('"%SDK_PATH%\emulator.exe" -list-avds') do (
    set /a i+=1
    echo [!i!] %%a
    call :get_emulator_status "%%a"
)
endlocal
exit /b

:get_emulator_status
:: Kiểm tra trạng thái của AVD
for /f "tokens=*" %%s in ('tasklist /FI "IMAGENAME eq qemu-system-*" /FI "WINDOWTITLE eq %~1*"') do (
    echo      Trạng thái: Đang chạy
    exit /b
)
echo      Trạng thái: Tắt
exit /b

:launch_emulator
cls
call :list_emulators
set /p avd_num="Chọn số thứ tự AVD để khởi chạy: "
setlocal enabledelayedexpansion
set i=0
for /f "tokens=*" %%a in ('"%SDK_PATH%\emulator.exe" -list-avds') do (
    set /a i+=1
    if "!i!"=="%avd_num%" (
        echo Đang khởi chạy AVD: %%a...
        "%SDK_PATH%\emulator.exe" -avd %%a
        endlocal
        goto menu
    )
)
echo [Lỗi] Số thứ tự không hợp lệ.
endlocal
pause
goto menu

:wipe_data_emulator
cls
call :list_emulators
set /p avd_num="Chọn số thứ tự AVD để xóa dữ liệu: "
setlocal enabledelayedexpansion
set i=0
for /f "tokens=*" %%a in ('"%SDK_PATH%\emulator.exe" -list-avds') do (
    set /a i+=1
    if "!i!"=="%avd_num%" (
        echo Đang xóa dữ liệu của AVD: %%a...
        "%SDK_PATH%\emulator.exe" -avd %%a -wipe-data
        endlocal
        goto menu
    )
)
echo [Lỗi] Số thứ tự không hợp lệ.
endlocal
pause
goto menu

:kill_emulator
cls
call :list_emulators
set /p avd_num="Chọn số thứ tự AVD để đóng: "
setlocal enabledelayedexpansion
set i=0
for /f "tokens=*" %%a in ('"%SDK_PATH%\emulator.exe" -list-avds') do (
    set /a i+=1
    if "!i!"=="%avd_num%" (
        echo Đang đóng AVD: %%a...
        taskkill /F /FI "WINDOWTITLE eq %%a*"
        endlocal
        goto menu
    )
)
echo [Lỗi] Số thứ tự không hợp lệ.
endlocal
pause
goto menu

:wipe_all_data
cls
echo Đang xóa dữ liệu của toàn bộ AVD...
for /f "tokens=*" %%a in ('"%SDK_PATH%\emulator.exe" -list-avds') do (
    "%SDK_PATH%\emulator.exe" -avd %%a -wipe-data
)
echo Hoàn tất.
pause
goto menu

:kill_all_emulators
cls
echo Đang đóng toàn bộ AVD...
taskkill /F /IM qemu-system-*
echo Hoàn tất.
pause
goto menu
