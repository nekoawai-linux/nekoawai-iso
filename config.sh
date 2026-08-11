#!/bin/bash

set -euxo pipefail

systemctl enable NetworkManager.service
systemctl enable getty@tty1.service
systemctl disable sshd.service 2>/dev/null || :
systemctl set-default multi-user.target
