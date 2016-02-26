#!/bin/bash
#
# This file is part of Hypertable.
#
# Hypertable is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 3 of the
# License, or any later version.
#
# Hypertable is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

# The installation directory
export HYPERTABLE_HOME=$(cd `dirname "$0"`/.. && pwd)
. $HYPERTABLE_HOME/bin/ht-env.sh

if [ "e$RUNTIME_ROOT" == "e" ]; then
  RUNTIME_ROOT=$HYPERTABLE_HOME
fi

usage() {
  echo
  echo "usage: ht-wait-until-quiesced.sh [OPTIONS]"
  echo
  echo "OPTIONS:"
  echo "  -h,--help             Display usage information"
  echo "  -i,--interval <sec>   Dump interval (default = 300)"
  echo
  echo "This script is used to wait for Hypertable to become quiet (i.e. quiesce)",
  echo "so that the system integrity can be checked and/or repaired with the",
  echo "'htck' tool."
  echo
  echo "The content of the sys/METADATA table is repeatedly dumped into the file"
  echo "'metadata.tsv' in the current working directory, with a wait between"
  echo "each successive dump.  Once the content of sys/METADATA does not change"
  echo "between two successive dumps, the script returns with exit status 0."
  echo
  echo "Once this script exits, it is an indication that all background activity"
  echo "(e.g. split and compaction) has stopped.  At this point Hypertable can be"
  echo "shut down and the 'htck' program can be run, using the 'metadata.tsv'"
  echo "file generated by this script, to check and/or repair system integrity."
  echo
  echo "NOTE: Hypertable should not be under any load when running this script."
  echo "If there is any load (esp. inserts) while this script is run, the system"
  echo "may not quiesce, or the 'metadata.tsv' file generated by this script may"
  echo "become inconsistent with the state of the database prior to a subsequent"
  echo "run of 'htck'.  If this happens, 'htck' will not work properly and could"
  echo "report false corruption or cause corruption when run in repair mode."
  echo
}

let INTERVAL=300

while [ $# -gt 0 ]; do
  case $1 in
    -h|--help)
      usage;
      exit 0
      ;;
    -i|--interval)
      shift
      if [ $# -eq 0 ]; then
        usage;
        exit 0
      fi
      let INTERVAL=$1
      shift
      ;;
    *)
      usage;
      exit 0
      ;;
  esac
done

oldsum=""
while true; do
  echo "use sys; select * from METADATA revs 1;" | $HYPERTABLE_HOME/bin/ht shell --batch > metadata.tsv
  sum=`md5sum metadata.tsv`
  echo $sum
  [ "$oldsum" = "$sum" ] && break
  sleep $INTERVAL
  oldsum=$sum
done

echo -e '\a'
sleep 1
echo -e '\a'
sleep 1
echo -e '\a'

exit 0
