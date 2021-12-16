FROM ubuntu:20.04
MAINTAINER "Shauli Mizrahi" shauli@hellorep.ai
RUN sudo wget https://raw.githubusercontent.com/shaulirep/rep-live-chat/master/deployment/setup_20.04.sh -O setup.sh
RUN chmod 755 setup.sh
RUN sudo ./setup.sh master


EXPOSE 3000
EXPOSE 3035
