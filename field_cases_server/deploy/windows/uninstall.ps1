<# إيقاف وإزالة المهمة وقاعدة جدار الحماية. لا يحذف المجلد ولا قاعدة البيانات. #>
param([int]$Port = 8080)
Stop-ScheduledTask -TaskName "FieldCasesServer" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "FieldCasesServer" -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "FieldCases-$Port" -ErrorAction SilentlyContinue
Write-Host "أُوقف البرنامج. المجلد وقاعدة البيانات لم يُحذفا."
