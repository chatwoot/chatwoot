# Assignment v2 Feature Documentation

## Overview

Assignment v2 is an intelligent, automated conversation distribution system that ensures conversations are fairly and efficiently assigned to available agents. It replaces the legacy assignment mechanism with a more sophisticated approach that considers multiple factors like agent capacity, availability, and conversation priority.

## Purpose

Instead of conversations sitting unassigned or being manually assigned one-by-one, Assignment v2 automatically distributes them across your team based on configurable rules and policies. This ensures:

- **No conversations are left unassigned** — Open conversations get assigned to agents automatically
- **Fair workload distribution** — Conversations are spread evenly across the team
- **Respects agent capacity** — Agents don't get overloaded with too many conversations
- **Flexible prioritization** — You control how conversations are prioritized (oldest first vs. longest waiting)

---

## How It Works: The Auto-Assignment Flow

Assignment v2 operates through two parallel mechanisms:

### 1. Real-time Assignment Trigger (AutoAssignmentHandler)

The system monitors conversation changes in real-time through the `AutoAssignmentHandler` concern:

- **Triggers on**: Every conversation save operation
- **Assignment occurs when**:
  - A conversation transitions to `status: 'open'` with no assignee
  - A conversation has an assignee who is no longer an inbox member
- **Action**: Immediately enqueues an `AutoAssignment::AssignmentJob` for that inbox
- **Fallback**: If assignment_v2 is not enabled, falls back to legacy `AgentAssignmentService`

This ensures conversations get assigned immediately when they become eligible, without waiting for the periodic job.

### 2. Periodic Assignment Cycle

The system also runs a **30-minute cycle** through an automated job (`AutoAssignment::PeriodicAssignmentJob`) configured in `config/schedule.yml`:

1. **Discovery Phase**: The system checks all accounts in batches
   - Only accounts with the `assignment_v2` feature flag enabled are processed
   - Uses `find_in_batches` for memory efficiency with large datasets

2. **Queue Phase**: For each inbox in those accounts:
   - Only inboxes with an `assignment_policy` linked are considered
   - The inbox must have `enable_auto_assignment` set to true
   - The linked assignment policy must be enabled
   - An `AutoAssignment::AssignmentJob` is queued for each eligible inbox

3. **Processing Phase**: Each assignment job:
   - Fetches up to 100 unassigned, open conversations (configurable via `AUTO_ASSIGNMENT_BULK_LIMIT` env var)
   - Processes conversations one at a time in the order determined by the priority policy

4. **Assignment Phase**: For each conversation, the system:
   - Checks if the conversation is assignable (open status, no current assignee)
   - Finds agents who are available (online status) and have capacity
   - Filters agents by rate limiting rules
   - Selects one agent using the configured selection strategy
   - Assigns the conversation to that agent
   - Tracks the assignment in Redis for rate limiting
   - Dispatches an `ASSIGNEE_CHANGED` event

### Key Architectural Details

- **Job Queues**:
  - `PeriodicAssignmentJob` runs in the `scheduled_jobs` queue
  - `AssignmentJob` runs in the `default` queue

- **Batched Processing**: Uses `find_in_batches` for accounts and inboxes to handle large-scale deployments efficiently

- **Error Handling**:
  - Errors are logged with the inbox ID
  - In test environments, errors are re-raised for debugging
  - In production, errors don't crash the entire job cycle

- **Conversation Limits**: Default is 100 conversations per job run, preventing memory issues and long-running jobs

---

## Prerequisites & Feature Enablement

Assignment v2 requires **all** of the following conditions to be met:

1. **Account-Level Feature Flag**: The account must have the `assignment_v2` feature enabled (configured in `config/features.yml`)
2. **Assignment Policy**: An `AssignmentPolicy` must exist and be linked to the inbox via `InboxAssignmentPolicy`
3. **Policy Enabled**: The `AssignmentPolicy` must have `enabled: true` (acts as a soft switch)
4. **Inbox Auto-Assignment**: The inbox must have `enable_auto_assignment: true`

If any of these conditions is not met, the inbox is skipped entirely and no assignments occur. The system checks these conditions via the `Inbox#auto_assignment_v2_enabled?` method.

---

## Assignment Policies

