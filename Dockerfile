FROM python:slim

RUN apt-get update
RUN apt-get install --no-install-recommends build-essential wget \
	curl git autoconf libtool libssl-dev gettext \
	libpcre3-dev libev-dev asciidoc xmlto automake \
	libc-ares-dev libmbedtls-dev libsodium-dev -y

WORKDIR /dep
RUN wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
RUN tar xzvf LATEST.tar.gz
RUN cd libsodium* && ./configure && make -j8 && make install
RUN echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf && ldconfig

RUN export MBEDTLS_VER=2.16.5 && \
	wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz && \
	tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz && \
	cd mbedtls-$MBEDTLS_VER && \
	make SHARED=1 CFLAGS="-O2 -fPIC" && \
	make DESTDIR=/usr install && \
	ldconfig

RUN git clone https://github.com/shadowsocks/shadowsocks-libev.git
RUN cd shadowsocks-libev && \
	git submodule update --init --recursive && \
	./autogen.sh && ./configure && make -j8 && \
	make install

RUN git clone https://github.com/shadowsocks/simple-obfs.git
RUN cd simple-obfs && \
	git submodule update --init --recursive && \
	./autogen.sh && \
	./configure && make -j8 &&\
	make install

RUN curl -L -o go.sh https://install.direct/go.sh
RUN chmod +x go.sh && ./go.sh

RUN rm -rf *

WORKDIR /app
COPY . .
RUN cp /usr/bin/v2ray/* /app/clients/v2ray-core/
RUN pip install -r requirements.txt

VOLUME ["/app/results"]
EXPOSE 10870
ENTRYPOINT [ "python", "web.py" ]
