#!/bin/bash
# For the first user (creates a new file)
htpasswd -c -B -b users.htpasswd user1 password

# To add another user to an existing file
htpasswd -B -b users.htpasswd user2 password