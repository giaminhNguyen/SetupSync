@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Công cụ quản lý SSH
chcp 65001 >nul

set "SSH_DIR=%USERPROFILE%\.ssh"
set "CONFIG_FILE=%SSH_DIR%\config"
set "TMP_FILE=%SSH_DIR%\config.tmp"

if not exist "%SSH_DIR%" (
    mkdir "%SSH_DIR%"
    echo   [THÔNG TIN] Đã tạo thư mục SSH: %SSH_DIR%
)
if not exist "%CONFIG_FILE%" (
    type nul > "%CONFIG_FILE%"
    echo   [THÔNG TIN] Đã tự động tạo file config rỗng: %CONFIG_FILE%
    echo.
    echo   Nhấn phím bất kỳ để tiếp tục...
    pause >nul
)

:MENU
cls
call :HEADER
echo.
call :BOX "MENU CHÍNH"
echo.
call :MENU_ITEM 1 "Danh sách SSH key / Copy public key" 0A
call :MENU_ITEM 2 "Quản lý SSH key (tạo / sửa / xoá / test)" 0B
call :MENU_ITEM 3 "Thêm / sửa / xoá cấu hình host" 0D
call :MENU_ITEM 4 "Xem nội dung config" 0E
call :MENU_ITEM 0 "Thoát" 07
echo.
color 0E
choice /c 12340 /n /m "  Chọn chức năng: "
set "opt=%errorlevel%"
color 0B

if "%opt%"=="1" goto LIST_KEYS
if "%opt%"=="2" goto MANAGE_KEY
if "%opt%"=="3" goto MANAGE_HOST
if "%opt%"=="4" goto SHOW_CONFIG
if "%opt%"=="5" exit /b
goto MENU

:HEADER
color 0B
echo ╔════════════════════════════════════════════════════════════════════╗
color 0A
echo ║                       CÔNG CỤ QUẢN LÝ SSH                        ║
color 0B
echo ╠════════════════════════════════════════════════════════════════════╣
echo ║  Thư mục SSH: %SSH_DIR%
echo ╚════════════════════════════════════════════════════════════════════╝
exit /b

:BOX
set "title=%~1"
color 0A
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║%title:~0,66%║
echo ╚════════════════════════════════════════════════════════════════════╝
color 0B
exit /b

:MENU_ITEM
set "num=%~1"
set "text=%~2"
set "mc=%~3"
if "%mc%"=="" set "mc=0B"
color %mc%
echo   [%num%] %text%
color 0B
exit /b

:PAUSE_MENU
echo.
color 0D
echo   Nhấn phím bất kỳ để quay về menu...
pause >nul
color 0B
goto MENU

:PAUSE_MANAGE_KEY
echo.
color 0D
echo   Nhấn phím bất kỳ để quay về quản lý SSH key...
pause >nul
color 0B
goto MANAGE_KEY

:LIST_KEYS
cls
call :HEADER
echo.
call :BOX "DANH SÁCH SSH KEY VÀ PUBLIC KEY"
echo.

set /a KEY_COUNT=0
for /f "delims=" %%F in ('dir /b /a-d "%SSH_DIR%" 2^>nul') do (
    if /i not "%%F"=="config" if /i not "%%F"=="known_hosts" if /i not "%%F"=="known_hosts.old" if /i not "%%~xF"==".pub" (
        set /a KEY_COUNT+=1
        set "KEY!KEY_COUNT!=%%F"
        REM Lấy ngày file
        set "KEY_DATE="
        for %%A in ("%SSH_DIR%\%%F") do set "KEY_DATE=%%~tA"
        REM Lấy loại key từ file .pub
        set "KEY_TYPE=(không rõ)"
        if exist "%SSH_DIR%\%%F.pub" (
            for /f "tokens=1" %%T in ('type "%SSH_DIR%\%%F.pub" 2^>nul') do (
                if not defined KEY_TYPE_DONE set "KEY_TYPE=%%T" & set "KEY_TYPE_DONE=1"
            )
        )
        set "KEY_TYPE_DONE="
        color 0E
        echo   [!KEY_COUNT!] %%F
        color 03
        echo       Loại   : !KEY_TYPE!
        echo       Ngày   : !KEY_DATE!
        if exist "%SSH_DIR%\%%F.pub" (
            color 0A
            echo       Public : %%F.pub
        ) else (
            color 0C
            echo       Public : (không tìm thấy)
        )
        color 0B
        echo.
    )
)

