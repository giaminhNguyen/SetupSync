@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Công cụ quản lý SSH
chcp 65001 >nul
color 0B

set "SSH_DIR=%USERPROFILE%\.ssh"
set "CONFIG_FILE=%SSH_DIR%\config"
set "TMP_FILE=%SSH_DIR%\config.tmp"

if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"
if not exist "%CONFIG_FILE%" type nul > "%CONFIG_FILE%"

:MENU
cls
call :HEADER
echo.
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                        MENU CHÍNH                         ║
echo   ╠════════════════════════════════════════════════════════════╣
echo   ║  [1] Danh sách SSH key / Copy public key                  ║
echo   ║  [2] Tạo SSH mới                                          ║
echo   ║  [3] Thêm / sửa / xoá cấu hình host                       ║
echo   ║  [4] Xoá SSH key                                          ║
echo   ║  [5] Xem nội dung config                                 ║
echo   ║  [0] Thoát                                                ║
echo   ╚════════════════════════════════════════════════════════════╝
echo.
color 0E
choice /c 123450 /n /m "  Chọn chức năng: "
set "opt=%errorlevel%"
color 0B

if "%opt%"=="1" goto LIST_KEYS
if "%opt%"=="2" goto CREATE_KEY
if "%opt%"=="3" goto MANAGE_HOST
if "%opt%"=="4" goto DELETE_KEY
if "%opt%"=="5" goto SHOW_CONFIG
if "%opt%"=="6" exit /b
goto MENU

:HEADER
color 0A
echo ╔════════════════════════════════════════════════════════════╗
echo ║                    CÔNG CỤ QUẢN LÝ SSH                    ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  Thư mục SSH: %SSH_DIR%
echo ╚════════════════════════════════════════════════════════════╝
color 0B
exit /b

:PAUSE_MENU
echo.
color 0D
echo   Nhấn phím bất kỳ để quay về menu...
pause >nul
color 0B
goto MENU

:LIST_KEYS
cls
call :HEADER
echo.
color 0A
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║             DANH SÁCH SSH KEY VÀ PUBLIC KEY              ║
echo   ╚════════════════════════════════════════════════════════════╝
color 0B
echo.

set /a KEY_COUNT=0
for /f "delims=" %%F in ('dir /b /a-d "%SSH_DIR%" 2^>nul') do (
    if /i not "%%F"=="config" if /i not "%%F"=="known_hosts" if /i not "%%F"=="known_hosts.old" if /i not "%%~xF"==".pub" (
        set /a KEY_COUNT+=1
        set "KEY!KEY_COUNT!=%%F"
        color 0E
        echo   [!KEY_COUNT!] Private: %%F
        color 0B
        if exist "%SSH_DIR%\%%F.pub" (
            echo       Public : %%F.pub
        ) else (
            color 0C
            echo       Public : (không tìm thấy)
            color 0B
        )
        echo.
    )
)

if !KEY_COUNT! EQU 0 (
    color 0C
    echo   Không tìm thấy SSH key nào.
    color 0B
    echo.
)

color 0E
echo   [C] Copy public key theo số
echo   [M] Quay về menu
color 0B
echo.
choice /c CM /n /m "  Chọn thao tác: "
if errorlevel 2 goto MENU
goto COPY_PUB

:COPY_PUB
cls
call :HEADER
echo.
color 0A
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                    COPY PUBLIC KEY                        ║
echo   ╚═══════════════��════════════════════════════════════════════╝
color 0B
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MENU

call :INPUT_NUMBER "Nhập số key để copy public key (hoặc Q để về menu)" COPY_INDEX
if errorlevel 1 goto MENU

call :GET_KEY_BY_INDEX "!COPY_INDEX!" COPY_KEY
if errorlevel 1 (
    color 0C
    echo.
    echo   Số không hợp lệ.
    color 0B
    call :PAUSE_MENU
    goto MENU
)

if not exist "%SSH_DIR%\!COPY_KEY!.pub" (
    color 0C
    echo.
    echo   Không tìm thấy file public key.
    color 0B
    call :PAUSE_MENU
    goto MENU
)

powershell -NoProfile -Command "Get-Content -Raw '%SSH_DIR%\!COPY_KEY!.pub' | Set-Clipboard"
color 0A
echo.
echo   Đã copy public key vào clipboard:
color 0B
echo   %SSH_DIR%\!COPY_KEY!.pub
echo.
call :PAUSE_MENU
goto MENU

