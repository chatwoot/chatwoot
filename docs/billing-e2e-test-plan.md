# Billing & Subscriptions — End-to-End Test Plan (Staging)

**Environment:** https://staging.cx.aloochat.ai
**Super Admin:** https://staging.cx.aloochat.ai/super_admin
**Stripe Dashboard:** Stripe Test Mode
**Logs:** `.devbin/staging-logs` (kubectl logs) / `.devbin/staging-sidekiq-logs`
**Console:** `.devbin/staging-console` (Rails console on staging)

---

## Prerequisites

- [ ] Stripe test mode is active on staging (verify via staging-console: `Stripe.api_key`)
- [ ] Stripe test card numbers ready: `4242 4242 4242 4242` (success), `4000 0000 0000 0341` (decline)
- [ ] A fresh test account on staging (or reset an existing one via super admin)
- [ ] Access to Stripe dashboard to verify events/webhooks
- [ ] Browser DevTools open (Network tab) to monitor API calls

---

## Test Accounts Setup

| Account | Purpose | Initial State |
|---------|---------|---------------|
| **Account A** | Full lifecycle (trial → paid → upgrade → cancel) | Fresh signup / trial granted via super admin |
| **Account B** | Payment failure & suspension flow | Needs active subscription |
| **Account C** | Super admin actions (complimentary, override, bonus credits) | Any state |

---

## 1. TRIAL FLOW

### 1.1 New Account Gets Trial Automatically
- **Action:** Create a new account on staging (sign up flow)
- **Expected:**
  - Account gets 14-day Pro trial with 500 AI credits
  - Billing page shows "Pro" plan, trial status, trial end date
  - AI usage meter shows trial credits remaining
  - CRM features are enabled (Pro trial)
- **Verify in logs:** `BillingListener` triggered, `grant_trial!` called
- **Verify in Super Admin:** Account shows trial subscription

