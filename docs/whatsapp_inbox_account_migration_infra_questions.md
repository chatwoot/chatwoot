# Questions for the Infra Agent

## Kubernetes runtime

1. What is the production namespace for this Chatwoot installation?
2. Which deployment/pod should be used for `rails runner` execution?
3. Is it acceptable to copy a temporary script into a running web pod under `/tmp`?
4. Are there admission or filesystem restrictions that would block that approach?
5. What is the exact command pattern normally used for ad-hoc Rails commands in this cluster?

## Environment and secrets

1. How are env vars injected into Chatwoot pods: Secret, ExternalSecret, SealedSecret, Helm values, or something else?
2. Does the web pod already have all DB/Redis/Rails env vars required for `bundle exec rails runner`?
3. Are there extra installation-specific env vars required for Rails boot in this deployment?
4. Is there any secret rotation or short-lived credential behavior to be aware of during the maintenance window?

## Database

1. What backup or snapshot should be taken immediately before execute?
2. Who owns/approves restore if rollback is needed?
3. Is there any write routing, proxy, or connection policy that might affect a one-off `rails runner` transaction?

## Redis

1. Is Redis standalone, Sentinel, or managed?
2. Are TLS or special client settings required?
3. Is scaling workers to `0` sufficient to avoid queue/assignment interference during execute?

## Workers and operations

1. Which deployment(s) run Sidekiq/background jobs for Chatwoot?
2. What is the exact scale-down command?
3. What is the exact scale-up command back to the original replica count?
4. Are there cronjobs or other controllers that should also be paused?
5. Are there monitoring/alerting rules that should be muted during the maintenance window?

## Rollback and safety

1. What is the expected rollback path if execute causes a bad state?
2. How long would restore take?
3. Is there any operational reason to prefer local execution over in-cluster execution for this migration?
