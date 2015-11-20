FROM alpine:3.2
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN \
  REQUIRED_PACKAGES="libyaml mercurial openssh" \
  && BUILD_PACKAGES="ca-certificates openssl wget" \

  && USERID_ON_HOST=1026 \

  && adduser -D -G users -g Mercurial -s /bin/sh -u $USERID_ON_HOST hg \
  && passwd -u hg \

  && apk add --update-cache \
    --repository http://dl-2.alpinelinux.org/alpine/edge/testing/\
    $REQUIRED_PACKAGES \
    $BUILD_PACKAGES \

  && ssh-keygen -A \
  && printf "%s\n" \
    "AllowAgentForwarding no" \
    "AllowTcpForwarding no" \
    "AllowUsers hg" \
    "PasswordAuthentication no" \
    "PermitRootLogin no" \
    "Port 2222" \
    "StrictModes no" \
    "UseDNS no" \
    >> /etc/ssh/sshd_config \

  && mkdir -p /app/ \
  && wget \
    --output-document /app/hgssh3.py \
    --quiet \
    https://bitbucket.org/painfulcranium/hgssh3/raw/default/hgssh3.py \
  && chmod 755 /app/hgssh3.py \

  && wget \
    --output-document - \
    --quiet \
    https://raw.github.com/pypa/pip/master/contrib/get-pip.py \
    | python \
  && pip install \
    watchdog \

  && wget \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document - \
      --quiet \
    | tar xz -C / \

  && mkdir -p /etc/services.d/sshd/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "exec /usr/sbin/sshd -D -e" \
    > /etc/services.d/sshd/run \
  && chmod +x /etc/services.d/sshd/run \

  && apk del \
    $BUILD_PACKAGES \
  && rm -rf /tmp/* /var/cache/apk/* /var/tmp/*

ENTRYPOINT ["/init"]
EXPOSE 2222

# docker build --rm --tag ptb2/mercurial .
# docker run --detach --name mercurial --net host \
#   --publish 2222:2222/tcp \
#   --volume /volume1/@appstore/Mercurial:/home/hg/.ssh:ro \
#   --volume /volume1/Media:/home/media \
#   ptb2/mercurial

# Details: https://bitbucket.org/painfulcranium/hgssh3/src

# authorized_keys:
# command="/app/hgssh3.py USERNAME /home/hg/.ssh/hgssh3.conf" ssh-rsa ABCDEFG...

# hgssh3.conf:
# [music]
# location = /home/media/Music
# USERNAME = write

# hgrc:
# [extensions]
# largefiles =
# [hooks]
# changegroup = hg update
# [largefiles]
# minsize = 1

# hg clone ssh://hg@example.com:2222/music