:CREATE_KEY
cls
call :HEADER
echo.
color 0A
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                         TẠO SSH MỚI                       ║
echo   ╚════════════════════════════════════════════════════════════╝
color 0B
echo.

call :INPUT_TEXT "Tên key mới (Q để về menu)" NEW_KEY
if errorlevel 1 goto MENU
if /i "!NEW_KEY!"=="q" goto MENU
if "!NEW_KEY!"=="" goto MENU

call :INPUT_TEXT "Email / comment (Q để về menu)" NEW_EMAIL
if errorlevel 1 goto MENU
if /i "!NEW_EMAIL!"=="q" goto MENU
if "!NEW_EMAIL!"=="" goto MENU

if exist "%SSH_DIR%\!NEW_KEY!" (
    color 0C
    echo.
    echo   Key đã tồn tại: !NEW_KEY!
    color 0B
    call :PAUSE_MENU
    goto MENU
)

color 0E
echo.
echo   Đang tạo key...
color 0B
ssh-keygen -t ed25519 -C "!NEW_EMAIL!" -f "%SSH_DIR%\!NEW_KEY!"

color 0A
echo.
echo   Hoàn tất.
color 0B
call :PAUSE_MENU
goto MENU

:MANAGE_HOST
cls
call :HEADER
echo.
color 0A
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║            THÊM / SỬA / XOÁ CẤU HÌNH HOST                 ║
echo   ╚════════════════════════════════════════════════════════════╝
color 0B
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MENU

call :INPUT_NUMBER "Chọn số SSH key (hoặc Q để về menu)" KEY_INDEX
if errorlevel 1 goto MENU

call :GET_KEY_BY_INDEX "!KEY_INDEX!" SELECTED_KEY
if errorlevel 1 (
    color 0C
    echo.
    echo   Số key không hợp lệ.
    color 0B
    call :PAUSE_MENU
    goto MENU
)

color 0A
echo.
echo   Key đã chọn: !SELECTED_KEY!
color 0B
echo.

call :SHOW_HOSTS_SELECT
echo.
call :INPUT_TEXT "Nhập số host để sửa/xoá, hoặc Enter để thêm mới (Q để về menu)" HOST_CHOICE
if errorlevel 1 goto MENU

if "!HOST_CHOICE!"=="" goto ADD_HOST

call :GET_HOST_BY_INDEX "!HOST_CHOICE!" HOST_ALIAS
if errorlevel 1 (
    color 0C
    echo.
    echo   Số host không hợp lệ.
    color 0B
    call :PAUSE_MENU
    goto MENU
)

color 0E
echo.
echo   Host đã chọn: !HOST_ALIAS!
color 0B
echo   [1] Sửa block
echo   [2] Xoá block
echo   [3] Quay lại
choice /c 123 /n /m "  Chọn thao tác: "
set "ACT=%errorlevel%"

if "!ACT!"=="1" goto EDIT_HOST
if "!ACT!"=="2" goto DELETE_HOST
goto MENU

:ADD_HOST
call :INPUT_TEXT "HostName thật (vd: github.com, gitlab.com)" REAL_HOST
if errorlevel 1 goto MENU
if /i "!REAL_HOST!"=="q" goto MENU
if "!REAL_HOST!"=="" goto MENU

call :INPUT_TEXT "Alias trong config" HOST_ALIAS_NEW
if errorlevel 1 goto MENU
if /i "!HOST_ALIAS_NEW!"=="q" goto MENU
if "!HOST_ALIAS_NEW!"=="" set "HOST_ALIAS_NEW=!REAL_HOST!"

call :INPUT_TEXT "User SSH (mặc định: git)" SSH_USER
if errorlevel 1 goto MENU
if /i "!SSH_USER!"=="q" goto MENU
if "!SSH_USER!"=="" set "SSH_USER=git"

call :INPUT_TEXT "Port SSH (mặc định: 22)" SSH_PORT
if errorlevel 1 goto MENU
if /i "!SSH_PORT!"=="q" goto MENU
if "!SSH_PORT!"=="" set "SSH_PORT=22"

set "IDENTITY_PATH=%SSH_DIR%\!SELECTED_KEY!"

