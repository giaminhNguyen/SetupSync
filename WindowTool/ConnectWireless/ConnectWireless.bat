@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

where adb >nul 2>&1
if errorlevel 1 (
    cls
    color 0C
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║                    ADB WIRELESS UTILITY                  ║
    echo ╠════════════════════════════════════════════════════════════╣
    echo ║ [LỖI] Không tìm thấy adb trong PATH.                      ║
    echo ║ Hãy cài Android Platform Tools và thêm adb vào PATH.     ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    pause
    exit /b 1
)

:MAIN
cls
color 0A
echo ╔════════════════════════════════════════════════════════════╗
echo ║                    ADB WIRELESS UTILITY                  ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║ [1] Danh sách thiết bị đang kết nối                       ║
echo ║ [2] Bật TCP/IP cho thiết bị (USB)                         ║
echo ║ [3] Kết nối ADB wireless                                  ║
echo ║ [4] Ngắt kết nối 1 thiết bị wireless                      ║
echo ║ [5] Ngắt kết nối tất cả thiết bị wireless                 ║
echo ║ [6] Chuyển thiết bị về USB mode                           ║
echo ║ [7] Thoát                                                 ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
color 0E
echo Nhập số chức năng rồi nhấn Enter. Nhập ESC trong các bước chọn để quay về menu.
echo.
color 0A
set /p "choice=Chọn chức năng [1-7]: "

if "%choice%"=="1" goto LIST_DEVICES
if "%choice%"=="2" goto ENABLE_TCPIP
if "%choice%"=="3" goto CONNECT_WIRELESS
if "%choice%"=="4" goto DISCONNECT_ONE
if "%choice%"=="5" goto DISCONNECT_ALL
if "%choice%"=="6" goto ADB_USB
if "%choice%"=="7" exit /b 0

color 0C
echo.
echo [LỖI] Lựa chọn không hợp lệ.
timeout /t 2 >nul
goto MAIN

:LIST_DEVICES
cls
color 0B
echo ╔════════════════════════════════════════════════════════════╗
echo ║                 DANH SÁCH THIẾT BỊ ADB                   ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
color 0F
adb devices
echo.
pause
goto MAIN

:ENABLE_TCPIP
cls
color 0B
echo ╔════════════════════════════════════════════════════════════╗
echo ║                    BẬT TCP/IP CHO THIẾT BỊ               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
color 0E
echo Lưu ý: Thiết bị nên đang kết nối bằng USB.
echo Nhập ESC rồi Enter để quay về menu.
echo.
color 0A

call :PickUsbDevice DEVICE_ID DEVICE_TEXT
if not defined DEVICE_ID goto MAIN

echo.
set /p "port=Nhập port TCP [mặc định 5555]: "
if /I "%port%"=="ESC" goto MAIN
if not defined port set "port=5555"

echo.
color 0F
echo Đang bật TCP/IP cho thiết bị: %DEVICE_TEXT%
color 0B
adb -s %DEVICE_ID% tcpip %port%

if errorlevel 1 (
    color 0C
    echo [LỖI] Không thể bật TCP/IP.
) else (
    color 0A
    echo [OK] Đã bật TCP/IP trên port %port%.
)

echo.
pause
goto MAIN

:CONNECT_WIRELESS
cls
color 0B
echo ╔════════════════════════════════════════════════════════════╗
echo ║                   KẾT NỐI ADB WIRELESS                   ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
color 0E
echo Nhập địa chỉ theo dạng IP:PORT, ví dụ: 192.168.1.10:5555
echo Nhập ESC rồi Enter để quay về menu.
echo.
color 0A
set /p "target=Nhập IP:PORT: "
if /I "%target%"=="ESC" goto MAIN
if not defined target (
    color 0C
    echo [LỖI] Bạn chưa nhập IP:PORT.
    echo.
    pause
    goto MAIN
)

echo.
color 0F
adb connect %target%

if errorlevel 1 (
    color 0C
    echo [LỖI] Kết nối thất bại tới %target%.
) else (
    color 0A
    echo [OK] Kết nối thành công tới %target%.
)

echo.
pause
goto MAIN

:DISCONNECT_ONE
cls
color 0B
echo ╔════════════════════════════════════════════════════════════╗
echo ║              NGẮT KẾT NỐI 1 THIẾT BỊ WIRELESS            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
call :PickWirelessDevice WIRELESS_ID WIRELESS_TEXT
if not defined WIRELESS_ID goto MAIN

echo.
color 0F
echo Đang ngắt kết nối %WIRELESS_TEXT%...
color 0B
adb disconnect %WIRELESS_TEXT%

