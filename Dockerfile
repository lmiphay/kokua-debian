FROM debian:stretch

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN \
	apt-get --yes update && \
	apt-get --yes upgrade

RUN \
	apt-get --yes install --install-recommends make g++ gdb python2.7 python-pip && \
	apt-get --yes install --install-recommends libgl1-mesa-dev libglu1-mesa-dev libstdc++6 libx11-dev libxinerama-dev libxml2-dev libxrender-dev

# off piste from here:
RUN apt-get --yes install libxrandr-dev libxcursor-dev libxcomposite-dev libxcb-shm0 sudo

# backports installs: cmake >=3.13.2 (default 3.7.2), git >=2.20.1 (default 2.11.0)
# Note - must run "apt-get update" after adding stretch-backports
RUN echo "deb http://deb.debian.org/debian stretch-backports main" >/etc/apt/sources.list.d/stretch-backports.list \
 && apt-get --yes update \
 && apt-get --yes -t stretch-backports install --install-recommends cmake git

RUN pip install autobuild

RUN \
	apt-get install -y systemd \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
	rm -f /lib/systemd/system/multi-user.target.wants/* \
	/etc/systemd/system/*.wants/* \
	/lib/systemd/system/local-fs.target.wants/* \
	/lib/systemd/system/sockets.target.wants/*udev* \
	/lib/systemd/system/sockets.target.wants/*initctl* \
	/lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
	/lib/systemd/system/systemd-update-utmp*

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]
