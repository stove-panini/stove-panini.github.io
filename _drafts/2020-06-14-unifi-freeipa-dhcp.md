---
title: Using UniFi's DHCP relay with ISC DHCPD and FreeIPA
---
In this scenario, we're dealing with two machines:

| dhcp.example.com | `10.0.7.2` |
| ipa.example.com  | `10.0.7.3` |

...and a few networks:

| Infra Network | `10.0.5.0/24`    |
| Lab Network   | `10.0.7.0/24`    |
| Home Network  | `192.168.1.0/24` |

Let's solve 2 problems:
1. How can we get our Unifi Security Gateway to use our dhcpd server?
2. How can we allow dhcpd to update DNS records in FreeIPA (aka Red Hat IdM)?

## DHCP Relay
First up, let's take a trip into our UniFi Controller. Go to _Settings > Advanced Features > Advanced Gateway Settings > DHCP > DHCP Relay_

Here, you'll add the IP for our DHCP server, `10.0.7.2`.

>**NOTE:** If you are currently using the USG's integrated DHCP, you need to set the _Listen and Transmit Port_ option to something other than `57`. Otherwise, the relay daemon will conflict with the DHCP daemon and fail to start. Consider `10057`.

Now, head over to _Settings > Networks_ and for each of our 
