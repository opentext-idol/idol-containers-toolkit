ARG IDOL_VERSION
ARG REGISTRY

FROM ${REGISTRY}/omnigroupserver:${IDOL_VERSION}

ARG LDAP_SERVER
ARG LDAP_PORT
ARG LDAP_BASE
ARG LDAP_USERNAME
ARG LDAP_PASSWORD
ARG KEY_USERNAME
ARG KEY_GROUPNAME
ARG LDAP_MODE
ARG LDAP_GROUP_BASE
ARG USER_FILTER
ARG GROUP_FILTER
ARG AES_KEYFILE=aes.key

COPY omnigroupserver.cfg /omnigroupserver/cfg/original.omnigroupserver.cfg
COPY ${AES_KEYFILE} /omnigroupserver/aes.key

RUN sed -i "s/XX_LDAP_SERVER_XX/${LDAP_SERVER}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_LDAP_PORT_XX/${LDAP_PORT}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_LDAP_BASE_XX/${LDAP_BASE}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_LDAP_USERNAME_XX/${LDAP_USERNAME}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_LDAP_PASSWORD_XX/${LDAP_PASSWORD}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_KEY_USERNAME_XX/${KEY_USERNAME}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_KEY_GROUPNAME_XX/${KEY_GROUPNAME}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_LDAP_MODE_XX/${LDAP_MODE}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_LDAP_GROUP_BASE_XX/${LDAP_GROUP_BASE}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_USER_FILTER_XX/${USER_FILTER}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg \
  && sed -i "s/XX_GROUP_FILTER_XX/${GROUP_FILTER}/g" /omnigroupserver/cfg/original.omnigroupserver.cfg
