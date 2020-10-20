ARG IDOL_VERSION
ARG REGISTRY

FROM ${REGISTRY}/community:${IDOL_VERSION}

ARG COMMUNITY_CFG=community.cfg
ARG LDAP_SERVER
ARG LDAP_PORT
ARG LDAP_RDN_ATTRIBUTE
ARG LDAP_BASE_DN
ARG LDAP_PASSWORD
ARG LDAP_GROUP
ARG SECURITYINFOKEYS
ARG DOCUMENT_SECURITY_TYPE=NT_V4

COPY ${COMMUNITY_CFG} /community/cfg/community.cfg

RUN sed -i "s/XX_LDAP_SERVER_XX/${LDAP_SERVER}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_LDAP_PORT_XX/${LDAP_PORT}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_LDAP_GROUP_XX/${LDAP_GROUP}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_LDAP_BASE_DN_XX/${LDAP_BASE_DN}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_LDAP_BASE_DN_PASSWORD_XX/${LDAP_PASSWORD}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_LDAP_RDN_ATTRIBUTE_XX/${LDAP_RDN_ATTRIBUTE}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_SECURITYINFOKEYS_XX/${SECURITYINFOKEYS}/g" /community/cfg/community.cfg \
  && sed -i "s/XX_DOCUMENT_SECURITY_TYPE_XX/${DOCUMENT_SECURITY_TYPE}/g" /community/cfg/community.cfg