Policies determine HOW conversations are selected and assigned. Here are the main policies:

### 1. Conversation Priority Policy

**What it does**: Controls which conversations get assigned first

**Options**:

- **Longest Waiting Mode** (`longest_waiting`):
  - Prioritizes conversations based on `last_activity_at` (oldest first)
  - Uses `last_activity_at ASC, created_at ASC` ordering
  - Ensures customers waiting longest for a response get priority
  - Ideal for support teams focused on response time SLAs

- **Default Mode** (or any other value):
  - Conversations are assigned in the order they were created
  - Uses `created_at ASC` ordering
  - First In, First Out (FIFO) approach
  - Ideal for teams that want to clear backlogs chronologically

**Example**:
```
Conversation A: Created 2 hours ago, last activity 2 hours ago
Conversation B: Created 1 hour ago, last activity 30 minutes ago
Conversation C: Created 30 minutes ago, last activity 30 minutes ago

Longest Waiting: A → B → C (prioritizes least recent activity)
Default: A → B → C (prioritizes creation order)
```

### 2. Fair Distribution / Rate Limiting Policy

**What it does**: Prevents any single agent from being overwhelmed by too many assignments in a short time window

**Configuration**:
- `fair_distribution_limit`: Maximum number of assignments per agent within the time window (integer)
- `fair_distribution_window`: Time window in seconds (integer, defaults to 3600 seconds / 1 hour)

**How it works**:
- When enabled, the system tracks each assignment in Redis
- Redis key pattern: `chatwoot:assignment:{inbox_id}:{agent_id}:{conversation_id}`
- Each key has a TTL (Time To Live) equal to the configured window
- Before assigning, the system counts existing keys for that agent
- If count >= limit, the agent is filtered out from eligible agents
- After assignment, a new Redis key is created with the window TTL

**Behavior**:
- If `fair_distribution_limit` is not set or is 0, rate limiting is disabled
- Rate limiting is applied **per inbox per agent**
- Once the time window expires, old assignments are automatically removed from Redis
- Agents become eligible again once their count drops below the limit

**Example**:
```
Configuration: limit=5, window=3600 (1 hour)

Agent A is assigned 5 conversations between 10:00-10:15am
At 10:16am, Agent A is filtered out (at limit)
At 11:01am (after the first assignment expires), Agent A is eligible again
```

**Edge Cases**:
- If ALL agents hit their rate limit, no assignments occur (0 assignments returned)
- Rate limits are checked AFTER agent availability but BEFORE capacity checks
- Rate limiting tracks assignments, not current workload (different from capacity)

### 3. Agent Availability Policy

**What it does**: Ensures only agents who are actually available get new conversations

**How it works**:
- Uses `OnlineStatusTracker` to check real-time agent status
- Fetches all users with their status from Redis
- Only agents with status exactly equal to `'online'` are eligible
- Agents with status `'busy'`, `'offline'`, or any other value are filtered out

**Integration**:
- The system calls `inbox.available_agents` which:
  1. Fetches online agent IDs from `OnlineStatusTracker`
  2. Filters inbox members to only those with online status
  3. Returns `InboxMember` records (not `User` records)

**Edge Cases**:
- If no agents are online for an inbox, 0 assignments occur
- Agent availability is checked at the time of assignment (not when the job starts)
- If an agent goes offline mid-job, they won't receive more assignments

**Important**: The system does NOT check:
- Agent's working hours
- Agent's timezone
- Agent's custom availability settings (these would need to be handled separately)

### 4. Capacity Management Policy (Enterprise Feature)

**What it does**: Advanced workload balancing based on agent's current load and conversation history

**How it works**:
- Each agent can be assigned to an `AgentCapacityPolicy`
- The policy defines `InboxCapacityLimit` records (one per inbox)
- Each limit specifies a `conversation_limit` (integer)
- The system counts the agent's current **open** conversations in that specific inbox
- If `current_count >= conversation_limit`, the agent is filtered out

**Key Characteristics**:
- **Inbox-specific**: Limits apply per inbox, so an agent can have different limits for different inboxes
- **Open conversations only**: Only counts conversations with `status: 'open'`
- **Optional**: If an agent has no `AgentCapacityPolicy`, they have unlimited capacity
- **Per-inbox limits**: If a capacity policy exists but has no `InboxCapacityLimit` for a specific inbox, the agent has unlimited capacity for that inbox

