FROM rocker/rstudio:latest

# set up multiple users
COPY scripts/experimental/batch_user_creation.sh /rocker_scripts/experimental/batch_user_creation.sh

# https://stackoverflow.com/questions/46797348/docker-cmd-exec-form-for-multiple-command-execution
CMD [ "sh", "-c", "/rocker_scripts/experimental/batch_user_creation.sh && /init" ]