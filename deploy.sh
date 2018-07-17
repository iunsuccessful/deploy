
### soft location
GRADLE_HOME=/usr/local/gradle
export SERVER_HOME=/usr/local/tomcat
export JAVA_HOME=/usr/local/java

### environment

APP_BRANCH=master
# APP_NAME=$1
APP_NAME=api-exam
GIT_URL=https://github.com/iunsuccessful/api-exam.git

APPS_BASE_HOME=$HOME/apps
ROJECT_SOURCE_DIR=$APPS_BASE_HOME/$APP_NAME
ROJECT_SOURCE_BRANCH_DIR=$ROJECT_SOURCE_DIR/$APP_BRANCH
WEB_APP_HOME=$ROJECT_SOURCE_BRANCH_DIR/web/target

export CATALINA_HOME=$SERVER_HOME
export CATALINA_BASE=$HOME/$APP_NAME/.tomcat

DEPLOY_HOME=$(cd `dirname $0`; pwd)

################################ Update source code & package ####################
package(){

    ###update source code

	echo "package 1"
	
	## always remove old code 
    echo " start to remove existed src folder:  $ROJECT_SOURCE_BRANCH_DIR "
    rm -rf  $ROJECT_SOURCE_BRANCH_DIR
	
	echo "package 2"
    
    echo "[INFO] git clone -b $APP_BRANCH $GIT_URL $APP_BRANCH"

    if [ ! -d "$APPS_BASE_HOME" ]; then
        echo "[INFO] make APPS_BASE_HOME :" $APPS_BASE_HOME
        mkdir $APPS_BASE_HOME
    fi
    if [ ! -d "$ROJECT_SOURCE_DIR" ]; then
        echo "[INFO] make ROJECT_SOURCE_DIR :" $ROJECT_SOURCE_DIR
        mkdir $ROJECT_SOURCE_DIR
    fi

    cd $ROJECT_SOURCE_DIR
    git clone -b $APP_BRANCH $GIT_URL $APP_BRANCH

    echo "copy config file to source..."
    # cp -rf $WEB_APP_HOME/classes/server.xml $CATALINA_BASE/conf/server.xml
    cp ~/application.properties $ROJECT_SOURCE_BRANCH_DIR/src/main/resources

    ###package app
    echo "[INFO] start to package application..."
    echo "current path is " `pwd`
    echo "result cmd is $GRADLE_HOME/bin/gradle build"
    cd $ROJECT_SOURCE_BRANCH_DIR
    $GRADLE_HOME/bin/gradle build
    echo "[INFO] package application finish."

}

### sent to remote

remote() {
    echo "Deploy home $DEPLOY_HOME"
	. $DEPLOY_HOME/app-iptable.sh
	app_ips=${APP_NAME//-/_}_ips
    echo "[INFO] app_ips = ${app_ips[*]}"
    for var in `eval echo \\${$app_ips[@]}`; do
        if [ $var = "localhost" ]; then
            echo "sh $CATALINA_BASE/tomcat.sh"
            sh $CATALINA_BASE/tomcat.sh $APP_NAME $CATALINA_HOME $CATALINA_BASE
        else
            sync ${var%#*} ${var#*#}
        fi
    done
}

sync() {
    echo "scp -r $HOME/$APP_NAME $1:$HOME/."
    sshpass -p $2 scp -o StrictHostKeyChecking=no -r $HOME/$APP_NAME $1:$HOME/.
    echo "sh $CATALINA_BASE/tomcat.sh $APP_NAME $CATALINA_HOME $CATALINA_BASE"
    sshpass -p $2 ssh $1 "sh $CATALINA_BASE/tomcat.sh $APP_NAME $CATALINA_HOME $CATALINA_BASE"
}

### stop tomcat

get_tomcat_pid(){    
    STR=`ps -C java -f --width 1000 | grep "$APP_NAME"|awk '{print $2}'`           
    echo $STR
}

stop_tomcat(){
    TOMCAT_JAVA_PID=`get_tomcat_pid`
    if [ ! -z "$TOMCAT_JAVA_PID" ] ; then
        echo -e "[INFO] kill java process $TOMCAT_JAVA_PID .\c"      
        kill -9 $TOMCAT_JAVA_PID > /dev/null 2>&1
        echo "Kill tomcat Oook!"
    else
        echo "[WARN] $HOST_NAME: tomcat not running, who care?"
    fi
}

################################################################
##check if started before
check_server(){
    java_pid=`ps  --no-heading -C java -f --width 1000 | grep "$$CATALINA_BASE" |awk '{print $2}'`
    if [ ! -z "$java_pid" ]; then
        echo "[INFO] Tomcat server already started: pid=$java_pid"
        exit;
    fi
}

copy_server_home(){
    if [ -d "$CATALINA_BASE" ]; then
        rm -rf $CATALINA_BASE
    fi
    mkdir -p $CATALINA_BASE/conf
    mkdir -p $CATALINA_BASE/webapps
	mkdir -p $CATALINA_BASE/logs
	mkdir -p $CATALINA_BASE/temp
	touch $CATALINA_BASE/logs/catalina.out
}

copy_tomcat_conf(){
    echo "cp -rf $CATALINA_HOME/conf/. $CATALINA_BASE/conf/."
    cp -rf $CATALINA_HOME/conf/. $CATALINA_BASE/conf/.
    echo "cp -rf $WEB_APP_HOME/classes/server.xml $CATALINA_BASE/conf/server.xml"
    cp -rf $WEB_APP_HOME/classes/server.xml $CATALINA_BASE/conf/server.xml
    echo "cp -rf $DEPLOY_HOME/tomcat.sh $CATALINA_BASE/tomcat.sh"
    cp -rf $DEPLOY_HOME/tomcat.sh $CATALINA_BASE/tomcat.sh
}

copy_war(){
    # cp -r $WEB_APP_HOME/$APP_NAME-war $CATALINA_BASE/webapps
    if [ ! -d "$CATALINA_BASE/webapps/ROOT" ]; then
        echo "[INFO] make ROOT :" $CATALINA_BASE/webapps/ROOT
        mkdir $CATALINA_BASE/webapps/ROOT
    fi
    cp -rf $WEB_APP_HOME/$APP_NAME/. $CATALINA_BASE/webapps/ROOT/.
}

deploy_to_tomcat(){
    # check_server
    copy_server_home
    copy_tomcat_conf
    copy_war
}



main(){
    package
    # stop_tomcat
	deploy_to_tomcat
    remote
    
	# $CATALINA_HOME/bin/catalina.sh start > /dev/null
	# tail -f $CATALINA_BASE/logs/catalina.out
}

main
