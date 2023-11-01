# idol-find

Provides an IDOL Find UI, backed by a (single) Community and ViewServer instance.

Expects a service to exist providing query access to an IDOL index (by default,
`idol-query-service`, though this can be overridden via the chart values).

An `idol-nifi` service, if one exists, will be used for Universal Viewing.
