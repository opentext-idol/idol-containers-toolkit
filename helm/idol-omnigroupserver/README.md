# idol-omnigroupserver

Provides an IDOL OmniGroupServer deployment

Whilst this can be deployed 'as-is', it is expected that a real deployment will
require configuration particular to the repositories the OGS instance needs to
provide user/group information for.

Consumers of this chart are encouraged to use this as a subchart, providing an
additional config-map with the OGS config file - see .Values.existingConfigMap
