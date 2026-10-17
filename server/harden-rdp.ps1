# ============================================
#  Run INSIDE the Windows Server 2016 box - elevated PowerShell.
#  !! Keep your RDP session OPEN while this runs.
# ============================================
$ErrorActionPreference = 'SilentlyContinue'
$ts  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
$rdp = Join-Path $ts 'WinStations\RDP-Tcp'

# 1) RDP on + NLA + SSL
Set-ItemProperty $ts  -Name fDenyTSConnections    -Value 0 -Type DWord -Force
Set-ItemProperty $rdp -Name SecurityLayer         -Value 2 -Type DWord -Force
Set-ItemProperty $rdp -Name UserAuthentication    -Value 1 -Type DWord -Force
Set-ItemProperty $ts  -Name fSingleSessionPerUser -Value 1 -Type DWord -Force

# 2) Firewall داخل الويندوز. في Oracle السحابة هي البواب الحقيقي
#    (قيد قاعدة 3389 في Security List على IP بيتك) فهنفتح كل البروفايلات هنا.
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' |
    Set-NetFirewallRule -Profile Any -Enabled True
Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' |
    Set-NetFirewallRule -Enabled False

# 3) حساب الأدمن - الباسورد بيتكتب من الكيبورد ومش بيتخزن في الملف
New-LocalUser -Name 'srvadmin' -FullName 'RDP Admin' -PasswordNeverExpires $true -AccountNeverExpires
Add-LocalGroupMember -Group 'Administrators'       -Member 'srvadmin'
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'srvadmin'

# حساب Administrator المدمج يتقفل - الدخول ب srvadmin بس
Disable-LocalUser -Name 'Administrator'

# 4) Lockout: 5 محاولات غلط = قفل 30 دقيقة
auditpol /set /subcategory:'Account Lockout' /success:enable /failure:enable
net.exe accounts /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30

# 5) Windows Defender شغال
Set-MpPreference -DisableRealtimeMonitoring $false
Update-MpSignature

# 6) Windows Update ما يعيدش التشغيل تحتك
$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
New-Item -Path $wu -Force | Out-Null
Set-ItemProperty $wu -Name NoAutoRebootWithLoggedOnUsers -Value 1 -Type DWord -Force

Write-Host 'RDP hardened: NLA + SSL + lockout + srvadmin + Defender.' -ForegroundColor Green
Write-Host 'NEXT: test from another PC BEFORE closing:  mstsc <public-ip>  user srvadmin' -ForegroundColor Yellow
Write-Host 'THEN: restrict the Oracle Security List rule for 3389 to your home IP /32.'
