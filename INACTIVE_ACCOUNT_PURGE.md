# Inactive Account Purge Feature

This feature implements the requirement from Linear issue CW-5526 to purge inactive accounts from Chatwoot. The implementation provides differentiated email templates for user-initiated vs system-initiated account deletions.

## Overview

The feature consists of:
1. **Differentiated Email Templates** - Separate templates for user vs system initiated deletions
2. **Inactive Account Identification** - Service to identify accounts that haven't been active
3. **Automated Purge Job** - Background job to mark inactive accounts for deletion
4. **Manual Tools** - Rake tasks for administrators to manage the process

## Components

### 1. Email Templates

#### User-Initiated Deletion (`account_deletion_user_initiated.liquid`)
- **Subject**: "Your Chatwoot account deletion has been scheduled"
- **Content**: Confirms user-requested deletion with clear next steps
- **Template**: `/app/views/mailers/administrator_notifications/account_notification_mailer/account_deletion_user_initiated.liquid`

#### System-Initiated Deletion (`account_deletion_system_initiated.liquid`)
- **Subject**: "Your Chatwoot account is scheduled for deletion due to inactivity"
- **Content**: Explains inactivity-based deletion with 30-day grace period
- **Template**: `/app/views/mailers/administrator_notifications/account_notification_mailer/account_deletion_system_initiated.liquid`

### 2. Mailer Updates

**Updated**: `AdministratorNotifications::AccountNotificationMailer`
- Enhanced `account_deletion` method to route to appropriate template based on reason
- Added date formatting for user-friendly deletion dates
- Included configurable support email in system-initiated emails

### 3. Inactive Account Identification

**Service**: `Internal::InactiveAccountIdentificationService`
- **Location**: `/app/services/internal/inactive_account_identification_service.rb`
- **Criteria for Inactivity**:
  - No user has been active in the last 30 days (`account_users.active_at`)
  - No conversations created or updated in the last 30 days
  - Account status is `active` (not suspended)
  - Account is not already marked for deletion
  - Account was created more than 30 days ago

### 4. Purge Job

**Job**: `Internal::PurgeInactiveAccountsJob`
- **Location**: `/app/jobs/internal/purge_inactive_accounts_job.rb`
- **Function**: Identifies inactive accounts and marks them for deletion with reason "Account Inactive"
- **Queue**: `scheduled_jobs`
- **Error Handling**: Continues processing if individual accounts fail

### 5. Configuration

**File**: `/config/initializers/inactive_account_purge.rb`
- `INACTIVITY_THRESHOLD_DAYS`: Configurable via `INACTIVE_ACCOUNT_THRESHOLD_DAYS` env var (default: 30)
- `SUPPORT_EMAIL`: Configurable via `CHATWOOT_SUPPORT_EMAIL` env var (default: hello@chatwoot.com)

### 6. Management Tools

**Rake Tasks**: `/lib/tasks/ops/purge_inactive_accounts.rake`

#### Dry Run
```bash
bundle exec rake chatwoot:ops:purge_inactive_accounts:dry_run
```
- Shows inactive accounts without marking them for deletion
- Displays detailed information about each account

#### Execute Purge
```bash
bundle exec rake chatwoot:ops:purge_inactive_accounts
```
- Interactive tool to mark inactive accounts for deletion
- Requires confirmation before proceeding

## Usage

### Manual Execution
```ruby
# Identify inactive accounts
inactive_accounts = Internal::InactiveAccountIdentificationService.inactive_accounts

# Mark specific account for deletion (user-initiated)
account.mark_for_deletion('manual_deletion')

# Mark specific account for deletion (system-initiated)
account.mark_for_deletion('Account Inactive')

# Run purge job
Internal::PurgeInactiveAccountsJob.perform_now
```

### Scheduled Execution
Add to your scheduler (e.g., whenever gem):
```ruby
# config/schedule.rb
every 1.week do
  runner "Internal::PurgeInactiveAccountsJob.perform_later"
end
```

## Testing

### Test Files Created
1. `/spec/services/internal/inactive_account_identification_service_spec.rb`
2. `/spec/jobs/internal/purge_inactive_accounts_job_spec.rb`
3. `/spec/mailers/administrator_notifications/account_notification_mailer_spec.rb`

### Test Coverage
- Inactive account identification logic
- Email template routing
- Job execution and error handling
- Edge cases (suspended accounts, recently created accounts, etc.)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INACTIVE_ACCOUNT_THRESHOLD_DAYS` | 30 | Days of inactivity before marking for deletion |
| `CHATWOOT_SUPPORT_EMAIL` | hello@chatwoot.com | Support email for system-initiated emails |

## Migration Notes

### Existing Installations
- No database migrations required
- Feature uses existing `custom_attributes` on Account model
- Backward compatible with existing deletion flows

### Template Migration
- Original template (`account_deletion.liquid`) maintained for backward compatibility
- New installations will automatically use differentiated templates
- Can be gradually migrated by updating deletion reason logic

## Security Considerations

1. **Grace Period**: 30-day default grace period allows users to reactivate accounts
2. **Confirmation Required**: Manual rake task requires explicit confirmation
3. **Audit Trail**: All deletions logged with reasons and timestamps
4. **Reversible**: Accounts can be unmarked for deletion during grace period

## Monitoring

### Logging
- All purge activities logged to Rails logger
- Individual account processing logged with success/failure status
- Error details captured for failed operations

### Metrics to Monitor
- Number of inactive accounts identified per run
- Success/failure rates of marking accounts for deletion
- User reactivation rates during grace period

## Future Enhancements

1. **Dashboard Integration**: Add inactive account metrics to admin dashboard
2. **Custom Thresholds**: Per-account or per-plan inactivity thresholds
3. **Warning Emails**: Send warning emails before marking for deletion
4. **Activity Weighting**: Consider different types of activity (logins vs conversations)
5. **Bulk Operations**: Admin interface for bulk account management

## Deployment Checklist

- [ ] Deploy code changes
- [ ] Verify environment variables are set
- [ ] Test dry run command
- [ ] Set up scheduled job
- [ ] Monitor first few executions
- [ ] Update documentation for support team

## Examples

### Email Content Examples

**User-Initiated Deletion Email**:
```
Hello there,

You've requested to delete your Chatwoot account **"Acme Corp"**. This account is now scheduled for deletion on **January 15, 2024**.

**What happens next?**
* The account will remain accessible until the scheduled deletion date.
* After that, all data including conversations, contacts, integrations, and settings, will be permanently removed.

If you change your mind before the deletion date, you can cancel this request by clicking **here**.

— Chatwoot Team
```

**System-Initiated Deletion Email**:
```
Hello there,

We've noticed that your Chatwoot account **"Acme Corp"** has been inactive for some time. Because of this, it's scheduled for deletion in **30 days**.

**How do I keep my account?**
Just log in to your Chatwoot account before **January 15, 2024**. From your account settings, you can cancel the deletion and continue using your account.

**What happens if I don't cancel?**
If there's no activity by **January 15, 2024**, your account and all associated data — including conversations, contacts, reports, and settings — will be permanently deleted.

**Why are we doing this?**
To keep things secure and efficient, we regularly remove inactive accounts so our systems remain optimized for active teams.

If you have any questions, feel free to reach us at **hello@chatwoot.com**.

— The Chatwoot Team
```