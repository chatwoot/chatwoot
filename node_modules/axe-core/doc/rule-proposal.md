# Proposing Axe-core Rules

This document outlines the process of proposing a rule. For a technical description on how to build a rule, read [Developing Axe-core Rules](./rule-development.md)

Before you start coding a new rule for axe-core, you _must_ create a Github issue to document the rule you want to create. There are many considerations to writing a good rule. It must have no false positives, which is difficult, because there are always many many edge cases to consider. Additionally, a known problem of accessibility testing, is that not all testers hold the same interpretation of the accessibility guidelines. All rules _must_ be consistent with the interpretation of Deque Systems, the developer behind Axe-core.

In addition to giving the axe-core development team an opportunity to provide feedback on the proposed rule, the Github Issue will serve as documentation of that rule for the future.

## WCAG interpretation

Please read our [principles for deciding on rules](./accessibility-supported.md).

## Rules Format

All Github issues that propose a rule must be tagged as _rule_, and must use the following format:

### Intro

In one sentence, describe what the rule does.

Example: "Ensures ARIA attributes are allowed for an element's role"\

#### Rule help

In one sentence, describe how to resolve the issue.

Example: "Elements must only use allowed ARIA attributes"

#### Tags

Indicate which tags the rule should use.

Example: wcag2a, wcag211, cat.keyboard

### Selector

If possible using a CSS selector, otherwise describe in one sentence using plain language what elements the rule selects.

Example 1: `input[type=checkbox][name]`

Example 2: Select each node that has an attribute starting with `aria-`.

### Checks:

Make each check a subheading of `checks`. Give the check name in the heading, and indicate if the check type is `any`, `all` or `none`.

In short sentences, using plain language, describe what conditions will lead to the check returning false, true or undefined. Keep the steps simple and short. You don't have to write out all the logic. Preferably not, just give the high level view of what the check does.

**Example 1:**

`###` aria/allow-attr (any)

1. Look up the element role
2. Look up a list of aria attributes allowed for that role
3. Return false if the element has aria attributes not in the list
4. Otherwise return true

**Example 2:**

`###` keyboard/focusable-no-name (none)

1. If the element is not in the focus order, return false
2. If the element has an accessible name, return false
3. Otherwise return true

## Best practices

For rule design, consider the following as best practices:

1. Rules should only have one `none` check so that the error message is specific
2. Rules should not combine `any` and `none`, these should be broken out into separate rules
3. Checks should each only test a single specific case (either a passing technique or a single failing test)

## Template

Use this template when creating the issue:

```markdown
# {{ Rule name }}

{{ Rule description }}

{{ Rule help }}

**Tags:** {{ tag, tag, tag }}

## Selector

{{ selector }}

## Checks

### {{ Check name 1 }} ( any / all / none )

1.

### {{ Check name 2, optional }} ( any / all / none )

1.
```

## W3C Standardized Rules

Deque Systems is one of leading organizations in the development of standardized accessibility conformance testing rules. The above format is an adaptation of the [Accessibility Conformance Testing Rules Format](https://www.w3.org/TR/act-rules-format/).

For details on how the above format maps to the ACT Rules format, see [act-rules-format.md](./act-rules-format.md).
