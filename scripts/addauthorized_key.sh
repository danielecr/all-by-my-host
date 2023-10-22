#!/bin/bash
most_recent_id="$(cd "$HOME" ; ls -t .ssh/id*.pub 2>/dev/null | grep -v -- '-cert.pub$' | head -n 1)"

MACHINE=$1
KEY=`cat $HOME/$most_recent_id`

virsh qemu-agent-command --domain $MACHINE '{"execute":"guest-ssh-add-authorized-keys","arguments":{"username":"ubuntu","keys":["'$KEY'"]}}'

cat <<EOF | tee -a ~/.ssh/config
Host $MACHINE
  User ubuntu
EOF
echo "# added to ~/.ssh/config"