**Example**:
```
Agent A has a capacity policy with:
- Inbox 1 (Support): limit = 10
- Inbox 2 (Sales): limit = 20

Agent A currently has:
- 10 open conversations in Inbox 1
- 5 open conversations in Inbox 2

Result:
- Agent A is at capacity for Inbox 1 (10 >= 10) → filtered out
- Agent A has capacity for Inbox 2 (5 < 20) → eligible
```

**Edge Cases**:
- Resolved/closed conversations do NOT count toward capacity
- Capacity is checked at assignment time, not continuously
- If an agent goes over capacity manually (outside auto-assignment), they're still filtered out

### 5. Exclusion Rules (Enterprise Feature)

**What it does**: Allows excluding certain conversations from auto-assignment based on labels or age

**Configuration** (on `AgentCapacityPolicy`):
```ruby
exclusion_rules = {
  'excluded_labels' => ['VIP', 'Escalation', 'Manual'],
  'exclude_older_than_hours' => 24
}
```

**Behavior**:

**Label-Based Exclusions**:
- Conversations tagged with any of the excluded labels are skipped
- Uses the `tagged_with` method with `exclude: true`
- Multiple labels are treated as OR (conversation with ANY excluded label is skipped)
- Label matching is exact (case-sensitive)

**Age-Based Exclusions**:
- Conversations older than the specified hours are skipped
- Age is calculated from `created_at`, not `last_activity_at`
- Uses `where('conversations.created_at >= ?', hours.hours.ago)`
- If set to 24, conversations created more than 24 hours ago are excluded

**Combined Exclusions**:
- Both rules are applied together (AND logic)
- A conversation must pass both checks to be eligible
- Example: Must be less than 24 hours old AND not have an excluded label

**Edge Cases**:
- If `exclusion_rules` is nil or empty, no exclusions apply
- If there's no capacity policy linked to the inbox, exclusion rules don't apply
- Exclusions are applied BEFORE agent selection (reduces conversations to assign)

---

## Selection Strategies

Once eligible agents are identified (after availability, rate limiting, and capacity checks), the system uses a selection strategy to pick the agent:

### Round-Robin (Default)

**Implementation**: Uses `AutoAssignment::RoundRobinSelector` which delegates to `AutoAssignment::InboxRoundRobinService`

**How it works**:
- Maintains a Redis-based queue of agent IDs for the inbox
- Each time an agent is selected, they're moved to the back of the queue
- The next agent in the queue is always selected
- Ensures even distribution over time

**Characteristics**:
- **Fair over time**: Each agent gets an equal turn
- **Stateful**: Uses Redis to maintain queue state across jobs
- **Inbox-specific**: Each inbox has its own round-robin queue

**Example**:
```
Queue: [Agent A, Agent B, Agent C]

Assignment 1: Agent A (queue becomes [Agent B, Agent C, Agent A])
Assignment 2: Agent B (queue becomes [Agent C, Agent A, Agent B])
Assignment 3: Agent C (queue becomes [Agent A, Agent B, Agent C])
```

**Edge Cases**:
- If an agent is removed from the inbox, they're removed from the queue
- If a new agent is added, they're added to the queue
- The queue is validated and reset if it becomes inconsistent (membership drift)
- The `InboxRoundRobinService` validates the queue and resets it when agent membership changes

### Balanced / Workload-Based (Enterprise)

**Implementation**: Uses `Enterprise::AutoAssignment::BalancedSelector`

**How it works**:
- For each eligible agent, counts their current **open** conversations in the inbox
- Selects the agent with the **minimum** count
- Uses `min_by` which returns the first agent if there's a tie

**Characteristics**:
- **Real-time balancing**: Based on current workload, not historical assignments
- **Inbox-specific**: Only counts conversations in the specific inbox
- **Open conversations only**: Ignores resolved/closed conversations
- **Prioritizes new agents**: Agents with 0 conversations are always selected first

**Example**:
```
Agent A: 5 open conversations
Agent B: 3 open conversations
Agent C: 8 open conversations

Selection: Agent B (has the least workload)

After assignment:
Agent A: 5, Agent B: 4, Agent C: 8
Next selection: Agent B again (still has least)
```

