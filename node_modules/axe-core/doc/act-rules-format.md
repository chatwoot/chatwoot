# W3C Standardized Rules

Deque Systems is one of leading organizations in the development of standardized accessibility conformance testing rules. The [axe-core rules proposal format](./rule-proposal.md) is an adaptation of the [Accessibility Conformance Testing Rules Format](https://www.w3.org/TR/act-rules-format/).

There are two ways a rule written in the axe-core rule format can be transformed into the ACT Rules format:

## Method 1: Create a single rule

This method is useful for rules with a small number of checks.

1. Add the test input type to it: `rendered page`
2. Add an `assumptions` section, add possible assumptions to it
3. Add an `outcomes` section, describing the different possible outcomes of the rule
4. Add a `Validation Tests` section, that links to the integration tests
5. Update the check to return pass/fail/cantTell instead of true/false/undefined
6. Add control flow to the checks:

- `any` checks should only return `fail` in the last step. All steps leading up to it either return `pass` or say `continue to the next step`.
- `all` and `none` checks should only return `pass` in the last step. All steps leading up to it either return `fail` or say `continue to the next step`.

7. Rename `checks` to `steps` and add a `step X` (where X is the step number) to the heading with the check name.
8. Replace the `tags` section with a `Accessibility Requirements`. The requirements can be determined based on the `wcag###` tags.

## Method 2: Create a rule group

This method is useful for larger rules with `any` checks. This effectively turns every check into its own rule, and turns the rule into a rule group.

1. Copy each check into a new document
2. Add a `steps` heading
3. Add the test input type to it: `rendered page`
4. Add an `assumptions` section, add possible assumptions to it
5. Add an `outcomes` section, describing the different possible outcomes of the rule
6. Copy the `selector` section from the original rule into the new rule documents
7. Update the check to return pass/fail/cantTell instead of true/false/undefined
8. Add a `Validation Tests` section, that links to only those integration tests relevant for this check (now a new rule).
9. Indicate that the new rule is part of a group, using the original axe-core rule ID as the group name.
10. Replace the `tags` section with a `Accessibility Requirements`. The requirements can be determined based on the `wcag###` tags.
