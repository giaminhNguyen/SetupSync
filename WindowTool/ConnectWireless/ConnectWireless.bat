@echo off
:menu
color 0a
chcp 65001 >nul
cls
echo ==============================================
echo ADB Utility Menu
echo ==============================================
echo 0 - Danh sách thiết bị đang kết nối
echo 1 - Kết nối qua WiFi
echo 2 - Kết nối qua WiFi TCP
echo 3 - Khởi động lại TCP
echo 4 - Ngắt kết nối WiFi đang chạy

echo ==============================================
set /p choice="Nhập số để chọn chức năng: "

if "%choice%"=="0" goto list_devices
if "%choice%"=="1" goto connect_wifi
if "%choice%"=="2" goto connect_wifi_tcp
if "%choice%"=="3" goto restart_TCP
if "%choice%"=="4" goto disconnect_wifi

goto menu

:list_devices
echo Danh sách thiết bị đang kết nối:
adb devices
pause
goto menu

:connect_wifi
set /p ip_port="Nhập IP & Port: "
adb connect %ip_port%
if %errorlevel%==0 (
    echo Kết nối thành công với %ip_port%.
) else (
    echo Kết nối thất bại. Vui lòng kiểm tra IP và thiết bị.
)
pause
goto menu

:connect_wifi_tcp
set /p ip="Nhập IP: "
adb connect %ip%
if %errorlevel%==0 (
    echo Kết nối thành công với %ip%.
) else (
    echo Kết nối thất bại. Vui lòng kiểm tra IP và thiết bị.
)
pause
goto menu

:disconnect_wifi
adb disconnect
echo Đã ngắt kết nối WiFi với tất cả thiết bị.
pause
goto menu

:restart_TCP
adb tcpip 5555
if %errorlevel%==0 (
    echo Đã khởi động lại TCP với port 5555.
)

pause
goto menu