**Comparison**:

| Aspect | Round-Robin | Balanced |
|--------|-------------|----------|
| **Goal** | Equal distribution over time | Equal workload at any moment |
| **State** | Redis queue | Database query |
| **Speed** | Very fast (Redis lookup) | Slower (DB count query) |
| **Accuracy** | Equal turns, not equal workload | Equal workload |
| **Best for** | High-volume, fast assignments | Teams where agents have varying resolve rates |

**Configuration**:
- In OSS: Always uses Round-Robin
- In Enterprise: Can set `balanced: true` on the assignment policy to use Balanced strategy

---

## Important Behaviors & Edge Cases

### Conversation Eligibility

A conversation is only eligible for auto-assignment if ALL of the following are true:

1. **Status is 'open'**: Resolved, pending, or snoozed conversations are never assigned
2. **No current assignee**: Conversations with an existing assignee are never reassigned
3. **Passes exclusion rules** (if Enterprise): Must not have excluded labels and must be within age threshold
4. **In an eligible inbox**: The inbox must have auto-assignment v2 enabled

**Edge Cases**:
- If a conversation is manually assigned mid-job, it's skipped (already has assignee)
- If a conversation is resolved mid-job, it's skipped (no longer open)
- Assignment v2 NEVER reassigns conversations (even if the current agent goes offline)

### Agent Eligibility

An agent is only eligible for assignment if ALL of the following are true:

1. **Member of the inbox**: Agent must be an `InboxMember`
2. **Status is 'online'**: Checked via `OnlineStatusTracker` at assignment time
3. **Within rate limit** (if configured): Agent hasn't exceeded assignments in the current window
4. **Has capacity** (if Enterprise): Agent's open conversation count is below their limit for this inbox

**Edge Cases**:
- If an agent meets all criteria but goes offline between the eligibility check and assignment, they may still receive the conversation (race condition)
- If ALL agents are filtered out, the conversation remains unassigned until the next cycle

### Zero-Assignment Scenarios

The system may assign 0 conversations if:

1. No unassigned, open conversations exist in the inbox
2. All conversations are excluded by exclusion rules
3. No agents are online
4. All online agents are at their rate limit
5. All online agents are at capacity (Enterprise)
6. The assignment policy is disabled mid-job

### Assignment Events

When a conversation is successfully assigned, the system:

1. Updates the conversation's `assignee_id` in the database
2. Creates a Redis key to track the assignment (for rate limiting)
3. Dispatches an `Events::Types::ASSIGNEE_CHANGED` event with:
   - `conversation`: The conversation object
   - `user`: The assigned agent
   - Timestamp of the assignment

**Event Integration**:
- Webhooks subscribed to `ASSIGNEE_CHANGED` will be triggered
- The conversation model also dispatches a `conversation.updated` event
- These events can be used for notifications, integrations, or analytics

### Error Handling

**Job-Level Errors**:
- If an `AssignmentJob` encounters an error, it logs the error with the inbox ID
- In production, the error is caught and logged, allowing other jobs to continue
- In test environment, errors are re-raised for debugging

**Service-Level Errors**:
- If a single conversation assignment fails, it's skipped and the job continues
- The `assigned_count` only includes successful assignments
- Database errors (like constraint violations) are logged but don't stop the job

**Graceful Degradation**:
- If Redis is unavailable, rate limiting is skipped (all assignments proceed)
- If OnlineStatusTracker fails, no agents are considered online (0 assignments)
- If the inbox is deleted mid-job, the job exits early

### Performance Considerations

**Batch Processing**:
- Accounts are processed in batches to avoid loading all accounts into memory
- Inboxes are processed in batches to avoid loading all inboxes into memory
- Conversations are limited to 100 per job to prevent long-running jobs

**Redis Usage**:
- Rate limiting creates one Redis key per assignment
- Keys automatically expire based on the configured window
- Pattern matching (`keys_count`) is used to count assignments (can be expensive with many agents)

**Database Queries**:
- Uses `includes(:user)` in `InboxAgentAvailability#available_agents` to preload users and avoid N+1 queries
- Falls back to `inbox_members.none` when no agents are online to avoid unnecessary database hits
- Uses `group(:assignee_id).count` for balanced selector (efficient aggregation)
- Uses `limit(100)` to prevent loading thousands of conversations at once

