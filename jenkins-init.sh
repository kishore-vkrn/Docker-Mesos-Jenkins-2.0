#!/bin/bash

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  echo "Copying init scripts"
  mkdir -p $JENKINS_HOME/init.groovy.d
  #find /usr/share/jenkins/init.groovy.d/ -type f -exec cp {} $JENKINS_HOME/init.groovy.d/ \;

  #echo "Copying plugins"
  #mkdir -p $JENKINS_HOME/plugins
  #find /usr/share/jenkins/plugins/ -type f -exec cp {} $JENKINS_HOME/plugins/ \;

  chown -R jenkins:jenkins $JENKINS_HOME
  if [[ -z "$@" ]]; then
    exec su jenkins -c "/usr/local/bin/jenkins.sh"
  else
    PARAMS="$@"
    exec su jenkins -c "/usr/local/bin/jenkins.sh \"$PARAMS\""
  fi
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
