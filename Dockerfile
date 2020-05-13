FROM balenalib/raspberry-pi2

RUN [ "cross-build-start" ]

RUN apt-get update && apt-get upgrade -y

ENV MONGODB_VERSION 3.2.22

RUN apt-get install -y wget \
 && wget https://fastdl.mongodb.org/src/mongodb-src-r${MONGODB_VERSION}.tar.gz \
 && tar zxf mongodb-src-r${MONGODB_VERSION}.tar.gz

RUN apt-get install -y scons build-essential \
    libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-thread-dev \
    python-pymongo

#RUN cd mongodb-src-r${MONGODB_VERSION} \
 #&& ls -alF src/third_party/mozjs-38/ \
 #&& cat src/third_party/mozjs-38/get_sources.sh \
 #&& cat src/third_party/mozjs-38/gen-config.sh

RUN python --version

RUN cd mongodb-src-r${MONGODB_VERSION} \
 && cd src/third_party/mozjs-38/ \
 && ./get_sources.sh

RUN apt-get install -y python-dev

ENV SHELL /bin/bash

RUN cd mongodb-src-r${MONGODB_VERSION} \
 && cd src/third_party/mozjs-38/ \
 && ./gen-config.sh arm linux 

RUN sed -i '188s/(Pred::/Pred::/' mongodb-src-r${MONGODB_VERSION}/src/third_party/boost-1.56.0/boost/mpl/assert.hpp \
 && sed -i '190s/)//' mongodb-src-r${MONGODB_VERSION}/src/third_party/boost-1.56.0/boost/mpl/assert.hpp \
 && sed -i '193s/(boost::mpl::not_<Pred>::/boost::mpl::not_<Pred>::/' mongodb-src-r${MONGODB_VERSION}/src/third_party/boost-1.56.0/boost/mpl/assert.hpp \
 && sed -i '195s/)//' mongodb-src-r${MONGODB_VERSION}/src/third_party/boost-1.56.0/boost/mpl/assert.hpp

# An upcoming version of glibc intends to stop including sys/sysmacros.h automatically with sys/type.h
RUN sed -i '35i#include <sys/sysmacros.h>' mongodb-src-r${MONGODB_VERSION}/src/mongo/db/storage/paths.h

RUN cd mongodb-src-r${MONGODB_VERSION} \
 && scons mongod --wiredtiger=off --mmapv1=on --disable-warnings-as-errors

RUN cd mongodb-src-r${MONGODB_VERSION} \
 && scons mongo --wiredtiger=off --mmapv1=on --disable-warnings-as-errors

RUN [ "cross-build-end" ]  

