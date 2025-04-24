@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title Menu Hẹn Giờ Tắt Máy
color 0a

:menu
cls
echo =============================================
echo           MENU HẸN GIỜ TẮT MÁY
echo =============================================
echo.
echo  0. Xóa hẹn giờ shutdown
echo  1. Hẹn giờ shutdown
echo.
set /p choice="Nhập lựa chọn của bạn: "

if "%choice%"=="0" goto cancel_timer
if "%choice%"=="1" goto set_timer

goto menu

:set_timer
cls
echo =============================================
echo           HẸN GIỜ TẮT MÁY
echo =============================================
echo.
set /p seconds="Nhập số giây cần hẹn giờ: "

REM Kiểm tra đầu vào phải là số
set "numbers=0123456789"
echo %seconds%| findstr /r "^[%numbers%]*$" >nul
if errorlevel 1 (
    echo.
    echo Vui lòng chỉ nhập số!
    timeout /t 2 >nul
    goto set_timer
)

REM Tính toán thời gian sẽ tắt máy
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set /a "total_seconds=(%%a*3600 + %%b*60 + %%c)+%seconds%"
    set /a "hour=(!total_seconds!/3600)%%24"
    set /a "minute=(!total_seconds!%%3600)/60"
    set /a "second=!total_seconds!%%60"
)

REM Tính toán thời gian sẽ tắt máy (phụ)
set /a "total_seconds1=%seconds%"
set /a "hour1=(!total_seconds1!/3600)%%24"
set /a "minute1=(!total_seconds1!%%3600)/60"
set /a "second1=!total_seconds1!%%60"

echo Máy tính sẽ tắt sau: %hour1% giờ %minute1% phút %second1% giây.
echo Thời gian sẽ tắt: %hour%:%minute%:%second%.
echo.
echo Xác nhận lệnh tắt máy:
echo 0 = Hủy
echo 1 = Xác nhận
set /p confirm="Lựa chọn của bạn: "

if "%confirm%"=="1" (
    REM Hủy lệnh cũ (nếu có) trước khi tạo lệnh mới
    shutdown /a >nul 2>&1
    echo.
    shutdown /s /t %seconds%
    echo.
    echo Đã thiết lập hẹn giờ tắt máy thành công!
) else (
    echo.
    echo Đã hủy thao tác hẹn giờ!
)
timeout /t 1 >nul
goto menu

:cancel_timer
shutdown /a >nul 2>&1
echo Đã xóa lệnh hẹn giờ tắt máy (nếu có).
timeout /t 2 >nul
goto menu
