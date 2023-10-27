# single-content

Provides `idol-query-service` and `idol-index-service` Service objects, backed by
a single IDOL Content instance. Intended as a much lighter-weight alternative to
the `distributed-idol` chart, for use in testing charts that expect one or both
of these endpoints to exist in the cluster.
