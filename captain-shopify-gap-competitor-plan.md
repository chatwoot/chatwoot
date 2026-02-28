# Captain + Shopify Gap Analysis and Competitor Comparison Plan

## 1. Purpose

Create a clear plan to:
1. Identify product and technical gaps in current Captain + Shopify experience.
2. Compare current behavior with leading support/commerce competitors.
3. Convert findings into a prioritized implementation roadmap.

## 2. Current Baseline (Chatwoot)

Current implemented scope:
1. Shopify product search via Captain tool.
2. Shopify order lookup by contact email/phone.
3. Captain V2 + Shopify connection gating.
4. Fallback identity extraction from conversation text/history.

Out of scope in current version:
1. Order lookup by order ID.
2. Checkout/cart workflows.
3. Deep post-purchase workflows (returns/exchanges automation).
4. GraphQL-first Shopify data layer.

## 3. Competitor Set

Primary competitors for comparison:
1. Gorgias (Shopify-first support workflows).
2. Zendesk + Shopify integration.
3. Intercom (Fin + commerce integrations).
4. Tidio / similar SMB Shopify-focused AI support stacks.

Note: This plan focuses on capability and UX patterns, not pricing.

## 4. Comparison Dimensions

Evaluate each competitor and Chatwoot against the same rubric:
1. Identity resolution robustness (email/phone/order context).
2. Order lookup depth (status, fulfillment, tracking, edits).
3. Product intelligence quality (search relevance, detail depth).
4. Agent handoff quality after failed AI attempts.
5. Conversation memory and context carry-forward.
6. Actionability (read-only vs operational actions).
7. Error transparency and recovery UX.
8. Admin visibility (logs, traceability, debugging).
9. Setup friction (scopes, auth, reauthorization handling).
10. Reliability under ambiguous user messages.

## 5. Gap Assessment Method

### Step 1: Baseline test scenarios (Chatwoot)
Run a fixed scenario pack:
1. Product availability questions.
2. Specific product detail follow-up.
3. Order status lookup with:
- email present in contact
- email only in user message
- confirmation-only follow-up (`Yes`)
- phone-only identity
4. No-result and provider-error paths.

### Step 2: Competitor behavior capture
For each scenario:
1. Capture response quality.
2. Capture number of turns to resolution.
3. Capture failure behavior and escalation quality.

### Step 3: Scorecard
Use 0-3 scoring per dimension:
1. `0` = missing
2. `1` = weak/manual
3. `2` = functional
4. `3` = strong/best-in-class

## 6. Initial Gap Hypotheses

Likely current gaps to validate:
1. Order retrieval flexibility:
- No order-id lookup path yet.
2. Product detail richness:
- Limited details when Shopify product metadata is sparse.
3. Proactive recovery:
- AI asks for identity but does not persist verified identity for next turns.
4. Action workflows:
- No built-in operational actions (refund/cancel/update address/escalate with structured payload).
5. Observability UX:
- Logs exist, but no dedicated operational dashboard for Shopify tool outcomes.

## 7. Roadmap Framework (Post-Analysis)

### Phase A (Quick Wins)
1. Improve prompt/tool guidance for identity confirmation.
2. Add operator-facing diagnostics for identity source and lookup failure reason.
3. Expand product response template quality.

### Phase B (Core Capability)
1. Add optional order lookup by order ID (feature-flagged).
2. Persist verified contact identity with safeguards.
3. Add richer order timeline output (payment, fulfillment, tracking where available).

### Phase C (Strategic)
1. Move Shopify reads to GraphQL Admin API.
2. Add structured post-purchase workflows.
3. Add KPI dashboard for resolution rate and lookup success rate.

## 8. Success Metrics

Track before/after:
1. First-response resolution rate for order status requests.
2. Median turns to order lookup completion.
3. Percentage of order lookups failing with missing identifier.
4. Product query relevance satisfaction (manual QA scoring).
5. Human handoff rate for Shopify intents.

## 9. Deliverables

1. Gap matrix (Chatwoot vs each competitor by dimension).
2. Ranked backlog of gaps with impact and effort.
3. Implementation proposal with phased milestones.
4. QA plan for each planned feature.

## 10. Execution Checklist

1. Finalize scenario pack.
2. Run Chatwoot baseline and record outputs.
3. Run competitor comparisons and record outputs.
4. Complete scoring matrix.
5. Convert top gaps into engineering tickets.
6. Validate each implemented item against the same scenario pack.
