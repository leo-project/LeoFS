#!/usr/bin/bash

USER=leofs
GROUP=$USER
COMPONENT=leo_storage
DIR=/opt/local/$COMPONENT

case $2 in
    PRE-INSTALL)
        if grep "^$GROUP:" /etc/group > /dev/null 2>&1
        then
            echo "Group already exists, skipping creation."
        else
            echo Creating $GROUP group ...
            groupadd $GROUP
        fi
        if id $USER > /dev/null 2>&1
        then
            echo "User already exists, skipping creation."
        else
            echo Creating $USER user ...
            useradd -g $GROUP -d /var/db/leofs -s /bin/false $USER
        fi
        echo Creating directories ...
        mkdir -p /var/db/leofs
        chown -R $USER:$GROUP /var/db/leofs
        mkdir -p /var/db/$COMPONENT/snmp
        chown -R $USER:$GROUP /var/db/$COMPONENT
        mkdir -p /var/log/$COMPONENT/sasl
        chown -R $USER:$GROUP /var/log/$COMPONENT
        if [ -d /tmp/$COMPONENT ]
        then
            chown -R $USER:$GROUP /tmp/$COMPONENT/
        fi
        ;;
    POST-INSTALL)
        if svcs svc:/network/$COMPONENT:default > /dev/null 2>&1
        then
            echo Service already existings ...
        else
            echo Importing service ...
            svccfg import $DIR/share/$COMPONENT.xml
        fi
        echo Trying to guess configuration ...
        IP=`ifconfig net0 | grep inet | awk -e '{print $2}'`
        if [ ! -f $DIR/etc/leo_storage.conf ]
        then
            cp $DIR/etc/leo_storage.conf.example $DIR/etc/leo_storage.conf
            sed --in-place -e "s/127.0.0.1/${IP}/g" $DIR/etc/leo_storage.conf
        fi
        ;;
esac
