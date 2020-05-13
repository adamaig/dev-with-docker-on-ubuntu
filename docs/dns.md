## DNS Tools on OSX

Source: https://superuser.com/a/1177211 (retrieved 2020-05-06)

> macOS has a sophisticated system for DNS request routing (“scoped queries”) in order to handle cases like VPN, where you might want requests for your work’s domain name to go down your VPN tunnel so that you get answers from your work’s internal DNS servers, which may have more/different information than your work’s external DNS servers.
>
> To see all the DNS servers macOS is using, and how the query scoping is set up, use: scutil --dns
>
> To query DNS the way macOS does, use: dns-sd -G v4v6 example.com or dns-sd -q example.com
>
> DNS-troubleshooting tools such as nslookup(1), dig(1), and host(1) contain their own DNS resolver code and don’t make use of the system’s DNS query APIs, so they don’t get the system behavior. If you don’t specify which DNS server for them to use, they will probably just use one of the ones listed in /etc/resolv.conf, which is >auto-generated and only contains the default DNS servers for unscoped queries.
>
> Traditional Unix command-line tools that aren’t specific to DNS, such as ping(8), probably call the traditional gethostbyname(3) APIs, which, on macOS, make use of the system’s DNS resolver behaviors.
>
> To see what your DHCP server told your Mac to use, look at the domain_name_server line in the output of: ipconfig getpacket en0

In order to clear the OSX dns cache

> sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache
