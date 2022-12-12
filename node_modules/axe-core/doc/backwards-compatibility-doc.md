# Backwards Compatibility in axe-core

## What is part of the public axe-core API?

The axe-core API includes:

- Any APIs documented here: [https://github.com/dequelabs/axe-core/blob/develop/doc/API.md](https://github.com/dequelabs/axe-core/blob/develop/doc/API.md)
- The selectors generated and included in the node information in the results arrays for any given HTML page
- The JSON structures passed into and out of any API functions
- Any functions in the `axe.utils` and `axe.commons` collections that are used by one of our standard rules (this document refers to these as the “Public Utils”). This includes use in any of the “matches”, “eval” and “after” functions.
- The implicit function signature of the matches, eval and after functions (the names of the parameters that are passed-to the functions and the values returned by them)

## What is not included in the public axe-core API?

Any other function or attribute on the axe object is not considered part of the public API and is therefore not covered by the guarantee in this document.

## What do we guarantee for the public axe-core API?

We guarantee that the API signatures and the return values of functions will not break in patch or minor release versions except that we may add items to JSON structures in minor releases or override parameters. We will not remove items from JSON structures.

In a minor release, we may change the implementation of Public Utils to fix bugs or improve performance. This means that a call to a Public Util may return a different value across patch versions.

We will not add or remove rules in a patch release. We will not add support for new technologies in a patch release. We will endeavour to return the exact same results across patch releases with the exception of changes that are due to bug fixes. This means that the likelihood of a patch release finding issues on a page that was clean in a previous release is very close to zero but not zero.

In a minor release, we may add support for new technologies in the Public Utils or in existing rules and we may add or disable rules. We may also change an experimental rule to become a standard rule (essentially equivalent to adding rule). This means that pages that did not return violations in a particular minor release may return violations in a subsequent release. Rule tags, including the "wcag\*" tags, and whether or not something is reported as best-practice can be changed in minor releases.

If the HTML page is unchanged, calls to the analysis function(s) when compared across minor or patch releases will return the same exact selector for the nodes in any of the result arrays. If the HTML page has changed, it is possible for the selector to be different but it is not guaranteed that the selector will be different.

APIs may be deprecated in a major or minor release. APIs that have been deprecated for 6 months or more will be removed in the next major release.

A major or a minor release may introduce new Public Utils.

Major releases may remove rules.

### Table: Summary of What Deque Guarantees with Public axe-core API

|                                               | Major                                                   | Minor                 | Patch                      |
| :-------------------------------------------- | :------------------------------------------------------ | :-------------------- | :------------------------- |
| **New Technologies**                          |                                                         |                       |                            |
| Support for new technologies\*                | May add support                                         | May add support       | Will not add support       |
| **APIS**                                      |                                                         |                       |                            |
| API signatures and return values of functions | May break                                               | Will not break        | Will not break             |
| APIs deprecated                               | May be deprecated                                       | May be deprecated     | Will not be deprecated     |
| APIs removed                                  | May be removed (will remove previously deprecated APIs) | Will not be removed   | Will not be removed        |
| **Public Utils**                              |                                                         |                       |                            |
| Implementation of Public Utils                | May change                                              | May change            | Will not change            |
| New public Utils                              | May add                                                 | May add               | Will not add               |
| **Rules**                                     |                                                         |                       |                            |
| Add rules                                     | May add                                                 | May add               | Will not add               |
| Disable or remove rules                       | May remove (will remove previously deprecated rules)    | May disable or remove | Will not disable or remove |
| Rule tags                                     | May add or remove                                       | May add or remove     | Will not change            |
| Deprecate rules                               | May deprecate                                           | May deprecate         | Will not deprecate         |

\*_New OSes, Browsers, ATs, new standards (e.g. introduction of ARIA), new versions of standards (e.g. WCAG 2.1)_

## Implications

### Breaking Builds

Patch release upgrades can be applied in CI environments with a high degree of certainty that breakages will not be due to changes in the release. The chance is, however, not zero.

### Custom Rules

A custom rule configuration (with-or-without custom rules) is guaranteed to run on any newer version that shares the same major version number as the version for which it was created. A custom rule configuration (with-or-without custom rules) is not guaranteed to work with an older version of axe-core than the version for which it was created.

You can write custom rules that utilize the Public Utils and the parameters that are passed to a check function, secure in the knowledge that the API will not change unless a major version is released.

However, because we can introduce new rules, it is possible that a custom rule configuration will return additional results when run against a new minor release and may return different results when run against a newer patch release.

A custom rule configuration may return different results (more or fewer) when run on a newer patch release due to bug fixes.

A major release may completely break a custom rule or even all custom rules because of a change to any of the APIs.

### Table: Implication of axe-core Updates on Custom Rule Function

| Axe-core Release Semantic Version              | Example | Simple Custom Rules    | Complex Custom Rules   |
| :--------------------------------------------- | :------ | :--------------------- | :--------------------- |
| Prior release (different major release number) | 1.3.4   | Not guaranteed to work | Not guaranteed to work |
| Release used to create custom rules            | 2.0.0   | Guaranteed to work     | Guaranteed to work     |
| Next release (minor release)                   | 2.1.0   | Guaranteed to work\*   | Guaranteed to work\*   |
| Next +1 release (patch release)                | 2.1.1   | Guaranteed to work\*   | Guaranteed to work\*   |
| Next +2 release (major release)                | 3.0.0   | Not guaranteed to work | Not guaranteed to work |

\*_Minor and patch releases will not break custom rules, but testing results may vary from those tests performed with previous minor and patch releases of axe-core. There may be inconsistencies between what Attest reports and what Comply reports._

Please note that with even small changes in versions for simple custom rules, there may be inconsistencies between what Attest reports and what Comply reports. For best results, in both cases, versions should match exactly.

### Tracking Issues Over Time

Many systems attempt to identify unique issues using a combination of the page and state, the rule-id and the selector to track an issue across time and across calls to the analysis functions. This will work reliably across patch releases. This could break if a rule is removed or split up across minor releases. In a major release, this could break for the additional reason of a possible change in the selector generation (this did happen in the changes between 2.6.x and 3.x).

### Comply

Comply has the ability to add labels and comments to issues and to mark issues as ignored. Comply will lose this information when it is not able to track issues across time. This means that historical issue information may be lost when upgrading to a newer major version of axe-core.
