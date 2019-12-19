#!/usr/bin/env bash
set -e
source /assets/colorecho

echo_green "starting bash script $0 $@"

if [ ! -d "/opt/oracle/app/product/11.2.0/dbhome_1" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/install.sh
fi


chown -R oracle:oinstall /opt/oracle/dpdump/
su oracle -c "/assets/entrypoint_oracle.sh $1"

