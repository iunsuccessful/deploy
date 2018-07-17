APP_NAME=$1
export CATALINA_HOME=$2
export CATALINA_BASE=$3

export JAVA_MEM_OPTS=" -server -Xms1024m -Xmx1024m -XX:SurvivorRatio=2 -XX:+UseParallelGC "
export JAVA_OPTS=" $JAVA_OPTS $JAVA_MEM_OPTS "

### point manager
open_jmx() {
    declare -A jvm_points
    # jvm_points=([azt-user]=7071 [azt-order]=7072 [azt-gateway]=7073 [azt-search]=7074)
    jvm_points=([azt-user]=7071)

    if [ ! -z ${jvm_points[$APP_NAME]} ]; then
       export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=${jvm_points[$APP_NAME]} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
       echo $CATALINA_OPTS
    fi
}


### stop tomcat

get_tomcat_pid(){    
    echo "get_tomcat_pid"
    STR=`ps -C java -f --width 1000 | grep "$APP_NAME"|awk '{print $2}'`           
    echo $STR
}

stop_tomcat(){
    echo "stop_tomcat"
    TOMCAT_JAVA_PID=`get_tomcat_pid`
    if [ ! -z "$TOMCAT_JAVA_PID" ] ; then
        echo -e "[INFO] kill java process $TOMCAT_JAVA_PID .\c"      
        kill -9 $TOMCAT_JAVA_PID > /dev/null 2>&1
        echo "Kill tomcat Oook!"
    else
        echo "[WARN] $HOST_NAME: tomcat not running, who care?"
    fi
}

##check if started before
check_server(){
    echo "check_server"
    java_pid=`ps  --no-heading -C java -f --width 1000 | grep "$APP_NAME" |awk '{print $2}'`
    if [ ! -z "$java_pid" ]; then
        echo "[INFO] Tomcat server already started: pid=$java_pid"
        exit;
    fi
}

main() {
    echo "$$1 $1 $2 $3"
    open_jmx
    stop_tomcat
    echo "$CATALINA_HOME/bin/catalina.sh start > /dev/null" 
	$CATALINA_HOME/bin/catalina.sh start > /dev/null
}

main
