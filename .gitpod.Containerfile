# docker build --no-cache --progress=plain -f .gitpod.Dockerfile .
FROM gitpod/workspace-full

# System
RUN bash -c "sudo apt-get update"
RUN bash -c "sudo install-packages direnv gettext mysql-client gnupg golang"
RUN bash -c "sudo pip install --upgrade pip"

# Aliyun CLI
RUN bash -c "brew install aliyun-cli"