if !KEY_COUNT! EQU 0 (
    color 0C
    echo   Không tìm thấy SSH key nào.
    color 0B
    echo.
)

color 0A
echo   [C] Copy public key theo số
color 0B
echo   [M] Quay về menu
echo.
color 0E
choice /c CM /n /m "  Chọn thao tác: "
if errorlevel 2 goto MENU
goto COPY_PUB

:COPY_PUB
cls
call :HEADER
echo.
call :BOX "COPY PUBLIC KEY"
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MENU

call :INPUT_NUMBER "Nhập số key để copy public key (hoặc Q để về menu)" COPY_INDEX
if errorlevel 1 goto MENU

call :GET_KEY_BY_INDEX "!COPY_INDEX!" COPY_KEY
if errorlevel 1 (
    call :MSG_ERROR "Số không hợp lệ."
    call :PAUSE_MENU
    goto MENU
)

if not exist "%SSH_DIR%\!COPY_KEY!.pub" (
    call :MSG_ERROR "Không tìm thấy file public key."
    call :PAUSE_MENU
    goto MENU
)

type "%SSH_DIR%\!COPY_KEY!.pub" | clip
call :MSG_OK "Đã copy public key vào clipboard: %SSH_DIR%\!COPY_KEY!.pub"
call :PAUSE_MENU
goto MENU

:MANAGE_KEY
cls
call :HEADER
echo.
call :BOX "QUẢN LÝ SSH KEY"
echo.
call :MENU_ITEM 1 "Tạo SSH mới" 0B
call :MENU_ITEM 2 "Chỉnh sửa SSH key" 0D
call :MENU_ITEM 3 "Xoá SSH key" 0C
call :MENU_ITEM 4 "Test kết nối SSH" 09
call :MENU_ITEM 0 "Quay về menu chính" 07
echo.
color 0E
choice /c 12340 /n /m "  Chọn thao tác: "
set "mk_opt=%errorlevel%"
color 0B

if "!mk_opt!"=="1" goto CREATE_KEY
if "!mk_opt!"=="2" goto EDIT_KEY
if "!mk_opt!"=="3" goto DELETE_KEY
if "!mk_opt!"=="4" goto TEST_SSH
goto MENU

:CREATE_KEY
cls
call :HEADER
echo.
call :BOX "TẠO SSH MỚI"
echo.

call :INPUT_TEXT "Tên key mới (Q để quay lại)" NEW_KEY
if errorlevel 1 goto MANAGE_KEY
if /i "!NEW_KEY!"=="q" goto MANAGE_KEY
if "!NEW_KEY!"=="" goto MANAGE_KEY