**Scaling Recommendations**:
- For high-volume inboxes, increase `AUTO_ASSIGNMENT_BULK_LIMIT` (e.g., 200-500)
- Consider shorter rate limiting windows for faster cycling (e.g., 1800 seconds instead of 3600)
- Use balanced selector for teams where workload balance is critical

---

## API Endpoints

Assignment v2 provides REST API endpoints for managing assignment policies:

### Policy Management
- **CRUD Operations**: `Api::V1::Accounts::AssignmentPoliciesController`
  - `GET /api/v1/accounts/:account_id/assignment_policies` - List all policies
  - `POST /api/v1/accounts/:account_id/assignment_policies` - Create a policy
  - `PUT /api/v1/accounts/:account_id/assignment_policies/:id` - Update a policy
  - `DELETE /api/v1/accounts/:account_id/assignment_policies/:id` - Delete a policy
  - **Accepts**: `assignment_order`, `conversation_priority`, `fair_distribution_limit`, `fair_distribution_window`, `enabled`

### Inbox-Policy Linking
- **Link/Unlink**: `Api::V1::Accounts::Inboxes::AssignmentPoliciesController`
  - `POST /api/v1/accounts/:account_id/inboxes/:inbox_id/assignment_policy` - Attach policy to inbox
  - `DELETE /api/v1/accounts/:account_id/inboxes/:inbox_id/assignment_policy` - Detach policy from inbox
  - **Note**: Only one policy can be linked to an inbox at a time

### Policy-Inbox Queries
- **List Linked Inboxes**: `Api::V1::Accounts::AssignmentPolicies::InboxesController`
  - `GET /api/v1/accounts/:account_id/assignment_policies/:policy_id/inboxes` - List all inboxes using a policy

### Authorization
- All endpoints require proper account scoping
- Requires `AssignmentPolicy` authorization for the requesting user

---

## Configuration & Flexibility

Assignment v2 is designed to be flexible at multiple levels:

### Account Level
- **Feature Flag**: `assignment_v2` must be enabled on the account
- **Enterprise Features**: Capacity and exclusion rules require Enterprise

### Policy Level
- **Assignment Order**: `round_robin` (default) or `balanced` (Enterprise only)
- **Conversation Priority**: `longest_waiting` or `earliest_created` (default/FIFO)
- **Fair Distribution Limit**: Integer (e.g., 5)
- **Fair Distribution Window**: Integer in seconds (defaults to 3600 when omitted)
- **Enabled**: Boolean soft switch to enable/disable the policy

### Inbox Level
- **Auto-Assignment**: `enable_auto_assignment` boolean
- **Policy Link**: `InboxAssignmentPolicy` links inbox to a policy (one-to-one relationship)
- **Capacity Limits** (Enterprise): Per-inbox conversation limits
- **Configuration Overrides**:
  - **OSS**: The `inbox.auto_assignment_config` JSONB field can override policy settings for per-inbox customization
  - **Enterprise**: Policy settings take precedence over `inbox.auto_assignment_config` - edit the policy directly

### Agent Level
- **Capacity Policy** (Enterprise): Optional `AgentCapacityPolicy` per agent
- **Availability**: Real-time online status tracked by `OnlineStatusTracker`

### Environment Level
- **Bulk Limit**: `AUTO_ASSIGNMENT_BULK_LIMIT` env var (default: 100)
- **Job Schedule**: Configurable via job scheduler (default: 30 minutes)

---

## System Architecture

### Components

1. **Jobs**:
   - `AutoAssignment::PeriodicAssignmentJob`: Scheduled job that discovers eligible inboxes
   - `AutoAssignment::AssignmentJob`: Per-inbox job that performs assignments

2. **Services**:
   - `AutoAssignment::AssignmentService`: Core assignment logic (OSS)
   - `Enterprise::AutoAssignment::AssignmentService`: Extended with capacity and exclusion rules
   - `AutoAssignment::RateLimiter`: Rate limiting logic using Redis
   - `Enterprise::AutoAssignment::CapacityService`: Capacity checking logic

