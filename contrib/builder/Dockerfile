
# docker build -t openldapbuild:latest .
# docker run -it openldapbuild:latest bash

FROM centos:8

MAINTAINER felipenoris <felipenoris@users.noreply.github.com>

WORKDIR /root

RUN yum update -y && yum install -y epel-release && yum clean all

RUN yum update -y && yum install -y \
    wget \
    gcc \
    make \
    libdb-devel \
    libtool-ltdl-devel \
    && yum clean all

RUN wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.50.tgz \
    && tar xf openldap-2.4.50.tgz \
    && cd openldap-2.4.50 \
    && ./configure \
    && make depend \
    && make

RUN mkdir libldap \
    && cp -r ./openldap-2.4.50/include ./libldap \
    && mkdir libldap/lib \
    && cp ./openldap-2.4.50/libraries/libldap/.libs/libldap.so ./libldap/lib \
    && cp ./openldap-2.4.50/libraries/liblber/.libs/liblber.so ./libldap/lib \
    && cp ./openldap-2.4.50/libraries/libldap_r/.libs/libldap_r.so ./libldap/lib
