FROM python:3.6-alpine



ENV PYTHONUNBUFFERED 1
ENV CHROME_BIN /usr/bin/chromium-browser
ENV CHROME_PATH /usr/lib/chromium/

RUN apk add --no-cache tini # Tini is now available at /sbin/tini

# Java

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apk add --no-cache --virtual .build-deps curl binutils \
    && GLIBC_VER="2.29-r0" \
    && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz" \
    && GCC_LIBS_SHA256="91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08" \
    && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" \
    && ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 \
    && curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" \
    && echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - \
    && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk \
    && apk add /tmp/glibc-${GLIBC_VER}.apk \
    && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk \
    && apk add /tmp/glibc-bin-${GLIBC_VER}.apk \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk \
    && apk add /tmp/glibc-i18n-${GLIBC_VER}.apk \
    && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
    && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
    && curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
    && echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c - \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz \
    && echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && apk del --purge .build-deps glibc-i18n \
    && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_VERSION jdk8u

RUN apk add --update openssl wget bash 

RUN set -eux; \
    apk add --virtual .fetch-deps curl; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='32b5f06fdaf7183a5b55b37ff4a88734c00e16b3e2c7ff42daecb96583e0841f'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-07-16-20-20/OpenJDK8U-jdk_aarch64_linux_hotspot_2019-07-16-20-20.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='a24e6e143a8eaf0b3a8477cac7555177d17667bf5e702db8adea7df8f9af837b'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-07-16-20-20/OpenJDK8U-jdk_ppc64le_linux_hotspot_2019-07-16-20-20.tar.gz'; \
         ;; \
       s390x) \
         ESUM='f8656a806527dfb4ca7e6590cb0de5da679cf4eb2cdbe92834c7e5b5ff3ac66d'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-07-16-20-20/OpenJDK8U-jdk_s390x_linux_hotspot_2019-07-16-20-20.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='9356e89f321cdfac35813875f93213c656016ea0c2c72994d60d9729472309fe'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-07-16-20-20/OpenJDK8U-jdk_x64_linux_hotspot_2019-07-16-20-20.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    apk del --purge .fetch-deps; \
    rm -rf /var/cache/apk/*; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:/opt/java/openjdk/jre/bin:$PATH"



# Before running spark , download spark from official site
# (https://www.apache.org/dyn/closer.lua/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz)
# currently 2.4.3 is latest

# Add directories to respective place in image    
ADD jars /opt/spark/jars
ADD bin /opt/spark/bin
ADD sbin /opt/spark/sbin
ADD kubernetes/dockerfiles/spark/entrypoint.sh /opt/
ADD examples /opt/spark/examples
ADD kubernetes/tests /opt/spark/tests
ADD data /opt/spark/data

# Adding requirements
ADD requirements.txt /requirements.txt

# Specifying dependencies that are needed for numpy,pandas
RUN set -ex \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
        libstdc++ \
        python3-dev \
        fontconfig \
        chromium \
        chromium-chromedriver \
    && apk add --no-cache --virtual .build-deps \
        g++ \
        gcc \
        make \
        libc-dev \
        libffi-dev \
        openssl-dev \
        ca-certificates \
        libxml2-dev \
        libxslt-dev \
        libjpeg-turbo-dev \
        zlib-dev  \
        musl-dev \
        linux-headers \
        pcre-dev \
        curl \
        git \
    && update-ca-certificates 2>/dev/null || true \
    && export PATH=$PATH:/usr/lib/chromium-browser \
    && pip3.6 install -U pip==9.0.3 \


    && pip3.6 install --no-cache-dir -r requirements.txt \
    && apk del .build-deps





# Setting environments
ENV SPARK_HOME /opt/spark

WORKDIR /opt/spark/work-dir

ENV PATH="/opt/spark/bin:${PATH}"

# most important file , if this won't work properly you will get driver-py not found in $PATH
# Default location on spark is kubernetes/dockerfiles/spark/entrypoint.sh in spark installation

ENTRYPOINT [ "/opt/entrypoint.sh" ]


    

