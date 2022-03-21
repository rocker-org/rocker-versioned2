# Tests for RStudio Server

## `scripts/experimental/batch_user_creation.sh`

### What does this implement/fix?

Batch creation of user accounts in RStudio server.

The script reads a list of username and password pairs from the `BATCH_USER_CREATION` enviroment variable
and uses this information to update a group of existing users when the container starts.
Each pair is of the format: `username:password` and is separated from the next by a semicolon `;`, with no intervening whitespace.

Usernames may only be up to 32 characters long (required by `useradd`) and by default the supplied passwords must be in clear-text
(later encrypted by `chpasswd`). If an username already exists, the script will deny that particular account creation request;
if not, the user account will be created, the login shell set to Bash and the user's home directory created,
if it does not exist.

By default, a group will be created for each new user with the same name as her username.
If the groupname already exists, the script will deny the group creation request.
If the password is not specified, it will be assumed that it is equals to the username.

All users will also be added to the `staff` group (same as default user).

A directory called `.rstudio/monitored/user-settings/user-settings` is created in that users home directory
to store RStudio initial preferences.

Users are not allowed to read other users' home directory.

#### How to test it?

1. Open a Terminal window (e.g., Bash) and build a docker image using the following command:

        docker build . -f tests/rstudio/batch-users.Dockerfile -t rocker/rstudio:batch-users

2. Then, start the container:

        docker run --rm -it -p 8787:8787 -e BATCH_USER_CREATION="user1:pass1;user2:pass2;user3:pass3" --name myrstudio rocker/rstudio:batch-users

    or,

        docker run --rm -it -p 8787:8787 --env-file tests/rstudio/env.batch-users01 --name myrstudio rocker/rstudio:batch-users

3. To get a list of all Linux users, enter the following command: `docker exec -it myrstudio getent passwd`.
