FROM rocker/rstudio:latest

# Script for to set up multiple users
COPY scripts/experimental/batch_user_creation.sh /rocker_scripts/experimental/batch_user_creation.sh

CMD [ "sh", "-c", "/rocker_scripts/experimental/batch_user_creation.sh && /init" ]
