FROM centos:7

MAINTAINER James Eckersall <james.eckersall@gmail.com>

# Var for first config
# Server Name
ENV \
  SESSIONNAME="Ark Docker" \
  SERVERMAP="TheIsland" \
  SERVERPASSWORD="" \
  ADMINPASSWORD="adminpassword" \
  NBPLAYERS=70 \
  UPDATEONSTART=1 \
  BACKUPONSTART=1 \
  BRANCH=master \
  SERVERPORT=27015 \
  STEAMPORT=7778

# Install dependencies
RUN \
  yum-config-manager --add-repo=http://negativo17.org/repos/epel-steam.repo && \
  yum-config-manager --add-repo=http://negativo17.org/repos/epel-multimedia.repo && \
  yum install -y epel-release && \
  yum install -y curl git steam


# Run commands as the steam user
RUN \
  adduser --shell /bin/bash steam && \
  usermod -a -G root steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN \
  chmod 0770 /home/steam -R && \
  chmod 0777 /home/steam/run.sh && \
  mkdir -p /ark /home/steam/ark-server-tools

# We use the git method, because api github has a limit ;)
RUN git clone -b $BRANCH https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools/
# Install
WORKDIR /home/steam/ark-server-tools/tools
RUN \
  chmod +x install.sh && \
  ./install.sh steam && \
  ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

# Define default config file in /ark
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

RUN chown steam -R /ark && chmod 0775 -R /ark

USER steam

# download steamcmd
RUN \
  mkdir /home/steam/steamcmd &&\
  cd /home/steam/steamcmd &&\
  curl http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar -vxz && \
  /home/steam/steamcmd/steamcmd.sh +login anonymous +quit

EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}

VOLUME /ark

# Change the working directory to /arkd
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/run.sh"]
