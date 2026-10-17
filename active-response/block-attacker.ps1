# Wazuh active-response script (Windows) - block a brute-force attacker's IP.
#
# Wazuh's execd pipes the full triggering alert (JSON) to this script on stdin.
# We read that alert, pull the attacker's source IP out of it, and create a
# Windows Firewall rule that blocks all inbound traffic from that IP.
#
# Triggered by: rule 60204 (Multiple Windows Logon Failures) -> MITRE T1110.
# Logs every run to block-events.log so the action is auditable.

$ErrorActionPreference = "SilentlyContinue"

# Read the whole alert that Wazuh sent on stdin
$raw = [Console]::In.ReadToEnd()

$log = "C:\Program Files (x86)\ossec-agent\active-response\block-events.log"
$ts  = (Get-Date).ToString("s")

# Extract the attacker IP from the alert JSON (data.win.eventdata.ipAddress)
$ip = $null
if ($raw -match '"ipAddress"\s*:\s*"([^"]+)"') { $ip = $matches[1] }

# add = block / delete = unblock (Wazuh sends the command in the alert envelope)
$cmd = "add"
if ($raw -match '"command"\s*:\s*"delete"') { $cmd = "delete" }

# Audit trail: how much data we received, which command, which IP we parsed
Add-Content -LiteralPath $log "$ts rawlen=$($raw.Length) cmd=$cmd ip=$ip"

if ($ip) {
  if ($cmd -eq "add") {
    netsh advfirewall firewall add rule name="WAZUH-BLOCK-$ip" dir=in action=block remoteip=$ip | Out-Null
    Add-Content -LiteralPath $log "$ts BLOCKED $ip"
  } else {
    netsh advfirewall firewall delete rule name="WAZUH-BLOCK-$ip" | Out-Null
    Add-Content -LiteralPath $log "$ts UNBLOCKED $ip"
  }
}
