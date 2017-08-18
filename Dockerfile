FROM ubuntu:14.04
MAINTAINER Max I. Shaposhnikoff <max@shaposhnikoff.info>
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN sed -i 's%archive.ubuntu.com%ua.archive.ubuntu.com%' /etc/apt/sources.list
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
ENV GRADLE_VERSION 3.3
ENV GRADLE_SHA c58650c278d8cf0696cab65108ae3c8d95eea9c1938e0eb8b997095d5ca9a292

RUN apt-get update && \
        apt-get -y install software-properties-common curl unzip python-software-properties sudo git jq dnsutils iputils-ping

RUN add-apt-repository -y ppa:webupd8team/java

RUN apt-get update
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
RUN apt-get -y install oracle-java8-installer

#ENV JAVA_HOME=/srv/java/jdk \
#    PATH=${PATH}:/srv/java/jdk/bin:/srv/java



RUN cd /usr/lib \
 && curl -fl https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle-bin.zip \
 && echo "$GRADLE_SHA gradle-bin.zip" | sha256sum -c - \
 && unzip "gradle-bin.zip" \
 && ln -s "/usr/lib/gradle-${GRADLE_VERSION}/bin/gradle" /usr/bin/gradle \
 && rm "gradle-bin.zip"

# Set Appropriate Environmental Variables
ENV GRADLE_HOME /usr/lib/gradle
ENV PATH $PATH:$GRADLE_HOME/bin

# Install Deps
RUN dpkg --add-architecture i386 && apt-get update \
    && apt-get install -y --force-yes expect wget \
    libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1

# Install Android SDK
RUN cd /opt && wget --output-document=android-sdk.tgz --quiet \
    http://dl.google.com/android/android-sdk_r24.3.3-linux.tgz \
    && tar xzf android-sdk.tgz && rm -f android-sdk.tgz \
    && chown -R root.root android-sdk-linux

# Setup environment
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install sdk elements
COPY tools /opt/tools
ENV PATH ${PATH}:/opt/tools
RUN ["/opt/tools/android-accept-licenses.sh", \
    "android update sdk --all --force --no-ui --filter platform-tools,tools,build-tools-25,build-tools-25.0.2,android-25,addon-google_apis_x86-google-25,extra-android-support,extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,sys-img-armeabi-v7a-android-25"]

COPY licenses /opt/android-sdk-linux/licenses 

# Cleaning
RUN apt-get clean

# Go to workspace
RUN mkdir -p /opt/workspace
WORKDIR /opt/workspace

