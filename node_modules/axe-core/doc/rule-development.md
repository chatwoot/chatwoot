# Developing Axe-core Rules

Before you start writing axe-core rules, be sure to create a proposal for them in a github issue. Read [Proposing Axe-core rules](./rule-proposal.md) for details.

A rule is a JSON Object that defines a test for axe-core to run. At a high level, think of a rule as doing two things. First it finds all elements that it should test, and after that it runs a number of checks to see if those selected elements pass or fail the rule.

## Rule Select and Matches

Each rule has a `selector` and optionally a `matches` property. The selector is a CSS selector. Each element matching this selector will be tested by the rule, unless the matches function says otherwise. The `matches` property is a reference to a function that returns a boolean, which indicates if the element should be tested.

The last thing that may influence if an element is selected for testing in the rule is it's visibility. By default, hidden elements are ignored by the rule, unless the `excludeHidden` is set to 'false'.

## Using Checks in Rules

The actual testing of elements in axe-core is done by checks. A rule has one or more checks which end up generating a result. There are three properties with which to define a rule's checks. Each of them deals differently:

- **All**: Takes an array of check names, **all** of which has to return true for the rule to pass.
- **none**: Takes an array of check names, **none** of which can to return true for the rule to pass.
- **any**: Takes an array of check names, **at least one** of which has to return true for the rule to pass.

## Rule Properties

| Prop. Name           | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| id                   | Unique identifier for the rule                                      |
| selector             | CSS Selector that matches elements to test                          |
| matches              | Function to further filter the outcome of the selector              |
| excludeHidden        | Should hidden elements be excluded                                  |
| all                  | Checks that must all return true                                    |
| any                  | Checks of which at least one must return true                       |
| none                 | Checks that must all return false                                   |
| pageLevel            | Should the rule only run on the main window                         |
| enabled              | Does the rule run by default                                        |
| tags                 | Grouping for the rule, such as wcag2a, best-practice                |
| metadata.description | Description of what a rule does                                     |
| metadata.help        | Short description of a violation, used in the axe extension sidebar |

## Check Properties

| Prop. Name                   | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| id                           | Unique identifier for the check                |
| evaluate                     | Evaluating function, returning a boolean value |
| options                      | Configurable value for the check               |
| after                        | Cleanup function, run after check is done      |
| metadata.impact              | "minor", "serious", "critical"                 |
| metadata.messages.pass       | Describes why the check passed                 |
| metadata.messages.fail       | Describes why the check failed                 |
| metadata.messages.incomplete | Describes why the check didn’t complete        |

Incomplete results occur when axe-core can’t produce a clear pass or fail result,
giving users the opportunity to review it manually. Incomplete messages can take
the form of a string, or an object with arbitrary keys matching the data returned
from the check.

A pass message is required, while fail and incomplete are dependent on the check result.

### Incomplete message string

As one example, the audio and video caption checks return an incomplete string:

```js
messages: {
  pass: 'Why the check passed',
  fail: 'Why the check failed',
  incomplete: 'Why the check returned undefined'
}
```

### Incomplete message object with missingData

As another example, the color-contrast check returns missingData to aid in
remediation. Here’s the message format:

```js
messages: {
  pass: 'Why the check passed',
  fail: 'Why the check failed',
  incomplete: {
    bgImage: 'The background color could not be determined due to a background image',
    default: 'fallback string'
  }
}
```

To wire up an incomplete message with a specific reason it returned undefined,
the check needs matching data. Otherwise, it will fall back to the `default` message.
Reasons are arbitrary for the check (such as 'bgImage') but they must match the
data returned:

```js
this.data({
  missingData: 'bgImage'
});
```

# Hierarchical rules

Axe-core handles shadow DOM and cross-domain iframe rules very well - as long as you take care in the design and implementation of your rule. Any rule that evaluates the DOM hierarchy needs to think about what happens across shadow DOM boundaries and iframe boundaries.

The rule callbacks all receive both a `node` and a `virtualNode` argument (in addition to the `options` argument). `node` points to the DOM Node that is to be evaluated, whereas `virtualNode` points to the node in the flattened tree (the hierarchy that shadow DOM creates that is used for parent child relationships across shadow DOM boundaries).

If your rule looks at any hierarchical context (parents or children) then you need to operate on the `virtualNode` for those operations. Calls to `isHidden` and the accessible name calculation calls will all evaluate the hierarchy. The commons and utils functions will all fetch the `virtualNode` from the flattened tree if you use the `node` implementation (and then simply call the virtualNode one) and are there for backwards compatibility. This backwards compatibility comes at a performance cost that can be avoided by simply using the `virtualNode` to start with. We will ask you to change this during PR review, so you might as well just start out by using the `virtualNode`.

## iframes

Rules that evaluate the structure and/or the number of elements on the entire page (for example the heading nesting rule, or the landmark rules) will need to do this evaluation across iframe boundaries. What this means is that the check function instead of determining pass/fail/incomplete, performs a data gathering function. This data is then passed up the iframe hierarchy to the top window where it is passed into the `after` function, which does the evaluation of the gathered data and determines pass/fail.

## Rules of Thumb for Rule Code Reviewers

Rules of thumb for determining whether `virtualNode` should be used - if any of the answers to the following questions is yes, then it should use shadow DOM and `virtualNode`:

1. Is it using the non-virtualNode version of a function that wraps the flattened tree lookup?
2. Is it evaluating the DOM hierarchy?

Rules that do this MUST have shadow DOM test cases that show passes and fails across the shadow DOM boundary.

Rules of thumb for determining whether an `after` function is required - if any of the answers to the following questions is yes:

1. Does the rule evaluate number of things on a page?
2. Does the rule evaluate hierarchy of things across a whole page?

Rules that use an `after` function MUST have iframe test cases that assert correct data passing between iframes and handle all the relevant cases across iframes.