if errorlevel 1 (
    color 0C
    echo [LỖI] Không thể ngắt kết nối %WIRELESS_TEXT%.
) else (
    color 0A
    echo [OK] Đã ngắt kết nối %WIRELESS_TEXT%.
)

echo.
pause
goto MAIN

:DISCONNECT_ALL
cls
color 0B
echo ╔════════════════════════════════════════════════════════════╗
echo ║             NGẮT TẤT CẢ KẾT NỐI WIRELESS                 ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
color 0F
adb disconnect

if errorlevel 1 (
    color 0C
    echo [LỖI] Không thể ngắt kết nối.
) else (
    color 0A
    echo [OK] Đã ngắt kết nối tất cả thiết bị wireless.
)

echo.
pause
goto MAIN

:ADB_USB
cls
color 0B
echo ╔════════════════════════════════════════════════════════════╗
echo ║                   CHUYỂN VỀ USB MODE                     ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
color 0F
adb usb

if errorlevel 1 (
    color 0C
    echo [LỖI] Không thể chuyển về USB mode.
) else (
    color 0A
    echo [OK] Đã chuyển thiết bị về USB mode.
)

echo.
pause
goto MAIN

:: ============================================================
:: FUNCTIONS
:: ============================================================

:PickUsbDevice
setlocal EnableDelayedExpansion
set "count=0"
set "tmpfile=%TEMP%\adb_usb_%RANDOM%.txt"

adb devices | findstr /R /C:"^[^ ]*[ ]*device$" > "%tmpfile%"

for /f "usebackq tokens=1" %%a in ("%tmpfile%") do (
    set /a count+=1
    set "dev!count!=%%a"
)

del "%tmpfile%" >nul 2>&1

if !count! EQU 0 (
    color 0C
    echo [LỖI] Không tìm thấy thiết bị USB nào đang ở trạng thái device.
    echo.
    endlocal & set "%~1=" & set "%~2=" & exit /b
)

color 0E
echo Danh sách thiết bị USB:
echo.
color 0F
for /L %%i in (1,1,!count!) do (
    call set "item=%%dev%%i%%"
    echo   %%i. !item!
)

echo.
color 0E
echo Nhập số thứ tự, hoặc nhập ESC để quay về menu.
echo.
color 0A

:ASK_USB
set "selected="
set /p "selected=Chọn thiết bị: "

if /I "!selected!"=="ESC" (
    endlocal & set "%~1=" & set "%~2=" & exit /b
)

echo !selected!| findstr /R "^[1-9][0-9]*$" >nul
if errorlevel 1 (
    color 0C
    echo [LỖI] Vui lòng nhập số hợp lệ hoặc ESC.
    color 0A
    goto ASK_USB
)

if !selected! GTR !count! (
    color 0C
    echo [LỖI] Số vượt quá danh sách.
    color 0A
    goto ASK_USB
)

call set "chosen=%%dev%selected%%"
endlocal & set "%~1=%chosen%" & set "%~2=%chosen%" & exit /b

:PickWirelessDevice
setlocal EnableDelayedExpansion
set "count=0"
set "tmpfile=%TEMP%\adb_wireless_%RANDOM%.txt"

adb devices | findstr /R /C:"^[^ ]*:[0-9]*[ ]*device$" > "%tmpfile%"

for /f "usebackq tokens=1" %%a in ("%tmpfile%") do (
    set /a count+=1
    set "dev!count!=%%a"
)

del "%tmpfile%" >nul 2>&1

if !count! EQU 0 (
    color 0C
    echo [LỖI] Không tìm thấy thiết bị wireless nào đang ở trạng thái device.
    echo.
    endlocal & set "%~1=" & set "%~2=" & exit /b
)

color 0E
echo Danh sách thiết bị wireless:
echo.
color 0F
for /L %%i in (1,1,!count!) do (
    call set "item=%%dev%%i%%"
    echo   %%i. !item!
)

echo.
color 0E
echo Nhập số thứ tự, hoặc nhập ESC để quay về menu.
echo.
color 0A

:ASK_WIRELESS
set "selected="
set /p "selected=Chọn thiết bị: "

if /I "!selected!"=="ESC" (
    endlocal & set "%~1=" & set "%~2=" & exit /b
)

echo !selected!| findstr /R "^[1-9][0-9]*$" >nul
if errorlevel 1 (
    color 0C
    echo [LỖI] Vui lòng nhập số hợp lệ hoặc ESC.
    color 0A
    goto ASK_WIRELESS
)

if !selected! GTR !count! (
    color 0C
    echo [LỖI] Số vượt quá danh sách.
    color 0A
    goto ASK_WIRELESS
)

call set "chosen=%%dev%selected%%"
endlocal & set "%~1=%chosen%" & set "%~2=%chosen%" & exit /b