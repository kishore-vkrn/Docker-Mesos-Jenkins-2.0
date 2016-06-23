FROM ubuntu:14.04
MAINTAINER Kishore Ramanan

# Expose Ports for web access and slave agents
EXPOSE 8080
EXPOSE 50000

# Update & Install common packages
RUN apt-get update && apt-get install -y wget git curl zip && apt-get install -y software-properties-common libsvn1

# Install a basic SSH server
RUN apt-get install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd

######################################################## BUILD TOOLS #########################################################
# GIT
#####
RUN apt-get install -y git

# JAVA
############
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# MAVEN
#######
ENV MAVEN_VERSION 3.3.3
RUN mkdir -p /usr/share/maven \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# Define MAVEN_HOME
ENV MAVEN_HOME /usr/share/maven

########################################################### JENKINS  ###########################################################
ENV JENKINS_VERSION 2.0
##########################
RUN mkdir -p /usr/share/jenkins
RUN curl -fsSL http://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war -o /usr/share/jenkins/jenkins.war
RUN chmod 644 /usr/share/jenkins/jenkins.war

# Jenkins Variables
ENV JENKINS_HOME /var/jenkins
ENV JENKINS_PLUGINS_LOCAL $JENKINS_HOME/plugins
ENV JENKINS_UC http://jenkins-updates.cloudbees.com
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log
ENV JAVA_OPTS="-Xmx8192m"
ENV JENKINS_OPTS="--handlerCountMax=300"

# Create Directories
RUN mkdir -p /usr/share/jenkins/ref/
RUN mkdir -p $JENKINS_HOME
RUN mkdir -p $JENKINS_PLUGINS_LOCAL
RUN touch $JENKINS_HOME/copy_reference_file.log
COPY jenkins.sh /usr/local/bin/jenkins.sh

ADD http://downloads.mesosphere.io/master/debian/7/mesos_0.21.1-1.0.debian77_amd64.deb /tmp/mesos.deb

RUN dpkg -i /tmp/mesos.deb && rm /tmp/mesos.deb

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

ADD jenkins-init.sh /usr/local/bin/jenkins-init.sh

VOLUME ["/var/jenkins"]

ENTRYPOINT ["/usr/local/bin/jenkins-init.sh"]
