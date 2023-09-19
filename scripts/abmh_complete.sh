#!/bin/bash

_domainname_1()
{
        if [ "${#COMP_WORDS[@]}" != "2" ]; then
                return
        fi
        COMPREPLY=`virsh list --name --all`
}

_imaganame_1()
{
        if [ "${#COMP_WORDS[@]}" != "3" ]; then
                return
        fi
        COMPREPLY=( $(compgen -W "jammy lunar bookworm") )
}


complete -r snapshot-new.sh addauthorized_key.sh create_machine.sh

complete -F _domainname_1 snapshot-new.sh addauthorized_key.sh

complete -F _imaganame_1 create_machine.sh
