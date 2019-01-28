
@echo Starting...
@set log_file="D:\Program Files\XX-Net-3.13.1\data\gae_proxy\ipv6_tunnel.log"

@echo Config servers...
@call:[config servers]>>%log_file%

@echo Reset IPv6...
@call:[reset ipv6]>>%log_file%

@echo Set IPv6 Tunnel...
@call:[set ipv6]>>%log_file%

@call:[print state]>>%log_file%

@echo Over
@echo Reboot system at first time!
@pause
exit


:[config servers]
sc config RpcEptMapper start= auto
sc start RpcEptMapper

sc config DcomLaunch start= auto
sc start DcomLaunch

sc config RpcSs start= auto
sc start RpcSs

sc config nsi start= auto
sc start nsi

sc config Winmgmt start= auto
sc start Winmgmt

sc config Dhcp start= auto
sc start Dhcp

sc config WinHttpAutoProxySvc start= auto
sc start WinHttpAutoProxySvc

sc config iphlpsvc start= auto
sc start iphlpsvc

goto :eof


:[reset ipv6]
netsh interface ipv6 reset
ipconfig /flushdns
goto :eof


:[set ipv6]
:: Reset Group Policy Teredo
"D:\Program Files\XX-Net-3.13.1\code\default\python27\1.0\pythonw.exe" "D:\Program Files\XX-Net-3.13.1\code\default\gae_proxy\local\ipv6_tunnel\win_reset_gp.py"


netsh interface teredo set state type=enterpriseclient servername=win1711.ipv6.microsoft.com.

:: Set IPv6 prefixpolicies
:: See https://tools.ietf.org/html/rfc3484
:: 2002::/16 6to4 tunnel
:: 2001::/32 teredo tunnel; not default
netsh interface ipv6 add prefixpolicy ::1/128 50 0
netsh interface ipv6 set prefixpolicy ::1/128 50 0
netsh interface ipv6 add prefixpolicy ::/0 40 1
netsh interface ipv6 set prefixpolicy ::/0 40 1
netsh interface ipv6 add prefixpolicy 2002::/16 30 2
netsh interface ipv6 set prefixpolicy 2002::/16 30 2
netsh interface ipv6 add prefixpolicy 2001::/32 25 5
netsh interface ipv6 set prefixpolicy 2001::/32 25 5
netsh interface ipv6 add prefixpolicy ::/96 20 3
netsh interface ipv6 set prefixpolicy ::/96 20 3
netsh interface ipv6 add prefixpolicy ::ffff:0:0/96 10 4
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 10 4

:: Fix look up AAAA on teredo
:: http://technet.microsoft.com/en-us/library/bb727035.aspx
:: http://ipv6-or-no-ipv6.blogspot.com/2009/02/teredo-ipv6-on-vista-no-aaaa-resolving.html
Reg add HKLM\SYSTEM\CurrentControlSet\services\Dnscache\Parameters /v AddrConfigControl /t REG_DWORD /d 0 /f

:: Enable all IPv6 parts
Reg add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters /v DisabledComponents /t REG_DWORD /d 0 /f

goto :eof


:[print state]
:: Show state
ipconfig /all
netsh interface ipv6 show teredo
netsh interface ipv6 show route
netsh interface ipv6 show interface
netsh interface ipv6 show prefixpolicies
netsh interface ipv6 show address
route print
goto :eof
