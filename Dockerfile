# Kasm Workspaces desktop image with Vivaldi, Anytype, RustDesk, VS Code and Claude.
#
# Built on Kasm's own "core" image, which provides KasmVNC, the XFCE desktop,
# audio/upload/download/printing plumbing and the startup scripts Kasm expects.
# Override BASE_IMAGE / BASE_TAG at build time to target a different Ubuntu release, e.g.
#   docker build --build-arg BASE_IMAGE=core-ubuntu-resolute --build-arg BASE_TAG=develop .
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_TAG="1.19.0-rolling-weekly"
FROM kasmweb/${BASE_IMAGE}:${BASE_TAG}

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=$STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

COPY src/install/ $INST_SCRIPTS/custom/

# GitHub token is optional; it only avoids API rate limits when looking up
# the latest Anytype and RustDesk releases.
RUN --mount=type=secret,id=github_token,required=false \
    bash $INST_SCRIPTS/custom/install_apps.sh \
    && bash $INST_SCRIPTS/custom/desktop_shortcuts.sh \
    && rm -rf $INST_SCRIPTS/custom

######### End Customizations ###########

RUN chown 1000:0 $HOME \
    && $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000
