@echo off
chcp 65001 >nul
title AI Config Backup
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0AIConfigBackup.ps1"
