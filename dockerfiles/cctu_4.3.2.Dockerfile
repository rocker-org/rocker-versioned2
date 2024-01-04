FROM rocker/verse

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Simon Bond <sjb277@medschl.cam.ac.uk>"

ENV CCTU_VERSION=V0.7.6

#Should only be temporary until r-ver.4.3.2.DOckerfile is run as this copies all the scripts to the image folder.
COPY scripts/install_cctu.sh /rocker_scripts/install_cctu.sh

RUN /rocker_scripts/install_cctu.sh
