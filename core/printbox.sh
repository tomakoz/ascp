#!/usr/bin/env bash

grep -R 'ERROR' ./log/printbox_sync_$(date +"%Y-%m-%d").log | awk -v FS="|" {'print $2;'} | grep -v 'printbox_sync' | sort -u > $_hash_lst
while read order_hash; do
  grep -R "${order_hash}" ./log/printbox_sync_$(date +"%Y-%m-%d").log | egrep '(Block|Cover)DstPath => ' | grep -v '_FORMAT_' | awk {'print $11;'} | sort -u | xargs -- ls -ld
done < $_hash_lst

