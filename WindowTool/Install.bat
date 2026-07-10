@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=('%~dp0').TrimEnd('\'); $c=[Environment]::GetEnvironmentVariable('Path','User'); if($null -eq $c){$c=''}; if(($c -split ';') -notcontains $d){[Environment]::SetEnvironmentVariable('Path', ($c.TrimEnd(';').TrimStart(';')+';'+$d).Trim(';'),'User'); Write-Host ('Da them vao PATH: '+$d) -ForegroundColor Green} else {Write-Host ('Da co san trong PATH: '+$d) -ForegroundColor Yellow}"
echo.
echo Mo cmd MOI (PATH chi nap o session moi) roi go:  wTool
pause
