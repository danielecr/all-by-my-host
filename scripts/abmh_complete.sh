#!/bin/bash

_domainname_1()
{
        if [ "${#COMP_WORDS[@]}" != "2" ]; then
                return
        fi
        COMPREPLY=`virsh list --name --all`
}

complete -F _domainname_1 snapshot-new.sh
