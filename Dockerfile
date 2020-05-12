ARG ALPINE_VERSION

FROM alpine:$ALPINE_VERSION

RUN apk update \
 && apk upgrade \
 && apk add --update openssl-dev dpkg-dev dpkg curl gcc g++ make autoconf ncurses-dev perl coreutils gnupg linux-headers zlib-dev

ENV LANG=en_US.UTF-8

ARG ERLANG_VERSION
ARG ELIXIR_VERSION

WORKDIR /tmp/erlang-build

RUN echo $ERLANG_VERSION; curl -fSL -o OTP-$ERLANG_VERSION.tar.gz https://github.com/erlang/otp/archive/OTP-$ERLANG_VERSION.tar.gz \
    && tar --strip-components=1 -zxf OTP-$ERLANG_VERSION.tar.gz \
    && rm OTP-$ERLANG_VERSION.tar.gz \
    && ./otp_build autoconf && \
        export ERL_TOP=/tmp/erlang-build && \
        export PATH=$ERL_TOP/bin:$PATH && \
        export CPPFlAGS="-D_BSD_SOURCE $CPPFLAGS" \
        && gnuArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
        && ./configure --build="$gnuArch" \
        --without-javac \
        --without-wx \
        --without-debugger \
        --without-observer \
        --without-jinterface \
        --without-cosEvent\
        --without-cosEventDomain \
        --without-cosFileTransfer \
        --without-cosNotification \
        --without-cosProperty \
        --without-cosTime \
        --without-cosTransactions \
        --without-et \
        --without-gs \
        --without-ic \
        --without-megaco \
        --without-orber \
        --without-percept \
        --without-typer \
        --enable-threads \
        --enable-shared-zlib \
        --enable-dirty-schedulers \
        --disable-dynamic-ssl-lib \
        --enable-ssl=/usr/lib \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install

 ## Elixir
 WORKDIR /tmp/elixir-build

 RUN set -xe \
     && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
     && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
     && tar --strip-components=1 -zxf elixir-src.tar.gz \
     && rm elixir-src.tar.gz \
     && make

FROM alpine:$ALPINE_VERSION AS alpine-elixir

ENV LANG=en_US.UTF-8

COPY --from=0 /tmp/erlang-build /tmp/erlang-build
COPY --from=0 /tmp/elixir-build /tmp/elixir-build

RUN apk --no-cache update \
    && apk --no-cache upgrade \
    && apk --no-cache add make ncurses-libs perl binutils \
    && cd /tmp/erlang-build && ERL_TOP=/tmp/erlang-build make install \
    && cd /tmp/elixir-build && make install \
    && find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf \
    && find /usr/local -name src | xargs -r find | grep -v '\.hrl$' | xargs rm -v || true \
    && find /usr/local -name src | xargs -r find | xargs rmdir -vp || true \
    && scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all \
    && scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && rm -rf /tmp/erlang-build \
    && rm -rf /tmp/elixir-build \
    && apk --no-cache del perl binutils make \
    && rm -rf /var/lib/apt/lists/*

CMD ["iex"]
