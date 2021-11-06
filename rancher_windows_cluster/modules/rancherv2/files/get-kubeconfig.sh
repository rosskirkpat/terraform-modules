#!/bin/bash

file=/etc/rancher/k3s/k3s.yaml
while [ ! -f "$file" ]
do
    inotifywait -qqt 2 -e create -e moved_to "$(dirname $file)"
done
cat /etc/rancher/k3s/k3s.yaml