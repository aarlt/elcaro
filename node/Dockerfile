FROM python:alpine AS builder

RUN apk add build-base libffi-dev openssl-dev ca-certificates
RUN pip install --upgrade pip

ADD src /elcaro
RUN pip install -r /elcaro/requirements.txt

RUN pip install pylxd

FROM python:alpine

COPY --from=0 /elcaro /elcaro

COPY init/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages

RUN apk add go-ipfs geth libffi su-exec tini-static openssl lxc bash

ENTRYPOINT ["/sbin/tini-static", "--", "/usr/local/bin/entrypoint.sh"]
# ENTRYPOINT ["/sbin/tini-static", "--", "/bin/bash"]

