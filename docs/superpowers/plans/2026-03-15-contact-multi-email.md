# Multi-Email Contacts Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow each contact to own multiple email addresses with one primary email, and reconcile inbound/contact lookup against any stored email while remaining backward-compatible with existing `contact.email` consumers.

**Architecture:** Introduce a normalized `contact_emails` table keyed by account and contact, keep `contacts.email` as the denormalized primary-email cache, and route all email lookup logic through the child table. Update contact write paths, merge flows, search, and the dashboard contact-details UI to manage aliases while preserving existing single-email API inputs for legacy clients.

**Tech Stack:** Ruby on Rails, ActiveRecord/PostgreSQL, Jbuilder, Vue 3 Composition API, RSpec, Vitest

---

## Chunk 1: Backend Data Model and Sync

### Task 1: Add `ContactEmail` persistence and invariants

**Files:**
- Create: `app/models/contact_email.rb`
- Create: `db/migrate/TIMESTAMP_create_contact_emails.rb`
- Create: `spec/factories/contact_emails.rb`
- Create: `spec/models/contact_email_spec.rb`
- Modify: `spec/enterprise/models/contact_company_association_spec.rb`
- Modify: `app/models/contact.rb`

- [ ] **Step 1: Write the failing model spec**

```ruby
require 'rails_helper'

describe ContactEmail do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: nil) }

  it 'normalizes email and validates uniqueness per account' do
    create(:contact_email, contact: contact, account: account, email: 'bob@gmail.com', primary: true)
    duplicate_contact = create(:contact, account: account, email: nil)

    duplicate = build(:contact_email, contact: duplicate_contact, account: account, email: 'BOB@GMAIL.COM', primary: false)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to be_present
  end

  it 'rejects account/contact mismatches and enforces a single primary row' do
    other_account = create(:account)
    mismatch = build(:contact_email, contact: contact, account: other_account, email: 'alias@example.com', primary: false)

    expect(mismatch).not_to be_valid
    expect(mismatch.errors[:account]).to be_present
  end

  it 'rejects zero-primary or multi-primary states for a contact with email rows' do
    create(:contact_email, contact: contact, account: account, email: 'one@example.com', primary: false)
    create(:contact_email, contact: contact, account: account, email: 'two@example.com', primary: false)

    expect(contact.reload.contact_emails.select(&:primary?)).to be_empty
    expect(contact).not_to be_valid

    create(:contact_email, contact: contact, account: account, email: 'three@example.com', primary: true)
    duplicate_primary = build(:contact_email, contact: contact, account: account, email: 'four@example.com', primary: true)

    expect(duplicate_primary).not_to be_valid
  end
end
```

- [ ] **Step 2: Run the spec to verify red**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/models/contact_email_spec.rb
```

Expected: fail with `uninitialized constant ContactEmail` or missing table errors.

- [ ] **Step 3: Implement the new model and migration**

Add:

- `has_many :contact_emails` on `Contact`
- `ContactEmail` model with `belongs_to :contact`, `belongs_to :account`
- email normalization before validation
- format validation matching `Devise.email_regexp`
- uniqueness validation scoped to `account_id`, case-insensitive
- validation enforcing `account_id == contact.account_id`
- partial unique index for one primary row per contact
- case-insensitive unique index for `lower(email), account_id`
- non-unique index on `contact_id`
- non-unique index on `account_id, primary`
- explicit foreign keys for `contact_id` and `account_id`
- explicit validation that a contact with any email rows has exactly one primary row
- indexes should follow existing repo conventions from recent contact migrations instead of assuming new foreign-key patterns
- phase-1 rollout behavior: backfill and read support ship first, while alias authoring remains disabled until all nodes/workers are on the new code

Migration shape:

```ruby
create_table :contact_emails do |t|
  t.integer :contact_id, null: false
  t.integer :account_id, null: false
  t.string :email, null: false
  t.boolean :primary, null: false, default: false
  t.timestamps
end
```

- [ ] **Step 4: Run the pre-index audit before backfill**

Add a pre-index audit query that aborts with a clear operator-facing error if legacy-invalid or normalization-colliding contact emails are found.

- [ ] **Step 5: Backfill existing primary emails**

Extend the migration to insert one primary child row for every existing `contacts.email` that is not null, and add an idempotent smoke check proving a pre-existing contact receives exactly one child row, marked `primary: true`, with the same email value after migrate.

- [ ] **Step 6: Run migrations and the targeted spec**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:test:prepare
bundle exec rspec spec/models/contact_email_spec.rb spec/enterprise/models/contact_company_association_spec.rb
```