call :APPEND_BLOCK "!HOST_ALIAS_NEW!" "!REAL_HOST!" "!SSH_USER!" "!SSH_PORT!" "!IDENTITY_PATH!"
color 0A
echo.
echo   Đã thêm block cấu hình.
color 0B
call :PAUSE_MENU
goto MENU

:EDIT_HOST
call :INPUT_TEXT "HostName thật mới" REAL_HOST
if errorlevel 1 goto MENU
if /i "!REAL_HOST!"=="q" goto MENU
if "!REAL_HOST!"=="" goto MENU

call :INPUT_TEXT "Alias mới" HOST_ALIAS_NEW
if errorlevel 1 goto MENU
if /i "!HOST_ALIAS_NEW!"=="q" goto MENU
if "!HOST_ALIAS_NEW!"=="" set "HOST_ALIAS_NEW=!HOST_ALIAS!"

call :INPUT_TEXT "User SSH mới (mặc định: git)" SSH_USER
if errorlevel 1 goto MENU
if /i "!SSH_USER!"=="q" goto MENU
if "!SSH_USER!"=="" set "SSH_USER=git"

call :INPUT_TEXT "Port SSH mới (mặc định: 22)" SSH_PORT
if errorlevel 1 goto MENU
if /i "!SSH_PORT!"=="q" goto MENU
if "!SSH_PORT!"=="" set "SSH_PORT=22"

set "IDENTITY_PATH=%SSH_DIR%\!SELECTED_KEY!"

call :REMOVE_HOST_BLOCK "!HOST_ALIAS!"
call :APPEND_BLOCK "!HOST_ALIAS_NEW!" "!REAL_HOST!" "!SSH_USER!" "!SSH_PORT!" "!IDENTITY_PATH!"
color 0A
echo.
echo   Đã cập nhật block cấu hình.
color 0B
call :PAUSE_MENU
goto MENU

:DELETE_HOST
call :REMOVE_HOST_BLOCK "!HOST_ALIAS!"
color 0A
echo.
echo   Đã xoá block host: !HOST_ALIAS!
color 0B
call :PAUSE_MENU
goto MENU

:DELETE_KEY
cls
call :HEADER
echo.
color 0A
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                         XOÁ SSH KEY                       ║
echo   ╚════════════════════════════════════════════════════════════╝
color 0B
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MENU

call :INPUT_NUMBER "Chọn số key cần xoá (hoặc Q để về menu)" DEL_INDEX
if errorlevel 1 goto MENU

call :GET_KEY_BY_INDEX "!DEL_INDEX!" DEL_KEY
if errorlevel 1 (
    color 0C
    echo.
    echo   Số key không hợp lệ.
    color 0B
    call :PAUSE_MENU
    goto MENU
)

color 0E
echo.
echo   Bạn sắp xoá: !DEL_KEY!
color 0B
choice /c YN /n /m "  Xác nhận xoá? [Y/N]: "
if errorlevel 2 goto MENU

del /f /q "%SSH_DIR%\!DEL_KEY!" >nul 2>nul
del /f /q "%SSH_DIR%\!DEL_KEY!.pub" >nul 2>nul

call :REMOVE_KEY_FROM_CONFIG "%SSH_DIR%\!DEL_KEY!"
color 0A
echo.
echo   Đã xoá key.
color 0B
call :PAUSE_MENU
goto MENU

:SHOW_CONFIG
cls
call :HEADER
echo.
color 0A
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                      NỘI DUNG CONFIG                      ║
echo   ╚════════════════════════════════════════════════════════════╝
color 0B
echo.

if not exist "%CONFIG_FILE%" (
    color 0C
    echo   Chưa có file config.
    color 0B
) else (
    type "%CONFIG_FILE%"
)
echo.
call :PAUSE_MENU
goto MENU

:SHOW_KEYS_SELECT
set /a KEY_COUNT=0
for /f "delims=" %%F in ('dir /b /a-d "%SSH_DIR%" 2^>nul') do (
    if /i not "%%F"=="config" if /i not "%%F"=="known_hosts" if /i not "%%F"=="known_hosts.old" if /i not "%%~xF"==".pub" (
        set /a KEY_COUNT+=1
        set "KEY!KEY_COUNT!=%%F"
        color 0E
        echo   [!KEY_COUNT!] %%F
        color 0B
    )
)
if !KEY_COUNT! EQU 0 (
    color 0C
    echo   Không có SSH key nào.
    color 0B
    exit /b 1
)
echo.
exit /b 0

