#!/bin/bash 

############################################################################
#
# This is the startup script for starting the graphana dashboard and the 
# kdb process
#
############################################################################

############################################################################
#     DEFINING ENVIRONMENT VARIABLES
############################################################################

export HOME=""
echo "SET HOME to $HOME"

export GRAFANA_CFG="$HOME/"
echo "SET GRAFANA_CFG to $GRAFANA_CFG"

export QSCRIPT="$HOME/"
echo "SET QSCRIPT to $QSCRIPT"

export GRAFANALOC=""
echo "SET GRAFANALOC to $GRAFANALOC"

export QLOG="$HOME/"
echo "SET QLOG to $QLOG"

export QLOC=""
echo "SET QLOC to $QLOC"

export QLIC=""
echo "SET QLIC to $QLIC"

export QHOME=""
echo "SET QHOME to $QHOME"

export RLWRAP=""
echo "SET RLWRAP to $RLWRAP"

############################################################################
#     STARTING COMPONENTS
############################################################################

echo "Starting the kdb process ..."
nohup $RLWRAP $QLOC $QSCRIPT -p 7777 > $QLOG/q_script_proc.log 2>&1 &

echo "Starting grafana server ..."
sudo systemctl daemon-reload
sudo systemctl start grafana-server
#sudo systemctl status grafana-server

