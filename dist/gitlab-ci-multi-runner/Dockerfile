
##################################################
#                                                #
# DO NOT EDIT THIS FILE MANUALLY                 #
# AUTOMATICALLY CREATED WITH docker-builder.sh   #
#                                                #
##################################################
  

FROM whatwedo/base:latest
RUN apt-get update -y && \
curl -L https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/v9.1.0/binaries/gitlab-ci-multi-runner-linux-amd64 -o /usr/local/bin/gitlab-ci-multi-runner && \
echo '40ad33669a8831ab3c8959c09f8ca98ef4bc71ef  /usr/local/bin/gitlab-ci-multi-runner' | shasum -c - && \
chmod +x /usr/local/bin/gitlab-ci-multi-runner && \
curl -L https://github.com/docker/machine/releases/download/v0.11.0/docker-machine-Linux-x86_64 -o /usr/local/bin/docker-machine && \
echo '2ccef0d442a5484c7279b85f501f27741507084c  /usr/local/bin/docker-machine' | shasum -c - && \
chmod +x /usr/local/bin/docker-machine && \
useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash && \
echo "rm -rf /root/.docker/machine/certs" >> /bin/everyboot
COPY files/supervisord/gitlab-ci-multi-runner.conf /etc/supervisor/conf.d/gitlab-ci-multi-runner.conf
RUN apt-get autoremove -y && \
apt-get clean -y && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
VOLUME /etc/gitlab-runner
LABEL ch.whatwedo.image.base="whatwedo/gitlab-ci-multi-runner"