:GET_KEY_BY_INDEX
set "target=%~1"
set "outvar=%~2"
set "%outvar%="
set /a current=0
for /f "delims=" %%F in ('dir /b /a-d "%SSH_DIR%" 2^>nul') do (
    if /i not "%%F"=="config" if /i not "%%F"=="known_hosts" if /i not "%%F"=="known_hosts.old" if /i not "%%~xF"==".pub" (
        set /a current+=1
        if "!current!"=="%target%" set "%outvar%=%%F"
    )
)
if not defined %outvar% exit /b 1
exit /b 0

:SHOW_HOSTS_SELECT
color 0A
echo   Các host hiện có trong config:
color 0B
echo   ------------------------------------------------------------
set /a HOST_COUNT=0
for /f "usebackq tokens=1,* delims= " %%A in ("%CONFIG_FILE%") do (
    if /i "%%A"=="Host" (
        if /i not "%%B"=="*" if /i not "%%B"=="?" (
            set /a HOST_COUNT+=1
            set "HOST!HOST_COUNT!=%%B"
            color 0E
            echo   [!HOST_COUNT!] %%B
            color 0B
        )
    )
)
if !HOST_COUNT! EQU 0 (
    color 0C
    echo   (Chưa có host nào)
    color 0B
)
echo.
exit /b 0

:GET_HOST_BY_INDEX
set "target=%~1"
set "outvar=%~2"
set "%outvar%="
set /a current=0
for /f "usebackq tokens=1,* delims= " %%A in ("%CONFIG_FILE%") do (
    if /i "%%A"=="Host" (
        if /i not "%%B"=="*" if /i not "%%B"=="?" (
            set /a current+=1
            if "!current!"=="%target%" set "%outvar%=%%B"
        )
    )
)
if not defined %outvar% exit /b 1
exit /b 0

:INPUT_TEXT
set "prompt=%~1"
set "outvar=%~2"
set "%outvar%="
set /p "%outvar%=  %prompt%: "
if /i "!%outvar%!"=="Q" exit /b 1
exit /b 0

:INPUT_NUMBER
set "prompt=%~1"
set "outvar=%~2"
set "%outvar%="
set /p "%outvar%=  %prompt%: "
if /i "!%outvar%!"=="Q" exit /b 1
if not defined %outvar% exit /b 1
for /f "delims=0123456789" %%A in ("!%outvar%!") do exit /b 1
exit /b 0

:APPEND_BLOCK
set "alias=%~1"
set "hostname=%~2"
set "user=%~3"
set "port=%~4"
set "identity=%~5"

>> "%CONFIG_FILE%" echo.
>> "%CONFIG_FILE%" echo Host %alias%
>> "%CONFIG_FILE%" echo     HostName %hostname%
>> "%CONFIG_FILE%" echo     User %user%
>> "%CONFIG_FILE%" echo     Port %port%
>> "%CONFIG_FILE%" echo     IdentityFile %identity%
>> "%CONFIG_FILE%" echo     IdentitiesOnly yes
>> "%CONFIG_FILE%" echo.
exit /b 0

:REMOVE_HOST_BLOCK
set "target=%~1"
if not exist "%CONFIG_FILE%" exit /b 0

break > "%TMP_FILE%"
set "skip=0"

for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    set "line=%%L"
    if /i "!line:~0,5!"=="Host " (
        set "currentHost=!line:~5!"
        if /i "!currentHost!"=="%target%" (
            set "skip=1"
        ) else (
            set "skip=0"
        )
    )

    if "!skip!"=="0" (
        >> "%TMP_FILE%" echo(!line!
    )
)

move /y "%TMP_FILE%" "%CONFIG_FILE%" >nul
exit /b 0

:REMOVE_KEY_FROM_CONFIG
set "keypath=%~1"
if not exist "%CONFIG_FILE%" exit /b 0

break > "%TMP_FILE%"
for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    echo(%%L | findstr /i /c:"%keypath%" >nul
    if errorlevel 1 (
        >> "%TMP_FILE%" echo(%%L
    )
)

move /y "%TMP_FILE%" "%CONFIG_FILE%" >nul
exit /b 0