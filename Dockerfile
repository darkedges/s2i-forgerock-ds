# Binary extract
FROM alpine:3.17.2 as installFile
ARG FRDS_ARCHIVE=DS-7.2.0.zip
ARG FRDS_ARCHIVE_REPOSITORY_URL=

ADD ${FRDS_ARCHIVE_REPOSITORY_URL}${FRDS_ARCHIVE}  /var/tmp/frds.zip

RUN unzip /var/tmp/frds.zip -d /var/tmp/

# Runtime deployment
ARG JRE_IMAGE=darkedges/s2i-forgerock-jvm
ARG JRE_TAG=11.0.18_10-jre-alpine
ARG FORGEROCK_VERSION=7.2.0

FROM darkedges/s2i-forgerock-jvm:11.0.18_10-jre-alpine as base

LABEL io.k8s.description="$DESCRIPTION" \
    io.k8s.display-name="ForgeRock $FORGEROCK_VERSION" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,forgerock,forgerock-ds-$FORGEROCK_VERSION" \
    com.redhat.deployments-dir="/opt/app-root/src" \
    com.redhat.dev-mode="DEV_MODE:false" \
    com.redhat.dev-mode.port="DEBUG_PORT:5858" \
    maintainer="Nicholas Irving <nirving@darkedges.com>" \
    summary="$SUMMARY" \
    description="$DESCRIPTION" \
    version="$FORGEROCK_VERSION" \
    name="darkedges/s2i-forgerock-ds" \
    usage="s2i build . darkedges/s2i-forgerock-ds myapp"

COPY --from=0 /var/tmp/opendj /opt/frds/
COPY contrib/ /opt/frds/

RUN apk add --no-cache tini bash curl jq && \
    fix-permissions /opt/frds && \
    chown -R default:root /opt/frds

USER 1001

COPY ./s2i/ $STI_SCRIPTS_PATH

EXPOSE 1389 1636 4444 8443

# Set the default CMD to print the usage
CMD ${STI_SCRIPTS_PATH}/usage