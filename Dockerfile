FROM ashish1981/multiarch-r-plugins
ARG CRAN
SHELL ["/bin/bash", "-c"]
RUN source /root/setenv.sh 
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    CRAN=${CRAN:-https://cran.rstudio.com}

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y 


## Don't require a password for sudo
RUN sed -i 's/^\(%sudo.*\)ALL$/\1NOPASSWD:ALL/' /etc/sudoers
## Add a library directory (for user-installed packages)
RUN chmod g+ws /usr/local/lib/R/site-library \
    ## Fix library path
    && sed -i '/^R_LIBS_USER=.*$/d' /usr/local/lib/R/etc/Renviron \
    && echo "R_LIBS_USER=\${R_LIBS_USER-'/usr/local/lib/R/site-library'}" >> /usr/local/lib/R/etc/Renviron \
    && echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron \
    ## Set configured CRAN mirror
    && echo CRAN=$CRAN >> /etc/environment \
    && echo "options(repos = c(CRAN='$CRAN'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site 

## Create shiny user with empty password (will have uid and gid 1000)
RUN useradd --create-home --shell /bin/bash shiny \
    && passwd shiny -d \
    && adduser shiny sudo \
    && cp /root/setenv.sh /home/shiny/ \
    && chmod +x /home/shiny/setenv.sh \
    && chown -R shiny.shiny /usr/local/lib/R/site-library \
    && source /home/shiny/setenv.sh
################################################
#################  Shiny Server   ##############
################################################
RUN cd /home/shiny \
    # && git clone https://github.com/rstudio/shiny-server.git 
    && git clone https://github.com/Ashish1981/shiny-server.git 

COPY install-node.sh /home/shiny/shiny-server/external/node/

COPY shiny-build.sh /tmp/shiny-build.sh

RUN  chmod a+x /tmp/shiny-build.sh \
    && chmod a+x /home/shiny/shiny-server/external/node/install-node.sh \
    && ./tmp/shiny-build.sh

