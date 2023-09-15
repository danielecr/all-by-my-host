#!/bin/bash

DOMAIN=$1
SNAPNAME=$2

NOW=`date -Iseconds`

## The date is already in the xml, but this was a wrong idea that new I want to leave here

virsh snapshot-create-as --domain $DOMAIN --disk-only --quiesce --description "$NOW" $SNAPNAME