# Chatwoot 
This repo is a fork of chatwoot project. We have made some custom changes to the interface and modified few features to suit our needs.

Chatwoot repo: https://github.com/chatwoot/chatwoot
Tag: v4.0.4

Chatwoot only provides the manual chat feature. We have created a RAG based service which is used to automate responses to user queries.

RAG Search Repo: https://github.com/delta-exchange/support-chatbot

## Useful links:

Devnet Chatwoot Dashboard: https://chatsupport-devnet.delta.exchange/

Production India Chatwoot Dashboard: https://chatsupport.delta.exchange/

Rag Search Devnet Dashboard:
http://internal-k8s-ragsearchindinter-f260553195-1364350755.ap-northeast-1.elb.amazonaws.com/

Rag Search Production Dashboard: 
http://internal-chatwoot-ragsearch-int-ingress-1795977167.ap-northeast-1.elb.amazonaws.com/


## Documentation

### User Guide
https://www.chatwoot.com/hc/user-guide/en

### Developer Docs
https://developers.chatwoot.com/introduction


## Setup
Install docker and docker compose. Docker desktop is recommended.
https://docs.docker.com/get-started/get-docker/

Clone the repo
```
git clone https://github.com/delta-exchange/chatwoot.git
```

### Running the Application
```bash
docker compose build base-system
docker compose build base-deps
docker compose up
```

### First time onboarding
Visit http://localhost:3000 to view chatwoot dashboard and complete the initial onboarding

```javascript
user_name: john@acme.inc
password: Password1!
```

### Testing Chat Widget
To test the chat widget in your local environment:
0. Ensure local dev server is running
1. Precompile assets:
   ```bash
   docker compose exec rails bundle exec rails assets:precompile
   ```
2. Visit http://localhost:3000/widget_tests?setUser=true
3. Reference: https://developers.chatwoot.com/contributing-guide/setup-guide#testing-chat-widget-in-your-local-environment

### Restoring devnet chatwoot db backup and setup

Get the backup dump file from @anuj-delta or @mankupathak-delta

### Steps to restore devnet chatwoot db backup
Open two terminals

Terminal 1 commands:
1. Remove old builds and volumes with
   `docker compose down -v`
2. Build once
   `docker compose build` (assuming base-system and base-deps are already built)
3. Start just postgres and redis - keep this running
   `docker compose up postgres redis`

Terminal 2 commands:
1. Using new terminal, copy dump file to postgres container
   `docker cp backup.dump chatwoot-postgres-1:/tmp/backup.dump`
2. Restore dump
   `docker exec -it chatwoot-postgres-1 pg_restore -U postgres -d chatwoot_production -v -c --if-exists /tmp/backup.dump`
3. Success migration will show like below without any errors
```
pg_restore: creating TRIGGER "public.accounts accounts_after_insert_row_tr"
pg_restore: creating TRIGGER "public.accounts camp_dpid_before_insert"
pg_restore: creating TRIGGER "public.campaigns campaigns_before_insert_row_tr"
pg_restore: creating TRIGGER "public.conversations conversations_before_insert_row_tr"
pg_restore: creating FK CONSTRAINT "public.active_storage_variant_records fk_rails_993965df05"
pg_restore: creating FK CONSTRAINT "public.inboxes fk_rails_a1f654bf2d"
pg_restore: creating FK CONSTRAINT "public.active_storage_attachments fk_rails_c3b3935057"
```
4. Start docker compose up in Terminal 1 again
   `docker compose up`
5. Get your devnet user credentials from @anuj-delta or @mankupathak-delta