REM Kiểm tra tên key không chứa ký tự đặc biệt hoặc khoảng trắng
echo "!NEW_KEY!" | findstr /r "[ &^<>|;,%%=]" >nul
if !errorlevel! EQU 0 (
    call :MSG_ERROR "Tên key không được chứa khoảng trắng hoặc ký tự đặc biệt."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

call :INPUT_TEXT "Email / comment (Q để quay lại)" NEW_EMAIL
if errorlevel 1 goto MANAGE_KEY
if /i "!NEW_EMAIL!"=="q" goto MANAGE_KEY
if "!NEW_EMAIL!"=="" goto MANAGE_KEY

if exist "%SSH_DIR%\!NEW_KEY!" (
    call :MSG_ERROR "Key đã tồn tại: !NEW_KEY!"
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

echo.
color 0A
echo   Chọn loại key:
color 0E
echo   [1] ed25519  (khuyên dùng - nhanh, an toàn, key ngắn)
echo   [2] rsa 4096 (tương thích rộng, hỗ trợ hệ thống cũ)
echo   [3] ecdsa    (cân bằng giữa tốc độ và tương thích)
color 0B
echo.
choice /c 123 /n /m "  Chọn loại key: "
set "KEY_TYPE_OPT=%errorlevel%"

if "!KEY_TYPE_OPT!"=="1" (
    set "KEY_TYPE=ed25519"
    set "KEY_BITS="
)
if "!KEY_TYPE_OPT!"=="2" (
    set "KEY_TYPE=rsa"
    set "KEY_BITS=-b 4096"
)
if "!KEY_TYPE_OPT!"=="3" (
    set "KEY_TYPE=ecdsa"
    set "KEY_BITS=-b 521"
)

color 0E
echo.
echo   Đang tạo key loại !KEY_TYPE!...
color 0B
ssh-keygen -t !KEY_TYPE! !KEY_BITS! -C "!NEW_EMAIL!" -f "%SSH_DIR%\!NEW_KEY!"

call :MSG_OK "Hoàn tất. Đã tạo key !KEY_TYPE!: !NEW_KEY!"
call :PAUSE_MANAGE_KEY
goto MANAGE_KEY

:MANAGE_HOST
cls
call :HEADER
echo.
call :BOX "THÊM / SỬA / XOÁ CẤU HÌNH HOST"
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MENU

call :INPUT_NUMBER "Chọn số SSH key (hoặc Q để về menu)" KEY_INDEX
if errorlevel 1 goto MENU

call :GET_KEY_BY_INDEX "!KEY_INDEX!" SELECTED_KEY
if errorlevel 1 (
    call :MSG_ERROR "Số key không hợp lệ."
    call :PAUSE_MENU
    goto MENU
)

call :MSG_INFO "Key đã chọn: !SELECTED_KEY!"
echo.

call :SHOW_HOSTS_TABLE
echo.
call :INPUT_TEXT "Nhập số host để sửa/xoá, hoặc Enter để thêm mới (Q để về menu)" HOST_CHOICE
if errorlevel 1 goto MENU

if "!HOST_CHOICE!"=="" goto ADD_HOST

call :GET_HOST_BY_INDEX "!HOST_CHOICE!" HOST_ALIAS
if errorlevel 1 (
    call :MSG_ERROR "Số host không hợp lệ."
    call :PAUSE_MENU
    goto MENU
)

call :MSG_INFO "Host đã chọn: !HOST_ALIAS!"
echo   [1] Sửa block
echo   [2] Xoá block
echo   [3] Quay lại
choice /c 123 /n /m "  Chọn thao tác: "
set "ACT=%errorlevel%"

if "!ACT!"=="1" goto EDIT_HOST
if "!ACT!"=="2" goto DELETE_HOST
goto MANAGE_HOST

:ADD_HOST
call :INPUT_TEXT "HostName thật (mặc định: github.com)" REAL_HOST
if errorlevel 1 goto MENU
if /i "!REAL_HOST!"=="q" goto MENU
if "!REAL_HOST!"=="" set "REAL_HOST=github.com"

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
call :MSG_OK "Đã thêm block cấu hình."
call :PAUSE_MENU
goto MENU

:EDIT_HOST
if not defined SELECTED_KEY (
    call :MSG_ERROR "Chưa chọn SSH key. Vui lòng quay lại menu quản lý host."
    call :PAUSE_MENU
    goto MENU
)
call :INPUT_TEXT "HostName thật mới (mặc định: github.com)" REAL_HOST
if errorlevel 1 goto MENU
if /i "!REAL_HOST!"=="q" goto MENU
if "!REAL_HOST!"=="" set "REAL_HOST=github.com"

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
call :MSG_OK "Đã cập nhật block cấu hình."
call :PAUSE_MENU
goto MENU

:DELETE_HOST
call :REMOVE_HOST_BLOCK "!HOST_ALIAS!"
call :MSG_OK "Đã xoá block host: !HOST_ALIAS!"
call :PAUSE_MENU
goto MENU

:DELETE_KEY
cls
call :HEADER
echo.
call :BOX "XOÁ SSH KEY"
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MANAGE_KEY

call :INPUT_NUMBER "Chọn số key cần xoá (hoặc Q để quay lại)" DEL_INDEX
if errorlevel 1 goto MANAGE_KEY

call :GET_KEY_BY_INDEX "!DEL_INDEX!" DEL_KEY
if errorlevel 1 (
    call :MSG_ERROR "Số key không hợp lệ."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

call :MSG_WARN "Bạn sắp xoá: !DEL_KEY!"
choice /c YN /n /m "  Xác nhận xoá? [Y/N]: "
if errorlevel 2 goto MANAGE_KEY

del /f /q "%SSH_DIR%\!DEL_KEY!" >nul 2>nul
del /f /q "%SSH_DIR%\!DEL_KEY!.pub" >nul 2>nul

call :REMOVE_KEY_FROM_CONFIG "%SSH_DIR%\!DEL_KEY!"
call :MSG_OK "Đã xoá key."
call :PAUSE_MANAGE_KEY
goto MANAGE_KEY

:SHOW_CONFIG
cls
call :HEADER
echo.
call :BOX "NỘI DUNG CONFIG"
echo.

if not exist "%CONFIG_FILE%" (
    call :MSG_ERROR "Chưa có file config."
) else (
    type "%CONFIG_FILE%"
)
echo.
call :PAUSE_MENU
goto MENU

:TEST_SSH
cls
call :HEADER
echo.
call :BOX "TEST KẾT NỐI SSH"
echo.

set /a HOST_COUNT=0
for /f "usebackq tokens=1,* delims= " %%A in ("%CONFIG_FILE%") do (
    if /i "%%A"=="Host" if /i not "%%B"=="*" if /i not "%%B"=="?" set /a HOST_COUNT+=1
)
if !HOST_COUNT! EQU 0 (
    call :MSG_ERROR "Chưa có host nào trong config để test."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)
call :SHOW_HOSTS_TABLE

call :INPUT_NUMBER "Chọn số host để test (hoặc Q để quay lại)" TEST_INDEX
if errorlevel 1 goto MANAGE_KEY

call :GET_HOST_BY_INDEX "!TEST_INDEX!" TEST_HOST
if errorlevel 1 (
    call :MSG_ERROR "Số host không hợp lệ."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

call :MSG_INFO "Đang test kết nối tới: !TEST_HOST!"
echo.
color 0E
echo   ─────────────────────────────────────────────────────────
color 0B
echo.
ssh -T !TEST_HOST!
set "SSH_EXIT=!errorlevel!"
echo.
color 0E
echo   ─────────────────────────────────────────────────────────
color 0B
echo.

REM GitHub trả về exit code 1 khi xác thực thành công (vì không cho phép shell)
if "!SSH_EXIT!"=="0" (
    call :MSG_OK "Kết nối thành công!"
) else if "!SSH_EXIT!"=="1" (
    call :MSG_OK "Xác thực thành công! (Server không cho phép shell - bình thường với GitHub/GitLab)"
) else (
    call :MSG_ERROR "Kết nối thất bại (exit code: !SSH_EXIT!). Kiểm tra lại cấu hình."
)
call :PAUSE_MANAGE_KEY
goto MANAGE_KEY

:EDIT_KEY
cls
call :HEADER
echo.
call :BOX "CHỈNH SỬA SSH KEY"
echo.

call :SHOW_KEYS_SELECT
if errorlevel 1 goto MANAGE_KEY

call :INPUT_NUMBER "Chọn số key cần chỉnh sửa (hoặc Q để quay lại)" EDIT_INDEX
if errorlevel 1 goto MANAGE_KEY

call :GET_KEY_BY_INDEX "!EDIT_INDEX!" EDIT_KEY_NAME
if errorlevel 1 (
    call :MSG_ERROR "Số key không hợp lệ."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

call :MSG_INFO "Key đã chọn: !EDIT_KEY_NAME!"
echo.
color 0A
echo   Chọn thao tác chỉnh sửa:
color 0E
echo   [1] Đổi passphrase
echo   [2] Đổi comment
echo   [3] Đổi tên key
echo   [4] Quay lại
color 0B
echo.
choice /c 1234 /n /m "  Chọn thao tác: "
set "EDIT_ACT=%errorlevel%"

if "!EDIT_ACT!"=="1" goto EDIT_PASSPHRASE
if "!EDIT_ACT!"=="2" goto EDIT_COMMENT
if "!EDIT_ACT!"=="3" goto EDIT_RENAME
goto MANAGE_KEY

:EDIT_PASSPHRASE
echo.
call :MSG_INFO "Đổi passphrase cho key: !EDIT_KEY_NAME!"
echo.
color 0E
echo   (Bạn sẽ được yêu cầu nhập passphrase cũ, sau đó nhập passphrase mới)
color 0B
echo.
ssh-keygen -p -f "%SSH_DIR%\!EDIT_KEY_NAME!"
if !errorlevel! EQU 0 (
    call :MSG_OK "Đã đổi passphrase thành công."
) else (
    call :MSG_ERROR "Đổi passphrase thất bại."
)
call :PAUSE_MANAGE_KEY
goto MANAGE_KEY

:EDIT_COMMENT
echo.
call :INPUT_TEXT "Nhập comment mới (Q để quay lại)" NEW_COMMENT
if errorlevel 1 goto MANAGE_KEY
if /i "!NEW_COMMENT!"=="q" goto MANAGE_KEY
if "!NEW_COMMENT!"=="" (
    call :MSG_ERROR "Comment không được để trống."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

echo.
call :MSG_INFO "Đang cập nhật comment cho key: !EDIT_KEY_NAME!"
color 0E
echo   (Bạn có thể được yêu cầu nhập passphrase nếu key có mật khẩu)
color 0B
echo.
ssh-keygen -c -C "!NEW_COMMENT!" -f "%SSH_DIR%\!EDIT_KEY_NAME!"
if !errorlevel! EQU 0 (
    call :MSG_OK "Đã đổi comment thành công."
) else (
    call :MSG_ERROR "Đổi comment thất bại."
)
call :PAUSE_MANAGE_KEY
goto MANAGE_KEY

:EDIT_RENAME
echo.
call :INPUT_TEXT "Nhập tên mới cho key (Q để quay lại)" NEW_NAME
if errorlevel 1 goto MANAGE_KEY
if /i "!NEW_NAME!"=="q" goto MANAGE_KEY
if "!NEW_NAME!"=="" (
    call :MSG_ERROR "Tên không được để trống."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

if exist "%SSH_DIR%\!NEW_NAME!" (
    call :MSG_ERROR "Key với tên !NEW_NAME! đã tồn tại."
    call :PAUSE_MANAGE_KEY
    goto MANAGE_KEY
)

REM Đổi tên private key
ren "%SSH_DIR%\!EDIT_KEY_NAME!" "!NEW_NAME!"
REM Đổi tên public key nếu có
if exist "%SSH_DIR%\!EDIT_KEY_NAME!.pub" (
    ren "%SSH_DIR%\!EDIT_KEY_NAME!.pub" "!NEW_NAME!.pub"
)

REM Cập nhật đường dẫn IdentityFile trong config (giữ nguyên blank lines)
if exist "%CONFIG_FILE%" (
    break > "%TMP_FILE%"
    for /f "tokens=1* delims=:" %%A in ('findstr /n "^" "%CONFIG_FILE%"') do (
        set "line=%%B"
        if "!line!"=="" (
            >> "%TMP_FILE%" echo.
        ) else (
            set "replaced=0"
            echo(!line! | findstr /i /c:"%SSH_DIR%\!EDIT_KEY_NAME!" >nul
            if !errorlevel! EQU 0 (
                >> "%TMP_FILE%" echo(    IdentityFile %SSH_DIR%\!NEW_NAME!
                set "replaced=1"
            )
            if "!replaced!"=="0" (
                >> "%TMP_FILE%" echo(!line!
            )
        )
    )
    move /y "%TMP_FILE%" "%CONFIG_FILE%" >nul
)

REM Cập nhật comment trong file public key
if exist "%SSH_DIR%\!NEW_NAME!.pub" (
    for /f "usebackq tokens=1,2" %%X in ("%SSH_DIR%\!NEW_NAME!.pub") do (
        > "%SSH_DIR%\!NEW_NAME!.pub.tmp" echo %%X %%Y !NEW_NAME!
    )
    if exist "%SSH_DIR%\!NEW_NAME!.pub.tmp" (
        move /y "%SSH_DIR%\!NEW_NAME!.pub.tmp" "%SSH_DIR%\!NEW_NAME!.pub" >nul
    )
)

call :MSG_OK "Đã đổi tên key: !EDIT_KEY_NAME! -> !NEW_NAME!"
call :PAUSE_MANAGE_KEY
goto MANAGE_KEY

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
    call :MSG_ERROR "Không có SSH key nào."
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

:SHOW_HOSTS_TABLE
call :BOX "BẢNG HOST TRONG CONFIG"
echo.
echo   ╔══════╦══════════════════════════════════════╦════════════════╗
echo   ║  STT ║ ALIAS                                ║ HOSTNAME       ║
echo   ╠══════╬══════════════════════════════════════╬════════════════╣
set /a HOST_COUNT=0
for /f "usebackq tokens=1,* delims= " %%A in ("%CONFIG_FILE%") do (
    if /i "%%A"=="Host" (
        if /i not "%%B"=="*" if /i not "%%B"=="?" (
            set /a HOST_COUNT+=1
            set "HOST!HOST_COUNT!=%%B"
            call :PAD_TRUNC "%%B" 36 HOST_DISP
            call :GET_HOSTNAME_BY_ALIAS "%%B" HOST_NAME_DISP
            call :PAD_TRUNC "!HOST_NAME_DISP!" 14 HOSTNAME_DISP
            call :PAD_TRUNC "!HOST_COUNT!" 4 HC_DISP
            echo   ║ !HC_DISP! ║ !HOST_DISP! ║ !HOSTNAME_DISP! ║
        )
    )
)
echo   ╚══════╩══════════════════════════════════════╩════════════════╝
if !HOST_COUNT! EQU 0 (
    color 0C
    echo   (Chưa có host nào)
    color 0B
)
echo.
exit /b 0

:GET_HOSTNAME_BY_ALIAS
set "alias=%~1"
set "outvar=%~2"
set "%outvar%="
set "found=0"
for /f "usebackq delims=" %%L in ("%CONFIG_FILE%") do (
    set "line=%%L"
    REM Loại bỏ khoảng trắng đầu dòng
    for /f "tokens=1,* delims= 	" %%X in ("!line!") do (
        set "keyword=%%X"
        set "value=%%Y"
    )
    if "!found!"=="1" (
        if /i "!keyword!"=="HostName" (
            set "%outvar%=!value!"
            set "found=0"
            exit /b 0
        )
        REM Nếu gặp block Host khác thì dừng
        if /i "!keyword!"=="Host" (
            set "found=0"
        )
    )
    if /i "!keyword!"=="Host" if /i "!value!"=="%alias%" (
        set "found=1"
    )
)
if not defined %outvar% set "%outvar%=(không rõ)"
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
set "blank_buf=0"

for /f "tokens=1* delims=:" %%A in ('findstr /n "^" "%CONFIG_FILE%"') do (
    set "line=%%B"
    if "!line!"=="" (
        if "!skip!"=="0" set /a blank_buf+=1
    ) else (
        if /i "!line:~0,5!"=="Host " (
            set "cur=!line:~5!"
            if /i "!cur!"=="%target%" (
                set "skip=1"
                set "blank_buf=0"
            ) else (
                set "skip=0"
            )
        )
        if "!skip!"=="0" (
            call :WRITE_BLANKS !blank_buf!
            set "blank_buf=0"
            >> "%TMP_FILE%" echo(!line!
        ) else (
            set "blank_buf=0"
        )
    )
)

move /y "%TMP_FILE%" "%CONFIG_FILE%" >nul
exit /b 0

:WRITE_BLANKS
for /l %%i in (1,1,%~1) do >> "%TMP_FILE%" echo.
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

:MSG_OK
color 0A
echo.
echo   [THÀNH CÔNG] %~1
color 0B
exit /b 0

:MSG_ERROR
color 0C
echo.
echo   [LỖI] %~1
color 0B
exit /b 0

:MSG_WARN
color 0E
echo.
echo   [CẢNH BÁO] %~1
color 0B
exit /b 0

:MSG_INFO
color 0D
echo.
echo   [THÔNG TIN] %~1
color 0B
exit /b 0

:PAD_TRUNC
set "str=%~1"
set "width=%~2"
set "outvar=%~3"
set "%outvar%=%str%                                                                                                    "
set "%outvar%=!%outvar%:~0,%width%!"
exit /b 0
