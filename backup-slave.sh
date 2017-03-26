#!/bin/bash

coproc mysql {
        mysql -hdbslave.dhgiang.internal -ubackup 
}

echo 'FLUSH TABLES WITH READ LOCK;' >&"${mysql[1]}"
echo 'SET GLOBAL read_only = ON;' >&"${mysql[1]}"
ssh root@dbslave.dhgiang.internal xfs_freeze -f /
/root/snapshot backup
ssh root@dbslave.dhgiang.internal xfs_freeze -u /
echo 'SET GLOBAL read_only = OFF;' >&"${mysql[1]}"
echo 'UNLOCK TABLES;' >&"${mysql[1]}"