Expected: PASS.

- [ ] **Step 7: Run a migration smoke check**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rails runner "puts Contact.where.not(email: nil).where.missing(:contact_emails).count"
```

Expected: `0`

- [ ] **Step 8: Verify backfilled rows match primary-email expectations**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rails runner "puts Contact.joins(:contact_emails).where.not(email: nil).where.not('contacts.email = contact_emails.email AND contact_emails.primary = ?', true).count"
```

Expected: `0`

- [ ] **Step 9: Commit**

```bash
git add app/models/contact_email.rb db/migrate spec/factories/contact_emails.rb spec/models/contact_email_spec.rb spec/enterprise/models/contact_company_association_spec.rb app/models/contact.rb
git commit -m "feat(contacts): add contact email addresses model"
```

### Task 2: Sync primary email writes with `contacts.email`

**Files:**
- Create: `app/services/contacts/email_addresses_sync_service.rb`
- Create: `spec/services/contacts/email_addresses_sync_service_spec.rb`
- Modify: `app/models/contact.rb`
- Modify: `app/controllers/api/v1/accounts/contacts_controller.rb`
- Modify: `spec/controllers/api/v1/accounts/contacts_controller_spec.rb`
- Modify: `app/actions/contact_identify_action.rb`
- Modify: `spec/actions/contact_identify_action_spec.rb`
- Modify: `app/services/data_import/contact_manager.rb`
- Modify: `spec/jobs/data_import_job_spec.rb`
- Modify: `app/mailboxes/mailbox_helper.rb`
- Modify: `spec/mailboxes/mailbox_helper_spec.rb`

- [ ] **Step 1: Write the failing service spec**

```ruby
require 'rails_helper'

describe Contacts::EmailAddressesSyncService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: nil) }

  it 'stores aliases and mirrors the primary email on contacts.email' do
    described_class.new(
      contact: contact,
      email_addresses: [
        { email: 'bob@gmail.com', primary: true },
        { email: 'bo@myworkplace.com', primary: false }
      ]
    ).perform

    expect(contact.reload.email).to eq('bob@gmail.com')
    expect(contact.contact_emails.pluck(:email, :primary)).to contain_exactly(
      ['bob@gmail.com', true],
      ['bo@myworkplace.com', false]
    )
  end

  it 'rejects duplicate normalized rows and multiple primaries' do
    expect do
      described_class.new(
        contact: contact,
        email_addresses: [
          { email: 'Bob@gmail.com ', primary: true },
          { email: ' bob@gmail.com', primary: false }
        ]
      ).perform
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect do
      described_class.new(
        contact: contact,
        email_addresses: [
          { email: 'one@example.com', primary: true },
          { email: 'two@example.com', primary: true }
        ]
      ).perform
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'promotes an existing alias or auto-promotes the oldest alias on legacy writes' do
    described_class.new(
      contact: contact,
      email_addresses: [
        { email: 'old-primary@example.com', primary: true },
        { email: 'alias@example.com', primary: false }
      ]
    ).perform

    expect { described_class.new(contact: contact, email: 'alias@example.com').perform }.not_to change { contact.reload.contact_emails.count }
    expect(described_class.new(contact: contact, email: nil).perform.reload.email).to eq('old-primary@example.com')
  end
end
```

