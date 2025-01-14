FROM buildpack-deps:bionic

SHELL ["/bin/bash", "-c"]
ARG DEBIANFRONTEND=noninteractive

USER root

ARG user=jenkinsagent
ARG group=jenkinsagent
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d /var/${user} -u ${uid} -g ${gid} -m ${user}

RUN apt-get update && \
	# To get latest version of git
	apt-get install -y software-properties-common && \
	add-apt-repository -y ppa:git-core/ppa && \
	apt-get update && \
	apt-get install -y \
	git \
	jq \
	# Because of jenkins/slave
	openjdk-8-jdk \
	# Required to run Docker daemon in entrypoint 
	supervisor \
	# Required to go back to jenkins user in entrypoint
	gosu \
	# Required to run Docker in Docker
	iptables \
	xz-utils \
    rsync \
	btrfs-progs

# Because of jenkins/slave
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
	apt-get install -y git-lfs

RUN curl -fsSL https://get.docker.com | sh && \
	usermod --append --groups docker ${user}

RUN rm -rf /var/lib/apt/lists/*

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN set -x \
	&& addgroup --system dockremap \
	&& adduser --system --ingroup dockremap dockremap \
	&& echo 'dockremap:165536:65536' >> /etc/subuid \
	&& echo 'dockremap:165536:65536' >> /etc/subgid

ENV DIND_COMMIT 3b5fac462d21ca164b3778647420016315289034

RUN wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" \
	&& chmod +x /usr/local/bin/dind

VOLUME /var/lib/docker

ARG AGENT_WORKDIR=/var/${user}/agent

RUN REMOTING_URL="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting" && \
	VERSION=$(curl -fsS ${REMOTING_URL}/maven-metadata.xml | grep "<latest>.*</latest>" | sed -e "s#\(.*\)\(<latest>\)\(.*\)\(</latest>\)\(.*\)#\3#g") && \
	curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar ${REMOTING_URL}/${VERSION}/remoting-${VERSION}.jar \
	&& chmod 755 /usr/share/jenkins \
	&& chmod 644 /usr/share/jenkins/agent.jar \
	&& ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /var/${user}/.jenkins && mkdir /var/${user}/.docker && mkdir -p ${AGENT_WORKDIR}
COPY dockerconfig.json /var/${user}/.docker/config.json

VOLUME /var/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /var/${user}

USER root

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "/bin/bash" ]
