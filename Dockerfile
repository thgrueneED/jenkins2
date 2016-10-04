FROM registry.access.redhat.com/rhel7:latest

# Jenkins image for OpenShift
#
# This image provides a Jenkins server, primarily intended for integration with
# OpenShift v3.
#
# Volumes: 
# * /var/jenkins_home
# Environment:
# * $JENKINS_PASSWORD - Password for the Jenkins 'admin' user.

MAINTAINER Ben Parees <bparees@redhat.com>, Aleksandar Lazic <aleksandar.lazic@cloudwerkstatt.com

# latest lts
# http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war
# the version dir is
# http://mirrors.jenkins-ci.org/war-stable/2.7.4/jenkins.war

ENV JENKINS_VERSION=2.7.4 \
    HOME=/var/lib/jenkins \
    JENKINS_HOME=/var/lib/jenkins \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    KUBERNETES_URL=http://updates.jenkins-ci.org/download/plugins/kubernetes/0.8/kubernetes.hpi \
    DUR_TASK_URL=http://updates.jenkins-ci.org/download/plugins/durable-task/1.12/durable-task.hpi \
    CRED_URL=http://updates.jenkins-ci.org/download/plugins/credentials/2.1.4/credentials.hpi \
    JENKINS_URL=http://mirrors.jenkins-ci.org/war-stable/2.7.4/jenkins.war
    

LABEL k8s.io.description="Jenkins is a continuous integration server" \
      k8s.io.display-name="Jenkins 2.7.4" \
      openshift.io.expose-services="8080:http" \
      openshift.io.tags="jenkins,jenkins2,ci" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

# Labels consumed by Red Hat build service
#LABEL BZComponent="openshift-jenkins-docker" \
#      Name="openshift3/jenkins-1-rhel7" \
LABEL Version="2.7.4" \
      Architecture="x86_64" \
      Release="8"

# 8080 for main web interface, 50000 for slave agents
EXPOSE 8080 50000

# RUN yum install -y yum-utils && \
#     yum clean all && \
#     yum repolist enabled

#orig packages
# INSTALL_PKGS="rsync gettext git tar zip unzip nss_wrapper java-1.8.0-openjdk atomic-openshift-clients jenkins jenkins-plugin-kubernetes jenkins-plugin-openshift-pipeline jenkins-plugin-credentials" && \
RUN yum clean all && \
    yum-config-manager --enable rhel-7-server-ose-3.2-rpms && \
    yum-config-manager --enable rhel-7-server-rpms && \
    yum repolist && \
    INSTALL_PKGS="rsync gettext git tar zip unzip java-1.8.0-openjdk-devel java-1.8.0-openjdk atomic-openshift-clients nss_wrapper which" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.UTF-8

COPY containerfiles/ /
# copied from jenkins1 from rh
# oc rsync jenkins-1-cz8p2:/usr/local/bin containerfiles/usr/local/
# COPY ./contrib/jenkins /usr/local/bin
# ADD ./contrib/s2i /usr/libexec/s2i

#    curl -sSo /opt/openshift/plugins/durable-task.hpi ${DUR_TASK_URL} && \
#    curl -sSo /opt/openshift/plugins/kubernetes.hpi ${KUBERNETES_URL} && \
#    curl -sSo /opt/openshift/plugins/credentials.hpi ${CRED_URL} && \
# NOTE: When adding new Jenkins plugin, you have to create the symlink for the
# HPI file created by rpm to /opt/openshift/plugins folder.
RUN mkdir -p /opt/openshift/plugins /var/lib/jenkins /usr/lib/jenkins && \
    curl -LsSo /usr/lib/jenkins/jenkins.war ${JENKINS_URL} && \
    # Prefer the latest version of the credentials plugin over the bundled
    # version.
    touch /opt/openshift/plugins/credentials.hpi.pinned && \
    chmod +x /usr/local/bin/fix-permissions && \
    chmod +x /usr/libexec/s2i/run && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /var/lib/jenkins

VOLUME ["/var/lib/jenkins"]

USER 1001
CMD ["/usr/libexec/s2i/run"]