- [ ] **Step 2: Run the service spec to verify red**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/services/contacts/email_addresses_sync_service_spec.rb
```

Expected: FAIL because the service does not exist.

- [ ] **Step 3: Implement the sync service**

Service responsibilities:

- normalize input rows
- reject duplicate/malformed rows
- ensure exactly one primary row for non-empty `email_addresses` payloads
- replace the contact's child rows with the requested set
- mirror the selected primary row into `contacts.email`
- allow zero rows and clear `contacts.email`
- treat `email_addresses` as authoritative when present
- keep legacy top-level `email` writes additive by demoting the previous primary to an alias when a new primary is set
- touch the parent contact on alias-only mutations so normal contact update events still fire

- [ ] **Step 4: Add the account contact write contract**

Update `Api::V1::Accounts::ContactsController` so account-scoped create/update accepts:

- `email_addresses: [{ email, primary }]`
- legacy `email`
- precedence rule: when `email_addresses` is present, ignore top-level `email` on write and derive it from the primary child row

Cover in request specs:

- create with only `email`
- update with `email_addresses`
- update with `email_addresses` plus conflicting `email`
- update with duplicate alias owned by another contact
- update with non-empty `email_addresses` and no primary, expecting validation failure
- update with `email_addresses: []`, expecting all emails to clear

- [ ] **Step 5: Add the transitional legacy-write bridge**

Implement one bridge in `Contact` so direct legacy `email` assignments from builders/mailboxes still flow through the same sync path until every caller is migrated. Cover at least one mailbox-helper path that creates a contact from an email sender.

- [ ] **Step 6: Wire existing single-email flows through the service**

Rules:

- controller create/update with only `email` should still work
- changing legacy top-level `email` should demote the previous primary to a non-primary alias
- blanking legacy top-level `email` should auto-promote the oldest remaining alias or clear all emails
- `ContactIdentifyAction` with `params[:email]` should set or promote the primary child row
- `DataImport::ContactManager` should continue accepting one email string and sync it through the service

- [ ] **Step 7: Run focused specs**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/services/contacts/email_addresses_sync_service_spec.rb spec/controllers/api/v1/accounts/contacts_controller_spec.rb spec/actions/contact_identify_action_spec.rb spec/jobs/data_import_job_spec.rb spec/mailboxes/mailbox_helper_spec.rb
```

Expected: PASS.

- [ ] **Step 8: Re-run Enterprise compatibility coverage after the sync changes**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/enterprise/models/contact_company_association_spec.rb
```

Expected: PASS, with alias-only changes not triggering association and primary promotion preserving the existing contract.

- [ ] **Step 9: Commit**

```bash
git add app/services/contacts/email_addresses_sync_service.rb spec/services/contacts/email_addresses_sync_service_spec.rb app/models/contact.rb app/controllers/api/v1/accounts/contacts_controller.rb spec/controllers/api/v1/accounts/contacts_controller_spec.rb app/actions/contact_identify_action.rb spec/actions/contact_identify_action_spec.rb app/services/data_import/contact_manager.rb spec/jobs/data_import_job_spec.rb app/mailboxes/mailbox_helper.rb spec/mailboxes/mailbox_helper_spec.rb
git commit -m "feat(contacts): sync primary and alias email writes"
```

### Task 3: Route email lookup through `contact_emails`

**Files:**
- Modify: `app/models/contact.rb`
- Modify: `app/builders/contact_inbox_with_contact_builder.rb`
- Modify: `app/services/mailbox/conversation_finder_strategies/new_conversation_strategy.rb`
- Modify: `app/mailboxes/imap/imap_mailbox.rb`
- Modify: `app/mailboxes/mailbox_helper.rb`
- Create: `spec/models/contact_from_email_spec.rb`
- Modify: `spec/builders/contact_inbox_with_contact_builder_spec.rb`
- Modify: `spec/services/mailbox/conversation_finder_strategies/new_conversation_strategy_spec.rb`
- Modify: `spec/mailboxes/imap/imap_mailbox_spec.rb`
- Modify: `spec/mailboxes/mailbox_helper_spec.rb`
- Modify: `spec/actions/contact_identify_action_spec.rb`
- Modify: `spec/jobs/data_import_job_spec.rb`

- [ ] **Step 1: Write the failing lookup spec**

```ruby
require 'rails_helper'

describe Contact, '.from_email' do
  it 'finds a contact through a non-primary alias' do
    contact = create(:contact, email: nil)
    create(:contact_email, contact: contact, account: contact.account, email: 'bob@gmail.com', primary: true)
    create(:contact_email, contact: contact, account: contact.account, email: 'bo@myworkplace.com', primary: false)

    expect(contact.account.contacts.from_email('bo@myworkplace.com')).to eq(contact)
  end
end
```

- [ ] **Step 2: Run the new spec to verify red**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/models/contact_from_email_spec.rb
```

Expected: FAIL because `from_email` only reads `contacts.email`.

- [ ] **Step 3: Implement relation-safe lookup**

Implementation target:

- make `from_email` resolve through `joins(:contact_emails)` so it works on `Contact` and `account.contacts`
- include a temporary fallback to `contacts.email` during the rollout window when a child row does not exist yet
- keep the caller API unchanged
- remove any direct dependence on `contacts.email` for lookup logic
- for inbound email flows, resolve the contact at account scope and create a missing `ContactInbox` for the target inbox instead of creating a second contact

- [ ] **Step 4: Update mailbox/builder specs to cover alias resolution**

Add one scenario in each affected spec where the incoming sender or lookup email matches a non-primary alias and ensure the existing contact is reused, including `ContactIdentifyAction` and `DataImport::ContactManager`.

