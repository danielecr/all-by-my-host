#!/bin/bash

_domainname_1()
{
        if [ "${#COMP_WORDS[@]}" != "2" ]; then
                return
        fi
        COMPREPLY=( $(compgen -W "$(virsh list --name --all)" "${COMP_WORDS[1]}") )
}

_imaganame_1()
{
        if [ "${#COMP_WORDS[@]}" != "3" ]; then
                return
        fi
        COMPREPLY=( $(compgen -W "jammy lunar bookworm" "${COMP_WORDS[2]}") )
}


complete -r snapshot-new.sh addauthorized_key.sh create_machine.sh

complete -F _domainname_1 snapshot-new.sh addauthorized_key.sh

complete -F _imaganame_1 create_machine.sh
