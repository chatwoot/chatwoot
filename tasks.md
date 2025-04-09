# Tasks for Converting auto_resolve_duration from Days to Minutes

## Background
Currently, the `auto_resolve_duration` field in the Account model stores values in days (e.g., 30 days). We need to convert this to store values in minutes to provide more granular control of auto-resolution.

## Backend Tasks

1. **Update Account Model Validation**
   - Current validation: `validates :auto_resolve_duration, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 999, allow_nil: true }`
   - Update validation to accept larger values suitable for minutes (1 day = 1440 minutes)
   - New validation should allow values from 15 minutes (minimum) to 1,439,856 minutes (999 days maximum)
   - Update: `validates :auto_resolve_duration, numericality: { greater_than_or_equal_to: 15, less_than_or_equal_to: 1_439_856, allow_nil: true }`

2. **Data Migration**
   - Create a migration to convert existing `auto_resolve_duration` values from days to minutes
   - Multiply existing values by 1440 (minutes in a day)
   - Handle potential NULL values
   - Example migration:
   ```ruby
   def up
     Account.where.not(auto_resolve_duration: nil).each do |account|
       account.update_column(:auto_resolve_duration, account.auto_resolve_duration * 1440)
     end
   end
   ```

3. **Update Resolvable Scope in Conversation Model**
   - Current scope: `open.where('last_activity_at < ? ', Time.now.utc - auto_resolve_duration.days)`
   - Change to: `open.where('last_activity_at < ? ', Time.now.utc - auto_resolve_duration.minutes)`

4. **Update Activity Messages**
   - In `activity_message_handler.rb`, update the auto-resolution message
   - Current implementation: `I18n.t('conversations.activity.status.auto_resolved', duration: auto_resolve_duration)`
   - Create a method to select appropriate translation key based on duration:
   ```ruby
   def auto_resolve_message_key(minutes)
     if minutes >= 1440 && minutes % 1440 == 0
       { key: 'auto_resolved_days', count: minutes / 1440 }
     elsif minutes >= 60 && minutes % 60 == 0
       { key: 'auto_resolved_hours', count: minutes / 60 }
     else
       { key: 'auto_resolved_minutes', count: minutes }
     end
   end
   ```
   - Update auto-resolution message generation:
   ```ruby
   # In activity_message_handler.rb (user_status_change_activity_content method)
   def user_status_change_activity_content(user_name)
     if user_name
       I18n.t("conversations.activity.status.#{status}", user_name: user_name)
     elsif Current.contact.present? && resolved?
       I18n.t('conversations.activity.status.contact_resolved', contact_name: Current.contact.name.capitalize)
     elsif resolved?
       message_data = auto_resolve_message_key(auto_resolve_duration)
       I18n.t("conversations.activity.status.#{message_data[:key]}", count: message_data[:count])
     end
   end
   ```
   - Update translation files: ✅
   ```yaml
   # In en.yml and other locale files
   en:
     conversations:
       activity:
         status:
           auto_resolved_days: "Conversation was marked resolved by system due to %{count} days of inactivity"
           auto_resolved_hours: "Conversation was marked resolved by system due to %{count} hours of inactivity"
           auto_resolved_minutes: "Conversation was marked resolved by system due to %{count} minutes of inactivity"
   ```

5. **Update Tests** ✅
   - Update test cases in `spec/models/account_spec.rb` for new validation limits (15 minutes minimum)
   - Update test cases in `spec/models/conversation_spec.rb` that test auto-resolution
   - Update test cases in `spec/jobs/conversations/resolution_job_spec.rb` to use minutes instead of days
   - Add tests for the new `auto_resolve_message_key` method
   - Test that proper translation keys are selected for different durations

6. **Documentation** ✅
   - Update API documentation to reflect the change from days to minutes
   - Add a note about backward compatibility for any external integrations

## Frontend Tasks

1. **Update UI for Auto-Resolve Duration Setting**
   - Current UI: Single number input field that accepts days (1-999)
   - New UI should provide:
     - A number input field for duration value
     - A dropdown to select the time unit (minutes, hours, days)
     - Default to days for backward compatibility
   
2. **Add State Variables**
   - Add `autoResolveDurationUnit` to track the selected unit (default: 'days')
   - Add `displayAutoResolveDuration` to store the converted value for display

3. **Update Validation**
   - Current validation: minValue(1), maxValue(999)
   - New validation based on selected unit:
     - Minutes: minValue(15), maxValue(1439856)
     - Hours: minValue(1), maxValue(23997)
     - Days: minValue(1), maxValue(999)

4. **Implement Conversion Logic**
   - When loading from API (always in minutes):
     - Detect best unit based on divisibility (days if divisible by 1440, hours if divisible by 60)
     - Calculate display value and set unit accordingly
   - When saving to API:
     - Convert user input to minutes based on selected unit
     - Send only the minutes value to the backend

5. **Update Localization Strings**
   - Add translations for new UI elements:
     - Unit selector options (minutes, hours, days)
     - Placeholder text
     - Validation error messages for each unit

6. **UI Implementation**
   - Replace the single input with:
     ```html
     <div class="flex">
       <input v-model="displayAutoResolveDuration" type="number" class="flex-grow" />
       <select v-model="autoResolveDurationUnit" class="ml-2">
         <option value="minutes">{{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MINUTES') }}</option>
         <option value="hours">{{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.HOURS') }}</option>
         <option value="days">{{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.DAYS') }}</option>
       </select>
     </div>
     ```

7. **Add Unit Conversion Methods**
   - `convertMinutesToDisplay(minutes)`: Convert API minutes to appropriate display value
   - `convertDisplayToMinutes(value, unit)`: Convert user input to minutes for API

8. **Update Events**
   - Add watchers for `displayAutoResolveDuration` and `autoResolveDurationUnit`
   - Recalculate validation rules when unit changes

9. **Testing**
   - Test all conversion edge cases
   - Verify validation works correctly for each unit
   - Confirm API sends and receives correct values

## Potential Challenges

1. **Backward Compatibility**:
   - External integrations might expect days as the unit of measurement
   - Consider providing helper methods to convert between days and minutes

2. **Database Size**:
   - Ensure the database column can handle larger integers (minutes will be larger values)
   - Consider changing column type to bigint if needed

3. **Performance Impact**:
   - The auto-resolution query using minutes should have similar or better performance as it avoids the day conversion

4. **Edge Cases**:
   - Ensure any frontend validation aligns with backend validation (15 minutes minimum)
   - Add proper error messages for validation failures
   - Handle rounding issues when converting between units