Add one inbound-email scenario where the matched contact exists in the account but has no `ContactInbox` for the receiving inbox, and verify the flow creates the missing `ContactInbox` while keeping the same contact.

Add one fallback scenario where `contacts.email` is present but `contact_emails` rows are missing, and ensure lookup still resolves during rollout overlap.

- [ ] **Step 5: Run focused specs**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/models/contact_from_email_spec.rb spec/builders/contact_inbox_with_contact_builder_spec.rb spec/services/mailbox/conversation_finder_strategies/new_conversation_strategy_spec.rb spec/mailboxes/imap/imap_mailbox_spec.rb spec/mailboxes/mailbox_helper_spec.rb spec/actions/contact_identify_action_spec.rb spec/jobs/data_import_job_spec.rb
```

Expected: PASS.

- [ ] **Step 6: Re-run shared-lookup dependents**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/actions/contact_identify_action_spec.rb spec/jobs/data_import_job_spec.rb
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/models/contact.rb app/builders/contact_inbox_with_contact_builder.rb app/services/mailbox/conversation_finder_strategies/new_conversation_strategy.rb app/mailboxes/imap/imap_mailbox.rb app/mailboxes/mailbox_helper.rb spec/models/contact_from_email_spec.rb spec/builders/contact_inbox_with_contact_builder_spec.rb spec/services/mailbox/conversation_finder_strategies/new_conversation_strategy_spec.rb spec/mailboxes/imap/imap_mailbox_spec.rb spec/mailboxes/mailbox_helper_spec.rb spec/actions/contact_identify_action_spec.rb spec/jobs/data_import_job_spec.rb
git commit -m "feat(contacts): resolve contacts by any stored email"
```

## Chunk 2: API, Merge, Search, and Dashboard

### Task 4: Expose alias emails in account contact APIs and search

**Files:**
- Modify: `app/controllers/api/v1/accounts/contacts_controller.rb`
- Modify: `app/controllers/api/v1/accounts/search_controller.rb`
- Modify: `app/services/search_service.rb`
- Modify: `enterprise/app/services/captain/tools/copilot/search_contacts_service.rb`
- Modify: `app/views/api/v1/models/_contact.json.jbuilder`
- Modify: `app/views/api/v1/accounts/search/_contact.json.jbuilder`
- Modify: `spec/controllers/api/v1/accounts/contacts_controller_spec.rb`
- Modify: `spec/controllers/api/v1/accounts/search_controller_spec.rb`
- Modify: `spec/services/search_service_spec.rb`
- Modify: `spec/enterprise/services/captain/tools/copilot/search_contacts_service_spec.rb`
- Modify: `swagger/swagger.json`

- [ ] **Step 1: Write the failing request specs**

Add one request spec that expects:

- account contact `create`/`update` accepts `email_addresses`
- account contacts index/show payloads include `email_addresses`
- `show`/`update` responses include `email_addresses`
- `/contacts/search` finds the contact when queried by an alias email
- `/search/contacts` returns the contact and includes `email_addresses`
- Enterprise Captain contact search by alias email returns the same contact
- `SearchService` returns one contact row even if multiple alias rows match the same query
- `SearchService` conversation search finds a conversation by a contact alias email

- [ ] **Step 2: Run the serialization and contract specs to verify red**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/controllers/api/v1/accounts/contacts_controller_spec.rb spec/controllers/api/v1/accounts/search_controller_spec.rb
```

Expected: FAIL because aliases are neither serialized nor searched.

- [ ] **Step 3: Implement scoped serialization for `email_addresses`**

Add to contact JSON:

```ruby
json.email_addresses do
  json.array! resource.contact_emails.order(primary: :desc, created_at: :asc) do |email_record|
    json.id email_record.id
    json.email email_record.email
    json.primary email_record.primary
  end
end
```

Serialization direction:

- keep `email_addresses` behind the explicit `with_email_addresses` gate from the spec
- enable that gate only for account contact endpoints and account search contact results
- keep reused contact partial call sites such as merge/contact-inbox filter/conversation nested contact payloads primary-email-only in this MVP

- [ ] **Step 4: Run the serialization specs again**

Run the same `bundle exec rspec spec/controllers/api/v1/accounts/contacts_controller_spec.rb spec/controllers/api/v1/accounts/search_controller_spec.rb` command.

Expected: PASS for scoped response shape and request contract changes.

- [ ] **Step 5: Implement alias-aware search behavior**

Search direction:

- use `LEFT JOIN contact_emails`
- search alias emails in addition to `contacts.email`
- ensure distinct contact rows before pagination
- update both `Api::V1::Accounts::ContactsController#search` and `SearchService` (`filter_contacts` and conversation/contact search surfaces)
- update Enterprise Captain contact search helpers that currently filter by contact email
- update `swagger/swagger.json` for the new response and request contract

