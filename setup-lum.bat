@echo off
REM ============================================
REM  ЛЮМ: настройка резервного доступа к ПК Никиты
REM  Запусти ПРАВОЙ КНОПКОЙ -> "Запуск от имени администратора"
REM ============================================
echo [1/6] Чиню DNS (8.8.8.8 / 1.1.1.1)...
netsh interface ipv4 add dnsservers name="Ethernet" address=8.8.8.8 index=1 >nul 2>&1
netsh interface ipv4 add dnsservers name="Ethernet" address=1.1.1.1 index=2 >nul 2>&1
netsh interface ipv4 add dnsservers name="Wi-Fi" address=8.8.8.8 index=1 >nul 2>&1
netsh interface ipv4 add dnsservers name="Wi-Fi" address=1.1.1.1 index=2 >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo    готово.
echo.
echo [2/6] Включаю WinRM (удалённое управление PowerShell)...
powershell -NoProfile -Command "Enable-PSRemoting -Force -SkipNetworkProfileCheck" >nul 2>&1
netsh advfirewall firewall delete rule name="WinRM-HTTP" >nul 2>&1
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985
echo    готово.
echo.
echo [3/6] Устанавливаю OpenSSH-сервер (резервный SSH)...
powershell -NoProfile -Command "Get-WindowsCapability -Online -Name OpenSSH.Server* | Add-WindowsCapability -Online" >nul 2>&1
powershell -NoProfile -Command "Set-Service sshd -StartupType Automatic; Start-Service sshd" >nul 2>&1
echo    готово.
echo.
echo [4/6] Открываю порты 22 и 445 в брандмауэре...
netsh advfirewall firewall delete rule name="SSH-22" >nul 2>&1
netsh advfirewall firewall add rule name="SSH-22" dir=in action=allow protocol=TCP localport=22
netsh advfirewall firewall delete rule name="SMB-445" >nul 2>&1
netsh advfirewall firewall add rule name="SMB-445" dir=in action=allow protocol=TCP localport=445
echo    готово.
echo.
echo [5/6] Добавляю SSH-ключ Люма (для входа без пароля)...
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDz6cxaI5irSGmG70EBEULbtV7XjvPGy2dAjNxPfnRY4 lum@roman >> "%USERPROFILE%\.ssh\authorized_keys"
REM Ключ для администраторов (особый путь в Windows OpenSSH)
if exist "C:\ProgramData\ssh" (
  echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDz6cxaI5irSGmG70EBEULbtV7XjvPGy2dAjNxPfnRY4 lum@roman >> "C:\ProgramData\ssh\administrators_authorized_keys"
  icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" "SYSTEM:F" >nul 2>&1
)
echo    готово.
echo.
echo [6/6] Проверяю службы...
powershell -NoProfile -Command "Get-Service sshd -ErrorAction SilentlyContinue | Select-Object Name,Status" 
echo.
echo ============================================
echo  ВСЕ ГОТОВО! Можно закрыть окно.
echo ============================================
pause