3. **Selectors**:
   - `AutoAssignment::RoundRobinSelector`: Round-robin selection strategy
   - `Enterprise::AutoAssignment::BalancedSelector`: Workload-based selection strategy

4. **Models**:
   - `AssignmentPolicy`: Configures assignment behavior
   - `InboxAssignmentPolicy`: Links inbox to policy
   - `AgentCapacityPolicy` (Enterprise): Defines capacity rules
   - `InboxCapacityLimit` (Enterprise): Per-inbox limits

5. **Concerns**:
   - `InboxAgentAvailability`: Provides `available_agents` method for inboxes

### Data Flow

```
1. PeriodicAssignmentJob (every 30 min)
   ↓
2. For each Account with assignment_v2
   ↓
3. For each Inbox with auto_assignment_v2_enabled?
   ↓
4. Queue AssignmentJob(inbox_id)
   ↓
5. AssignmentService.perform_bulk_assignment(limit: 100)
   ↓
6. Fetch unassigned conversations (with priority ordering)
   ↓
7. For each conversation:
   a. Check assignable? (open + no assignee)
   b. Find available agents (online + rate limit + capacity)
   c. Select agent (round-robin or balanced)
   d. Assign conversation
   e. Track in Redis
   f. Dispatch event
   ↓
8. Return assigned_count
```

### Redis Keys

**Rate Limiting**:
- Pattern: `chatwoot:assignment:{inbox_id}:{agent_id}:*`
- Key: `chatwoot:assignment:{inbox_id}:{agent_id}:{conversation_id}`
- TTL: Equal to `fair_distribution_window` (default 3600 seconds)

**Round-Robin Queue**:
- Key: `chatwoot:round_robin:{inbox_id}`
- Type: List (LPUSH/RPOP operations)
- Persistent (no TTL)

---

## Advantages Over Manual Assignment

| Aspect | Manual | Assignment v2 |
|--------|--------|---|
| **Speed** | Slow (requires human action) | Instant (automatic every 30 min) |
| **Consistency** | Variable (depends on person) | Consistent (follows rules) |
| **Fairness** | Prone to bias | Fair and data-driven |
| **Scalability** | Doesn't scale (1 person = bottleneck) | Scales infinitely |
| **Workload Balance** | Hard to maintain | Automatically balanced |
| **Priority** | Manual judgment | Configurable policies |
| **24/7 Operation** | Requires shifts | Automated |
| **Onboarding** | New agents may be overlooked | New agents automatically included |
| **Audit Trail** | Limited | Full event log |

---

## Integration Points

Assignment v2 integrates with several Chatwoot systems:

1. **Conversation Model**:
   - Reads: `status`, `assignee_id`, `last_activity_at`, `created_at`
   - Writes: `assignee_id`
   - Scopes: `unassigned`, `open`

2. **OnlineStatusTracker**:
   - Reads: Real-time agent online status from Redis
   - Returns: Hash of `{user_id => status}`

3. **Redis**:
   - Rate limiting: Stores assignment keys with TTL
   - Round-robin: Maintains agent queues
   - Performance: All Redis operations are non-blocking

4. **Events System**:
   - Dispatches: `Events::Types::ASSIGNEE_CHANGED`
   - Consumers: Webhooks, notifications, analytics

5. **Assignment Policy**:
   - Reads: Priority, limits, windows, balanced mode
   - Links: Via `InboxAssignmentPolicy`

6. **Capacity Policy** (Enterprise):
   - Reads: Per-inbox limits, exclusion rules
   - Links: Via `AccountUser` and `InboxCapacityLimit`

7. **Labels** (Enterprise):
   - Reads: Conversation labels for exclusion rules
   - Uses: ActsAsTaggableOn gem for label filtering

---

## For Non-Technical Stakeholders

Think of Assignment v2 as an intelligent dispatcher at a taxi company:

### Without Assignment v2
- Customers (conversations) call in and wait on hold
- Someone manually decides which driver (agent) should take each ride
- Some drivers get overloaded while others sit idle
- Customers who called first might not get picked up first
- The dispatcher becomes a bottleneck

### With Assignment v2
- The system automatically dispatches rides to available drivers
- Drivers who are online and not at capacity get new rides
- The system balances workload so no driver gets too many rides at once
- You can set rules: "Prioritize customers waiting longest" or "No driver gets more than 5 rides per hour"
- Drivers with VIP rides (excluded labels) can be handled separately
- Everything happens automatically every 30 minutes

