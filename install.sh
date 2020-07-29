set -o xtrace
set -o errexit
set -o pipefail

cd oracleScrips
source env.sh

pwd
mkdir -p $ORACLE_BASE/
mkdir -p $INSTALL_DIR/
cp env.sh $RUN_FILE $START_FILE $CREATE_DB_FILE $CONFIG_RSP $CHECK_DB_FILE $USER_SCRIPTS_FILE $ORACLE_BASE/
# check whether LINUX.X64_193000_db_home.zip exists in $INSTALL_DIR
FILE=/tmp/$INSTALL_FILE_1
if test -f "$FILE"; then
    echo "$FILE exist"
    mv $FILE $INSTALL_DIR/
else
  echo "$FILE doesn't exist"
  exit 1
fi

cp $INSTALL_RSP $INSTALL_DIR/

./$CHECK_SPACE_FILE
./$SETUP_LINUX_FILE

chown oracle:oinstall -R $INSTALL_DIR

sudo -u oracle bash -c "./$INSTALL_DB_BINARIES_FILE $DB_EDITION"

$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh

#helath check after Oracle is running
# sudo -u oracle bash -c "$ORACLE_BASE/$CHECK_DB_FILE"

