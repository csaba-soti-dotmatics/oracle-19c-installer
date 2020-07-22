#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Runs the Oracle Database inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -x

########### Move DB files ############
function moveFiles {

   if [ ! -d $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID ]; then
      mkdir -p $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   fi;

   mv $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   mv $ORACLE_HOME/dbs/orapw$ORACLE_SID $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   mv $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   mv $ORACLE_HOME/network/admin/listener.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   mv $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/

   # oracle user does not have permissions in /etc, hence cp and not mv
   cp /etc/oratab $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   
   symLinkFiles;
}

########### Symbolic link DB files ############
function symLinkFiles {

   if [ ! -L $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
   fi;
   
   if [ ! -L $ORACLE_HOME/dbs/orapw$ORACLE_SID ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID $ORACLE_HOME/dbs/orapw$ORACLE_SID
   fi;
   
   if [ ! -L $ORACLE_HOME/network/admin/sqlnet.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora
   fi;

   if [ ! -L $ORACLE_HOME/network/admin/listener.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/listener.ora $ORACLE_HOME/network/admin/listener.ora
   fi;

   if [ ! -L $ORACLE_HOME/network/admin/tnsnames.ora ]; then
      ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora
   fi;

   # oracle user does not have permissions in /etc, hence cp and not ln 
   cp $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab /etc/oratab

}


# Default for ORACLE SID
if [ "$ORACLE_SID" == "" ]; then
   export ORACLE_SID=ORCLCDB
else
  # Make ORACLE_SID upper case
  # Github issue # 984
  export ORACLE_SID=${ORACLE_SID^^}

  # Check whether SID is no longer than 12 bytes
  # Github issue #246: Cannot start OracleDB image
  if [ "${#ORACLE_SID}" -gt 12 ]; then
     echo "Error: The ORACLE_SID must only be up to 12 characters long."
     exit 1;
  fi;

  # Check whether SID is alphanumeric
  # Github issue #246: Cannot start OracleDB image
  if [[ "$ORACLE_SID" =~ [^a-zA-Z0-9] ]]; then
     echo "Error: The ORACLE_SID must be alphanumeric."
     exit 1;
   fi;
fi;

# Default for ORACLE PDB
export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}

# Make ORACLE_PDB upper case
# Github issue # 984
export ORACLE_PDB=${ORACLE_PDB^^}

# Default for ORACLE CHARACTERSET
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}

# Check whether database already exists
if [ -d $ORACLE_BASE/oradata/$ORACLE_SID ]; then
   symLinkFiles;
   
   # Make sure audit file destination exists
   if [ ! -d $ORACLE_BASE/admin/$ORACLE_SID/adump ]; then
      mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
   fi;
   
   # Do not Start database yet
   $ORACLE_BASE/$START_FILE;
   
else
  # Remove database config files, if they exist
  rm -f $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
  rm -f $ORACLE_HOME/dbs/orapw$ORACLE_SID
  rm -f $ORACLE_HOME/network/admin/sqlnet.ora
  rm -f $ORACLE_HOME/network/admin/listener.ora
  rm -f $ORACLE_HOME/network/admin/tnsnames.ora
   
  # Create database
  $ORACLE_BASE/$CREATE_DB_FILE $ORACLE_SID $ORACLE_PDB $ORACLE_PWD;
   
  # Move database operational files to oradata
  moveFiles;
   
  # Execute custom provided setup scripts
  $ORACLE_BASE/$USER_SCRIPTS_FILE $ORACLE_BASE/scripts/setup
fi;