- [ ] **Step 6: Run the search specs to verify green**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/services/search_service_spec.rb spec/enterprise/services/captain/tools/copilot/search_contacts_service_spec.rb spec/controllers/api/v1/accounts/search_controller_spec.rb
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/api/v1/accounts/contacts_controller.rb app/controllers/api/v1/accounts/search_controller.rb app/services/search_service.rb enterprise/app/services/captain/tools/copilot/search_contacts_service.rb app/views/api/v1/models/_contact.json.jbuilder app/views/api/v1/accounts/search/_contact.json.jbuilder spec/controllers/api/v1/accounts/contacts_controller_spec.rb spec/controllers/api/v1/accounts/search_controller_spec.rb spec/services/search_service_spec.rb spec/enterprise/services/captain/tools/copilot/search_contacts_service_spec.rb swagger/swagger.json
git commit -m "feat(contacts): expose and search contact email aliases"
```

### Task 5: Preserve aliases through manual contact merge

**Files:**
- Modify: `app/actions/contact_merge_action.rb`
- Modify: `spec/actions/contact_merge_action_spec.rb`

- [ ] **Step 1: Write the failing merge spec**

Add a case where:

- base contact has `bob@gmail.com` as primary
- mergee contact has `bo@myworkplace.com`
- after merge the base contact owns both emails and remains primary on `bob@gmail.com`
- add a second case where both contacts already share the same alias email and the duplicate row is skipped cleanly
- add a third case where the base contact has no email rows and the mergee primary becomes the merged contact primary

- [ ] **Step 2: Run the merge spec to verify red**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec spec/actions/contact_merge_action_spec.rb
```

Expected: FAIL because merge does not transfer child email rows.

- [ ] **Step 3: Implement merge transfer logic**

Rules:

- move unique child rows from mergee to base
- preserve base primary row
- demote transferred mergee rows if needed
- resync `contacts.email` from the final primary row before destroy

- [ ] **Step 4: Run the merge spec again**

Run the same `bundle exec rspec spec/actions/contact_merge_action_spec.rb` command.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/actions/contact_merge_action.rb spec/actions/contact_merge_action_spec.rb
git commit -m "feat(contacts): preserve email aliases on merge"
```

### Task 6: Add alias management to the dashboard contact details view

**Files:**
- Create: `app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactEmailFields.vue`
- Modify: `app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue`
- Modify: `app/javascript/dashboard/components-next/Contacts/Pages/ContactDetails.vue`
- Modify: `app/javascript/dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue`
- Modify: `app/javascript/dashboard/store/modules/contacts/actions.js`
- Modify: `app/javascript/dashboard/store/modules/specs/contacts/actions.spec.js`
- Modify: `app/javascript/dashboard/i18n/locale/en/contact.json`
- Create: `app/javascript/dashboard/components-next/Contacts/ContactsForm/spec/ContactsForm.spec.js`

- [ ] **Step 1: Write the failing component and store specs**

Add a test that:

- loads a contact with two email addresses
- adds a new alias email
- removes an alias email
- marks a different alias as primary
- emits an update payload containing `email_addresses`
- keeps the create-contact dialog in single-email mode

Add a store spec that proves `email_addresses` survives `FormData` serialization for contact updates with avatar uploads.

- [ ] **Step 2: Run the component and store specs to verify red**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
pnpm test -- app/javascript/dashboard/components-next/Contacts/ContactsForm/spec/ContactsForm.spec.js
pnpm test -- app/javascript/dashboard/store/modules/specs/contacts/actions.spec.js
```

Expected: FAIL because the form only models a single `email` string and the store does not yet encode `email_addresses` for `FormData`.

- [ ] **Step 3: Implement the smallest UI that works**

UI shape:

- keep the existing primary email input visible
- render additional alias rows below it
- support add/remove alias
- support "set as primary"
- emit `email_addresses` plus top-level `email` derived from the selected primary row

Use `ContactEmailFields.vue` as the dedicated alias-row component. Keep the page layout and Tailwind patterns intact while isolating alias-row state and validation from `ContactsForm.vue`.

- [ ] **Step 4: Update the account contact update request**

