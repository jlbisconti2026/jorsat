#!/bin/bash

oc get groups -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -v "osenext01" | while read -r group; do
    [ -z "$group" ] && continue
    oc delete group "$group"
done
