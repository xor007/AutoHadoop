FROM centos:7
MAINTAINER F5061881

#!!!!!! add epel repos and switch on proxy
ADD etc/yum.repos.d/ambari.repo /etc/yum.repos.d/ambari.repo
ADD etc/yum.repos.d/hdp.repo /etc/yum.repos.d/hdp.repo
ADD etc/yum.repos.d/hdf.repo /etc/yum.repos.d/hdf.repo

RUN yum update -y && yum clean all

#Setting up systemd
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]
ENTRYPOINT ["/usr/sbin/init"]


RUN yum install -y policycoreutils systemd* && yum clean all

RUN yum install -y yum-utils yum-plugin-ovl tar git curl bind-utils unzip wget && yum clean all

# Setup sshd
RUN yum install -y net-tools openssh-server openssh-clients && yum clean all
RUN systemctl enable sshd

# kerberos client
RUN yum install -y krb5-workstation && yum clean all

# initscripts (service wrapper for servicectl) is need othewise the Ambari is unable to start postgresql
RUN yum install -y initscripts && yum clean all
RUN yum install -y ntp* && yum clean all

RUN yum install -y ambari-server

RUN curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq

# install Ambari specified 1.8 jdk
RUN mkdir -p /opt/java/ && ls -l /opt
ENV JDK_VERSION jdk1.8.0_152
ADD /opt/java/$JDK_VERSION /opt/java/jdk1.8
RUN ls -l /etc/yum.conf /opt/java/jdk1.8

ENV JAVA_HOME /opt/java/jdk1.8
ENV PATH $PATH:$JAVA_HOME/bin

RUN ssh-keygen -f /tmp/id_rsa -t rsa -N ''
#ADD host_rsa_pub /tmp/id_rsa.pub
#ADD host_rsa_priv /tmp/id_rsa
RUN mkdir /root/.ssh && cp /tmp/id_rsa* /root/.ssh/ && cat  /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa*

#RUN ambari-server setup -j $JAVA_HOME -s

#RUN chkconfig ntpd on; service ntpd start

#RUN timedatectl set-timezone Africa/Johannesburg 

ENV PS1 "[\u@docker-ambari \W]# "