Update the store serialization path in `app/javascript/dashboard/store/modules/contacts/actions.js` so `email_addresses` survives both JSON and `FormData` submissions. Add a store spec proving the array is encoded correctly for avatar-upload updates.

- [ ] **Step 5: Run frontend and focused backend verification**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
pnpm test -- app/javascript/dashboard/components-next/Contacts/ContactsForm/spec/ContactsForm.spec.js
pnpm test -- app/javascript/dashboard/store/modules/specs/contacts/actions.spec.js
eval "$(rbenv init -)"
bundle exec rspec spec/controllers/api/v1/accounts/contacts_controller_spec.rb
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactEmailFields.vue app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue app/javascript/dashboard/components-next/Contacts/Pages/ContactDetails.vue app/javascript/dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue app/javascript/dashboard/store/modules/contacts/actions.js app/javascript/dashboard/store/modules/specs/contacts/actions.spec.js app/javascript/dashboard/i18n/locale/en/contact.json app/javascript/dashboard/components-next/Contacts/ContactsForm/spec/ContactsForm.spec.js
git commit -m "feat(contacts): manage multiple emails in contact details"
```

### Task 7: Final verification sweep

**Files:**
- Modify: none unless fixes are needed

- [ ] **Step 1: Run the focused regression suite**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
eval "$(rbenv init -)"
bundle exec rspec \
  spec/models/contact_email_spec.rb \
  spec/models/contact_from_email_spec.rb \
  spec/enterprise/models/contact_company_association_spec.rb \
  spec/services/contacts/email_addresses_sync_service_spec.rb \
  spec/services/search_service_spec.rb \
  spec/enterprise/services/captain/tools/copilot/search_contacts_service_spec.rb \
  spec/actions/contact_identify_action_spec.rb \
  spec/actions/contact_merge_action_spec.rb \
  spec/builders/contact_inbox_with_contact_builder_spec.rb \
  spec/services/mailbox/conversation_finder_strategies/new_conversation_strategy_spec.rb \
  spec/mailboxes/imap/imap_mailbox_spec.rb \
  spec/mailboxes/mailbox_helper_spec.rb \
  spec/jobs/data_import_job_spec.rb \
  spec/controllers/api/v1/accounts/contacts_controller_spec.rb \
  spec/controllers/api/v1/accounts/search_controller_spec.rb
pnpm test -- app/javascript/dashboard/components-next/Contacts/ContactsForm/spec/ContactsForm.spec.js
pnpm test -- app/javascript/dashboard/store/modules/specs/contacts/actions.spec.js
```

Expected: all tests pass.

- [ ] **Step 2: Run lint on touched files**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
pnpm eslint \
  app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactEmailFields.vue \
  app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue \
  app/javascript/dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue \
  app/javascript/dashboard/components-next/Contacts/Pages/ContactDetails.vue \
  app/javascript/dashboard/store/modules/contacts/actions.js \
  app/javascript/dashboard/store/modules/specs/contacts/actions.spec.js
eval "$(rbenv init -)"
bundle exec rubocop app/models/contact.rb app/models/contact_email.rb app/services/contacts/email_addresses_sync_service.rb app/controllers/api/v1/accounts/contacts_controller.rb app/controllers/api/v1/accounts/search_controller.rb app/services/search_service.rb enterprise/app/services/captain/tools/copilot/search_contacts_service.rb app/actions/contact_merge_action.rb app/mailboxes/mailbox_helper.rb app/mailboxes/imap/imap_mailbox.rb app/builders/contact_inbox_with_contact_builder.rb app/services/mailbox/conversation_finder_strategies/new_conversation_strategy.rb
```

Expected: no lint errors.

- [ ] **Step 3: Inspect the diff**

Run:

```bash
cd /Users/sadimir/.config/superpowers/worktrees/chatwoot/contact-multi-email
git status --short
git diff --stat
```

Expected: only the intended contact multi-email files are changed.

- [ ] **Step 4: Manual smoke test the real user flow**

Run through the happy path in a local dev environment:

1. open one contact in contact details
2. add an alias email and save
3. set the alias as primary and save
4. remove a non-primary alias and save
5. verify contact search finds the contact by the remaining alias
6. merge a second contact into it
7. verify the merged contact is still found by the alias and shows the same conversation history

- [ ] **Step 4: Prepare PR materials**

Draft PR points:

- product change: one contact can own multiple emails with one primary email
- how to test: add alias email in contact details, send inbound email from alias, verify the same contact/conversation history is reused
- closes: `#3079`
