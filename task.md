# Decoupled Fork Integration Tasks

Checklist for implementing the modular community features into the local `chatwoot-plus` repository.

## 1. Setup & Environment
- [x] Create branch `feature/plus-integration` off clean `develop`
- [x] Add and verify environment keys in `.env` and `.env.example`

## 2. UnoAPI Channel Integration
- [ ] Cherry-pick UnoAPI inbox commits (`61973d62c3`, `451eb55cfb`, `1902de7d86`, `8c7a5d1764`, `44f2b30845`)
- [ ] Resolve any config or view conflicts
- [ ] Verify UnoAPI channel can be registered in local Dev environment

## 3. WhatsApp Groups Engine & Groups Tab
- [ ] Create database migration for group conversation fields and `group_contacts` table
- [ ] Cherry-pick groups tab commit (`9c407f3e79`)
- [ ] Implement/adapt payload normalizer for inbound WhatsApp/Uno group events
- [ ] Implement group participants Sidekiq hydration job

## 4. Preserved Deleted Messages & Sync
- [ ] Cherry-pick commits (`e581b62e7d`, `e19e54d776`, `1cb87e901f`)
- [ ] Verify account settings schema correctly registers `preserve_deleted_message_content`
- [ ] Validate bidirectional deletion webhook handlers

## 5. Facebook/Instagram Comments Handling
- [ ] Cherry-pick comments forwarding middleware and jobs (`179ccf6cf6`, `eb442cf194`, `ed96467046`)
- [ ] Cherry-pick Comments sidebar views and proxy controllers (`bc045f33f5`, `8df096cb72`, `786e46fde3`, `e6ccddafce`, `914c4a2f2c`, `acc0a9dadd`)
- [ ] Mount proxy routes in `config/routes.rb` and frontend routing files

## 6. Inline Click-to-WhatsApp Ad Referrals
- [ ] Cherry-pick ad referral persistence and inline cards (`dfb2fcb467`, `79ad984996`, `72d650b311`)
- [ ] Verify inline cards do not render for standard 1-to-1 conversations

## 7. Scheduled Messages (Decoupled)
- [ ] Create table migration for `plus_scheduled_messages`
- [ ] Implement `Plus::ScheduledMessage` model and Sidekiq periodic runner job
- [ ] Add datetime scheduler picker to dashboard conversation `Editor.vue`

## 8. Per-Inbox Signatures (Schema-less)
- [ ] Add signature input field to general inbox Settings frontend
- [ ] Append signature in `Messages::MessageBuilder` when sending outgoing public messages

## 9. Uno Premium Health Check
- [ ] Cherry-pick ops task and job configuration (`93edbbfb04`)
- [ ] Ensure `schedule.yml` runs the worker daily

## 10. Docker Setup & E2E Verification
- [ ] Configure `unoapi` service block in `docker-compose.production.yaml`
- [ ] Run database migrations (`bundle exec rails db:migrate`)
- [ ] Boot Chatwoot dev stack and perform manual verification of all modules
