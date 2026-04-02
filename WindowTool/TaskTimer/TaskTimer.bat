@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title TaskTimer Deluxe
color 0A

set "APP_NAME=TASKTIMER DELUXE"
set "APP_VER=2.0"
set "APP_AUTHOR=Copilot"

rem ============================================================
rem  MAIN MENU
rem ============================================================
:main
cls
call :header
echo   [1] Hẹn giờ Shutdown
echo   [2] Hẹn giờ Restart
echo   [3] Hẹn giờ Logoff
echo   [4] Hủy hẹn giờ hiện tại
echo   [5] Thoát
call :separator
set /p "choice=   Chọn chức năng: "

if "%choice%"=="1" (set "action=shutdown" & set "actionName=Shutdown" & goto choose_unit)
if "%choice%"=="2" (set "action=restart"  & set "actionName=Restart"  & goto choose_unit)
if "%choice%"=="3" (set "action=logoff"   & set "actionName=Logoff"   & goto choose_unit)
if "%choice%"=="4" goto cancel_timer
if "%choice%"=="5" exit /b
goto main

rem ============================================================
rem  HEADER
rem ============================================================
:header
echo.
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                    %APP_NAME%                                ║
echo   ║                 Hẹn giờ hệ thống tiện lợi                  ║
echo   ╚════════════════════════════════════════════════════════════╝
echo.
echo.
exit /b

:separator
echo   ────────────────────────────────────────────────────────────
exit /b

:pause_short
timeout /t 2 >nul
exit /b

:pause_long
timeout /t 3 >nul
exit /b

rem ============================================================
rem  CHOOSE TIME UNIT
rem ============================================================
:choose_unit
cls
call :header
echo   Chức năng: %actionName%
call :separator
echo   [1] Giây
echo   [2] Phút
echo   [3] Giờ
echo   [4] Quay lại menu
call :separator
set /p "unit=   Chọn đơn vị thời gian: "

if "%unit%"=="1" (set "multiplier=1" & set "unitName=giây"   & goto ask_value)
if "%unit%"=="2" (set "multiplier=60" & set "unitName=phút"   & goto ask_value)
if "%unit%"=="3" (set "multiplier=3600" & set "unitName=giờ" & goto ask_value)
if "%unit%"=="4" goto main
goto choose_unit

rem ============================================================
rem  ASK VALUE
rem ============================================================
:ask_value
cls
call :header
echo   Chức năng: %actionName%
echo   Đơn vị   : %unitName%
call :separator
set /p "value=   Nhập số %unitName%: "

if not defined value (
    echo.
    echo   [LỖI] Bạn chưa nhập giá trị.
    call :pause_short
    goto ask_value
)

echo(%value%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo.
    echo   [LỖI] Vui lòng nhập số nguyên dương.
    call :pause_short
    goto ask_value
)

if %value% LEQ 0 (
    echo.
    echo   [LỖI] Giá trị phải lớn hơn 0.
    call :pause_short
    goto ask_value
)

set /a "seconds=value*multiplier"
set /a "hh=seconds/3600"
set /a "mm=(seconds%%3600)/60"
set /a "ss=seconds%%60"

call :calc_target_time %seconds% targetTime

cls
call :header
echo   XÁC NHẬN THIẾT LẬP
call :separator
echo   Hành động        : %actionName%
echo   Thời gian        : %value% %unitName%
echo   Quy đổi          : !hh! giờ !mm! phút !ss! giây
echo   Dự kiến thực hiện: !targetTime!
call :separator
echo   [1] Xác nhận
echo   [0] Hủy
call :separator
set /p "confirm=   Lựa chọn: "

if "%confirm%"=="1" goto execute_task
if "%confirm%"=="0" goto main

echo.
echo   [LỖI] Lựa chọn không hợp lệ.
call :pause_short
goto ask_value

rem ============================================================
rem  EXECUTE TASK
rem ============================================================
:execute_task
shutdown /a >nul 2>&1

if /i "%action%"=="shutdown" (
    shutdown /s /t %seconds%
    set "actionText=Shutdown"
) else if /i "%action%"=="restart" (
    shutdown /r /t %seconds%
    set "actionText=Restart"
) else if /i "%action%"=="logoff" (
    set "actionText=Logoff"
)

cls
call :header
echo   ĐÃ THIẾT LẬP THÀNH CÔNG
call :separator
echo   Hành động : %actionText%
echo   Thời gian : %value% %unitName%
echo   Tổng giây  : %seconds%
echo   Dự kiến    : !targetTime!
call :separator

if /i "%action%"=="logoff" (
    echo   [INFO] Logoff sẽ thực hiện sau khi hết thời gian đếm ngược.
    echo.
    call :countdown %seconds% "logoff"
    goto do_logoff
) else (
    echo   [INFO] Hệ thống sẽ tự thực hiện lệnh sau khi hết đếm ngược.
    echo.
    call :countdown %seconds% "%action%"
    goto main
)

rem ============================================================
rem  COUNTDOWN
rem  %1 = seconds
rem  %2 = action type
rem ============================================================
:countdown
setlocal EnableDelayedExpansion
set /a remain=%~1

:count_loop
cls
echo.
echo   ╔════════════════════════════════════════════════════════════╗
echo   ║                     TASKTIMER DELUXE                       ║
echo   ╚════════════════════════════════════════════════════════════╝
echo.
echo   Đang chờ thực hiện: %actionName%
echo   Thời gian còn lại  : !remain! giây
echo.
echo   Nhấn Ctrl+C để dừng chương trình nếu cần.
echo.
if !remain! LEQ 0 goto end_count
timeout /t 1 /nobreak >nul
set /a remain-=1
goto count_loop

:end_count
endlocal
exit /b

rem ============================================================
rem  LOGOFF AFTER COUNTDOWN
rem ============================================================
:do_logoff
shutdown /l
exit /b

rem ============================================================
rem  CANCEL TIMER
rem ============================================================
:cancel_timer
cls
call :header
echo   HỦY HẸN GIỜ
call :separator
shutdown /a >nul 2>&1
echo   [OK] Đã hủy lệnh hẹn giờ hiện tại nếu có.
call :separator
call :pause_short
goto main

rem ============================================================
rem  CALC TARGET TIME
rem  %1 = seconds
rem  %2 = output variable
rem ============================================================
:calc_target_time
setlocal EnableDelayedExpansion
set "cur=%time%"
if "!cur:~0,1!"==" " set "cur=0!cur:~1!"

set /a curH=1!cur:~0,2!-100
set /a curM=1!cur:~3,2!-100
set /a curS=1!cur:~6,2!-100

set /a total=curH*3600 + curM*60 + curS + %~1

set /a th=(total/3600)%%24
set /a tm=(total%%3600)/60
set /a ts=total%%60

if !th! LSS 10 set "th=0!th!"
if !tm! LSS 10 set "tm=0!tm!"
if !ts! LSS 10 set "ts=0!ts!"

endlocal & set "%~2=%th%:%tm%:%ts%"
exit /b