FROM ubuntu

ADD https://github.com/Yelp/dumb-init/releases/download/v1.0.2/dumb-init_1.0.2_amd64 /usr/bin/dumb-init

RUN chmod +x /usr/bin/dumb-init
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates wget curl apt-transport-https software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sL https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | bash && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update -y && \
    apt-get install -y docker-ce gitlab-runner && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/ayufan/gitlab-ci-multi-runner/master/dockerfiles/ubuntu/entrypoint /
RUN chmod +x /entrypoint

VOLUME ["/etc/gitlab-runner", "/home/gitlab-runner"]
ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