### 1.2 Trial Billing Page Display
- **Action:** Navigate to Settings → Billing on the trial account
- **Expected:**
  - Current Plan card shows: Plan = "Pro", Status = "trialing", Trial Ends = date
  - Usage card shows AI responses meter (0 / limit)
  - Plan selector shows all 4 plans (Basic Monthly/Annual, Pro Monthly/Annual)
  - "Manage Billing" button is visible
  - No "Cancel" button (trial can't be cancelled from UI — it just expires)

### 1.3 Trial Credit Consumption
- **Action:** Trigger AI responses (send messages to an AI-powered bot/agent)
- **Expected:**
  - `trial_credits_remaining` decrements on each AI response
  - Usage meter updates on billing page refresh
  - AI responses continue working while credits > 0
- **Verify via console:** `Account.find(ID).trial_credits_remaining`

### 1.4 Trial Expiry (Time-based)
- **Action:** Via super admin or console, set trial to expire (e.g., `account.active_subscription.update!(trial_ends_at: 1.minute.ago, ends_at: 1.minute.ago)`)
- **Expected:**
  - `on_trial?` returns false
  - `ai_responses_allowed?` returns false
  - Billing page shows no active plan or prompts to subscribe
  - AI features should be gated (paywall shown)

### 1.5 Trial Expiry (Credits Exhausted)
- **Action:** Via console, set `account.update!(trial_credits_remaining: 0)`
- **Expected:**
  - `trial_active?` returns false (even though time hasn't expired)
  - AI responses are blocked
  - User should see paywall / upgrade prompt

### 1.6 Trial Extension (Super Admin)
- **Action:** Super Admin → Accounts → Find account → Extend Trial (14 days)
- **Expected:**
  - `trial_ends_at` extended by 14 days
  - Account can use AI again if credits remain
  - Billing page reflects new trial end date

---

## 2. CHECKOUT & FIRST SUBSCRIPTION

### 2.1 Checkout — Basic Monthly
- **Action:** On billing page, select "Basic Monthly" (60 KD/mo) → redirected to Stripe Checkout
- **Expected:**
  - Stripe Checkout page loads with correct amount (60 KD)
  - Promo code field is available (`allow_promotion_codes: true`)
  - Metadata shows `account_id` and `plan_key`
- **Pay with:** `4242 4242 4242 4242`, any future expiry, any CVC

### 2.2 Post-Checkout State
- **Action:** Complete payment, redirected back to billing page
- **Expected:**
  - Plan shows "Basic", Status = "active"
  - `trial_credits_remaining` is cleared to 0
  - Limits synced: `ai_responses_per_month: 10000`, `knowledge_base_documents: 100`
  - CRM feature disabled (Basic plan)
  - API access disabled (Basic plan)
  - Renewal date shown correctly
  - Usage meter shows 0 / 10,000
- **Verify in logs:** `checkout.session.completed` webhook received, `handle_checkout_completed` ran
- **Verify in Stripe:** Subscription active, customer created with account metadata

### 2.3 Checkout — Pro Monthly
- **Action:** Repeat with a different account, select "Pro Monthly" (75 KD/mo)
- **Expected:**
  - Same as above but limits: `ai_responses_per_month: 25000`, `knowledge_base_documents: 200`
  - CRM feature **enabled**
  - API access **enabled**

### 2.4 Checkout with Promo Code
- **Action:** Create a test coupon in Stripe dashboard, then checkout with promo code applied
- **Expected:**
  - Discount reflected on Stripe Checkout page
  - Subscription created with discount applied
  - Invoice shows correct discounted amount

### 2.5 Checkout — Card Declined
- **Action:** Attempt checkout with `4000 0000 0000 0341` (always declined)
- **Expected:**
  - Stripe shows error on checkout page
  - No subscription created
  - Account remains in previous state (trial or no plan)
  - No crash/error in staging logs

---

## 3. PLAN MANAGEMENT

### 3.1 Swap Plan — Basic Monthly → Pro Monthly (Upgrade)
- **Action:** On billing page with active Basic Monthly, click Pro Monthly plan
- **Expected:**
  - `swapPlan` API called, Stripe subscription updated
  - Plan changes to "Pro" immediately
  - Limits updated: 25,000 AI responses, 200 KB docs
  - CRM feature enabled
  - Success toast shown
- **Verify in Stripe:** Subscription shows new price, prorated invoice if applicable
- **Verify in logs:** `subscription.updated` webhook → `handle_subscription_updated` → `sync_plan_features!`

### 3.2 Swap Plan — Pro Monthly → Basic Monthly (Downgrade)
- **Action:** Swap from Pro Monthly to Basic Monthly
- **Expected:**
  - Plan changes to "Basic"
  - Limits reduced: 10,000 AI responses, 100 KB docs
  - CRM feature disabled
  - If usage already exceeds new limit, overage tracking should kick in

### 3.3 Swap Plan — Monthly → Annual (Same Tier)
- **Action:** Swap from Basic Monthly (60 KD/mo) to Basic Annual (600 KD/yr)
- **Expected:**
  - Interval changes, same features/limits
  - Stripe handles proration
  - Billing page shows annual renewal date

### 3.4 Swap Plan — Annual → Monthly
- **Action:** Swap from annual back to monthly
- **Expected:**
  - Stripe processes the change
  - Renewal date updates accordingly

### 3.5 Manage Billing Portal
- **Action:** Click "Manage Billing" button
- **Expected:**
  - Redirected to Stripe Billing Portal
  - Can view invoices, update payment method
  - Can see subscription details
  - Return URL works correctly back to billing page

---

## 4. CANCELLATION & RESUME

### 4.1 Cancel Subscription
- **Action:** Click "Cancel" button on billing page
- **Expected:**
  - Subscription set to cancel at period end (NOT immediately)
  - Status changes to show grace period
  - "Resume" button appears
  - "Cancel" button disappears
  - Plan features remain active until period end
  - Success toast shown
- **Verify in Stripe:** Subscription `cancel_at_period_end: true`

### 4.2 Resume Cancelled Subscription
- **Action:** Click "Resume" button during grace period
- **Expected:**
  - Cancellation reversed
  - Status returns to "active"
  - "Cancel" button reappears, "Resume" disappears
  - Success toast shown
- **Verify in Stripe:** `cancel_at_period_end: false`

### 4.3 Subscription Actually Expires (End of Period)
- **Action:** Via Stripe dashboard or CLI, advance subscription to end of period (or via console cancel immediately)
- **Expected:**
  - `subscription.deleted` webhook fires
  - Account no longer subscribed
  - Features gated (paywall shown)
  - Plan selector shown again for re-subscription

---

## 5. USAGE TRACKING & OVERAGE

### 5.1 Normal Usage Within Limits
- **Action:** Trigger AI responses on a subscribed account
- **Expected:**
  - `ai_responses_count` increments in `AccountUsageRecord`
  - Usage meter on billing page updates
  - No overage tracked

### 5.2 Usage at 80% — Warning Notification
- **Action:** Via console, set usage to 80% of limit (e.g., 8000/10000 for Basic)
- **Expected:**
  - `BillingNotificationJob` sends `usage_warning` email
  - Check mailer logs or email delivery
- **Note:** This runs daily via sidekiq-cron, may need to trigger manually: `BillingNotificationJob.perform_now`

### 5.3 Usage Exceeds Limit — Overage
- **Action:** Via console, set `usage.ai_responses_count` above the plan limit
- **Expected:**
  - `overage_count` calculated and stored
  - `overage_notice` email sent (via daily job)
  - Overage shown on billing page
  - AI responses still work (overage model, not hard block)

### 5.4 Overage Billing on Invoice
- **Action:** When Stripe creates the next invoice (or simulate via Stripe CLI)
- **Expected:**
  - `invoice.created` webhook fires
  - `handle_invoice_created` adds overage line item
  - Line item: "AI response overage: N responses x 0.010 KD"
  - Total invoice = subscription amount + overage
- **Verify in Stripe:** Invoice shows the extra line item

### 5.5 Usage Reset on New Month
- **Action:** Check that a new `AccountUsageRecord` is created for the new month
- **Expected:**
  - Previous month's record preserved
  - New month starts at 0 for all counters

---

## 6. PAYMENT FAILURE & SUSPENSION

### 6.1 Payment Fails — Subscription Goes Unpaid
- **Action:** In Stripe, update the customer's payment method to a declining card, then trigger an invoice payment attempt
- **Expected:**
  - Stripe marks subscription as `past_due` then `unpaid`
  - `subscription.updated` webhook fires with status `unpaid`
  - `handle_subscription_updated` calls `suspend_for_nonpayment!`
  - Account status changes to `suspended`
  - `custom_attributes` has `suspension_reason: "nonpayment"` and `suspended_at`
  - `account_suspended` email sent
- **Verify in Super Admin:** Account shows as suspended

### 6.2 Suspended Account — User Experience
- **Action:** Log into the suspended account
- **Expected:**
  - Account is suspended — features should be restricted
  - User should see indication that account is suspended
  - Billing page should still be accessible to fix payment

### 6.3 Successful Payment After Suspension — Auto-Reactivate
- **Action:** Update payment method in Stripe to a working card, retry invoice
- **Expected:**
  - `charge.succeeded` webhook fires
  - `handle_charge_succeeded` calls `reactivate_after_payment!`
  - Account status returns to `active`
  - `suspension_reason` and `suspended_at` removed from custom_attributes
  - Plan features re-synced
  - `account_reactivated` email sent

---

## 7. SUPER ADMIN ACTIONS

### 7.1 Grant Trial
- **Action:** Super Admin → Accounts → select account → Grant Trial (14 days)
- **Expected:**
  - Account gets trial subscription with 500 credits
  - Pro features enabled
  - Billing page shows trial

### 7.2 Extend Trial
- **Action:** Super Admin → Extend Trial (14 days) on an account with active trial
- **Expected:**
  - `trial_ends_at` extended
  - Billing page reflects new date

### 7.3 Grant Complimentary Plan
- **Action:** Super Admin → Grant Complimentary
- **Expected:**
  - Account gets active subscription on `fake_processor`
  - Full Pro features without Stripe payment
  - No expiry (unlimited)
  - Billing page shows active plan

### 7.4 Override Plan
- **Action:** Super Admin → Override Plan (select a plan_key)
- **Expected:**
  - Previous subscription cancelled
  - New subscription created (fake or Stripe based on option)
  - Features synced to new plan

### 7.5 Add Bonus Credits
- **Action:** Super Admin → Add Bonus Credits (e.g., 1000)
- **Expected:**
  - `bonus_credits` on current usage record increased by 1000
  - Effective AI limit = plan limit + bonus credits
  - Account can use more AI responses before overage

### 7.6 Reset Usage
- **Action:** Super Admin → Reset Usage
- **Expected:**
  - `ai_responses_count` and `voice_notes_count` reset to 0
  - Usage meter on billing page shows 0
  - Overage cleared

### 7.7 Cancel Subscription (Admin)
- **Action:** Super Admin → Cancel Subscription
- **Expected:**
  - Subscription cancelled at period end
  - Same behavior as user-initiated cancel

### 7.8 Suspend Account
- **Action:** Super Admin → Suspend
- **Expected:**
  - Account status = suspended
  - Same behavior as nonpayment suspension

### 7.9 Reactivate Account
- **Action:** Super Admin → Reactivate
- **Expected:**
  - Account status = active
  - Features re-synced

### 7.10 Apply Coupon
- **Action:** Via console: `account.apply_coupon!("COUPON_ID")` on a Stripe subscription
- **Expected:**
  - Discount applied in Stripe
  - Next invoice reflects discount

---

## 8. BILLING DASHBOARD (Super Admin)

- **Action:** Navigate to Super Admin → Billing Dashboard (`/admin/billing_dashboard`)
- **Expected:**
  - Shows correct counts for:
    - Active subscriptions
    - Active trials
    - Trials expiring in 7 days
    - Complimentary subscriptions
    - No subscription
    - Suspended accounts
    - Total accounts

---

## 9. BILLING EMAILS

| Email | Trigger | How to Test |
|-------|---------|-------------|
| `trial_expiring` | 3 days before trial end | Set trial_ends_at to 3 days from now, run `BillingNotificationJob.perform_now` |
| `trial_expired` | Day after trial ends | Set trial_ends_at to yesterday, run job |
| `payment_failed` | Stripe payment fails | Use declining card |
| `usage_warning` | 80%+ usage reached | Set usage to 80%+, run job |
| `overage_notice` | Usage exceeds limit | Set usage above limit, run job |
| `usage_limit_reached` | Limit fully exceeded | Set usage = limit, run job |
| `welcome_to_plan` | First successful checkout | Complete checkout flow |
| `plan_changed` | Plan swap | Swap plan |
| `account_suspended` | Nonpayment suspension | Trigger suspension |
| `account_reactivated` | Payment after suspension | Trigger reactivation |

**How to verify emails on staging:**
- Check staging logs for mailer output
- Check Stripe events for webhook deliveries
- If using a staging email service (e.g., Mailhog), check the inbox

---

## 10. FEATURE GATING

### 10.1 CRM Feature Gate
- **Action:** On Basic plan, try to access CRM features
- **Expected:** CRM features disabled/hidden (`:crm` feature flag off)

- **Action:** Upgrade to Pro plan
- **Expected:** CRM features enabled (`:crm` feature flag on)

### 10.2 API Access Gate
- **Action:** On Basic plan, check if API access is restricted
- **Expected:** API access disabled per plan config

- **Action:** On Pro plan, check API access
- **Expected:** API access enabled

### 10.3 Knowledge Base Document Limit
- **Action:** On Basic plan (100 docs limit), try adding documents beyond limit
- **Expected:** `within_limit?('knowledge_base_documents', count)` returns false

---

## 11. EDGE CASES & REGRESSION

### 11.1 Double Checkout Prevention
- **Action:** Rapidly click checkout button twice
- **Expected:** Only one Stripe Checkout session created, no duplicate subscriptions

### 11.2 Concurrent Webhook Processing
- **Action:** Trigger multiple webhooks in quick succession (checkout + subscription.created)
- **Expected:** No race conditions, account state is consistent

### 11.3 Account with No Email
- **Action:** Account where `support_email` is blank and no admin email
- **Expected:** Billing still works, Stripe customer creation handles gracefully

### 11.4 Re-subscribe After Full Cancellation
- **Action:** After subscription fully expires, go through checkout again
- **Expected:** New subscription created cleanly, features re-enabled

### 11.5 Billing Page for Non-Admin
- **Action:** Log in as an agent (non-admin) and try to access `/settings/billing`
- **Expected:** Access denied (route requires `administrator` permission)

### 11.6 Voice Notes Usage Tracking
- **Action:** Send voice notes (each counts as 6 AI responses)
- **Expected:** `voice_notes_count` increments, `ai_responses_count` increments by 6 per note

---

## Execution Order (Recommended)

1. **Setup:** Prepare test accounts via Super Admin (Section 0)
2. **Trial Flow:** Test 1.1 → 1.6
3. **Checkout:** Test 2.1 → 2.5
4. **Plan Swaps:** Test 3.1 → 3.5
5. **Cancel/Resume:** Test 4.1 → 4.3
6. **Usage & Overage:** Test 5.1 → 5.5
7. **Payment Failure:** Test 6.1 → 6.3
8. **Super Admin:** Test 7.1 → 7.10
9. **Dashboard:** Test 8
10. **Emails:** Test 9
11. **Feature Gating:** Test 10.1 → 10.3
12. **Edge Cases:** Test 11.1 → 11.6

---

## Tooling Quick Reference

```bash
# Tail staging Rails logs (last 200 lines, follow)
.devbin/staging-logs 200

# Tail staging Sidekiq logs
.devbin/staging-sidekiq-logs

# Open Rails console on staging
.devbin/staging-console

# Useful console commands:
a = Account.find(ID)
a.billing_status                    # Full billing state
a.active_plan                       # Current plan
a.usage_summary                     # Usage details
a.trial_credits_remaining           # Trial credits left
a.grant_trial!(days: 14)            # Grant trial
a.extend_trial!(days: 7)            # Extend trial
a.reset_usage!                      # Reset counters
a.add_bonus_credits!(1000)          # Add bonus credits
a.suspend_for_nonpayment!           # Simulate suspension
a.reactivate_after_payment!         # Simulate reactivation
BillingNotificationJob.perform_now  # Trigger notification emails
```