### Benefits
- **Faster**: Customers get assigned immediately
- **Fairer**: All drivers get equal opportunities
- **Scalable**: Works with 5 drivers or 500
- **Configurable**: Rules can be adjusted based on business needs
- **Reliable**: Runs 24/7 without human intervention

---

## Troubleshooting

### "Conversations aren't being assigned"

Check the following in order:

1. **Feature flag**: Is `assignment_v2` enabled for the account?
2. **Assignment policy**: Does the inbox have a linked, enabled assignment policy?
3. **Inbox setting**: Is `enable_auto_assignment` true for the inbox?
4. **Agent availability**: Are any agents online?
5. **Rate limiting**: Are all agents at their rate limit? Check Redis keys
6. **Capacity** (Enterprise): Are all agents at capacity? Check open conversation counts
7. **Exclusion rules** (Enterprise): Are all conversations being excluded by labels or age?
8. **Job running**: Is `PeriodicAssignmentJob` scheduled and running?

### "Assignments are uneven"

- If using round-robin: Check the Redis queue for the inbox
- If some agents never get assignments: Check their online status
- If using balanced selector: Check open conversation counts per agent
- If rate limiting is too strict: Increase the limit or window

### "Too many/too few assignments"

- Check `AUTO_ASSIGNMENT_BULK_LIMIT` (default 100)
- Check rate limiting configuration
- Check capacity limits (Enterprise)
- Check conversation priority (longest_waiting vs. FIFO)

### "Redis keys not expiring"

- Verify `fair_distribution_window` is set correctly
- Check Redis configuration for key eviction policies
- Manually inspect keys: `Redis::Alfred.keys('chatwoot:assignment:*')`

---

## Testing Guidelines

### Test Coverage Touchpoints

**Core Spec Files**:
- `spec/services/auto_assignment/assignment_service_spec.rb` - Verifies open-only assignment, respect for limits, conversation priority, fair distribution, and event dispatching
- `spec/services/auto_assignment/rate_limiter_spec.rb` - Covers Redis key semantics, limit/window handling, and edge cases when configuration is absent
- `spec/services/auto_assignment/round_robin_selector_spec.rb` - Ensures proper Redis-backed round robin queue and handles empty agent pools
- `spec/jobs/auto_assignment/*` - Covers both immediate job and periodic scheduler behavior
- `spec/enterprise/services/enterprise/auto_assignment/*` - Asserts balanced selection, capacity filtering, and exclusion rule behavior

### Key Test Scenarios

1. **Basic Assignment**:
   - Create unassigned, open conversation
   - Create online agent
   - Run assignment service
   - Verify conversation is assigned

2. **Rate Limiting**:
   - Configure rate limit (e.g., 2 per hour)
   - Assign 2 conversations to an agent
   - Verify 3rd conversation goes to a different agent

3. **Capacity Management**:
   - Set capacity limit (e.g., 5 conversations)
   - Create 5 open conversations for an agent
   - Verify agent is filtered out of eligibility

4. **Exclusion Rules**:
   - Configure excluded labels
   - Create conversation with excluded label
   - Verify conversation is not assigned

5. **Priority**:
   - Create multiple conversations with different `last_activity_at`
   - Configure `longest_waiting` priority
   - Verify oldest `last_activity_at` is assigned first

6. **Agent Availability**:
   - Set agent status to 'busy' or 'offline'
   - Verify agent is not eligible
   - Set status to 'online'
   - Verify agent is now eligible

7. **Zero Assignments**:
   - Disable assignment policy
   - Verify 0 assignments occur
   - Set all agents offline
   - Verify 0 assignments occur

---

## Next Steps / Additional Reading

- To enable Assignment v2 for your account, contact your Chatwoot administrator
- For Enterprise features, see the Enterprise-specific capacity policies documentation
- For webhook integrations, refer to the Assignment Events documentation
- For performance tuning, consult the Scaling Chatwoot guide

---

**Last Updated**: November 2024
**Feature Status**: Stable (v2 final)
**Related PR**: #12320
**Architecture**: Modular with Enterprise extensions via `prepend_mod_with`
