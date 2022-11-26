#!/bin/sh

iptables -A OUTPUT -m owner --gid-owner nonet -j DROP
ip6tables -A OUTPUT -m owner --gid-owner nonet -j DROP
