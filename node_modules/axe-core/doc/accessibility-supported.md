# How we make decisions on rules

In order to adhere to the manifesto and at the same time be useful to developers and content creators, we evaluate all rules according to strict normative WCAG 2 interpretation. We also pay very strong attention to the normative portion of WCAG 2 known as [accessibility supported](https://www.w3.org/TR/WCAG20/#accessibility-supporteddef).

## Accessibility supported

Accessibility supported means that in order for a technique to pass, it must work in some predefined set of browsers and assistive technologies. For axe-core this means that for a screen reader, browser, or environment to be added to the list of supported combinations, the following two criteria must be met:

1. Be used by more than 1% of users (currently extrapolated from the [WebAims Screen Reader User Survey](https://webaim.org/projects/screenreadersurvey8/#browsercombos))
1. Introduce new coverage for a screen reader, browser, or environment not currently accessibility supported

We currently test the following AT combinations for support

1. VoiceOver and Safari on OS X
1. VoiceOver and Safari on iOS
1. JAWS and IE11 on Windows
1. JAWS and Chrome on Windows
1. NVDA and Firefox on Windows
1. Talkback and Chrome on Android
1. Dragon and Firefox on Windows

## Impact on ARIA

For some technologies, like ARIA, we have a dilemma in that the spec is approved before supported and we have to weigh a balance between something that conforms to the spec, but does not yet work. When we do this, we favor the accessibility supported principle over the spec but we temper this with the impact of using an unsupported feature. Here is how we do this:

1. If the feature's use is supported by all platforms: allow, else
1. If the feature's use does not have a negative impact on accessibility: allow, else
1. If we can detect a fallback: allow, else
1. disallow the feature's use until it is supported

In addition, we disallow invalid attributes starting with `aria-` and invalid attribute values as these are highly likely to have a negative impact on accessibility because of the scenarios under which these are likely to occur (this is so we can act as a useful linting tool for developers).

## Best practices

We recognize that there are best practices that significantly improve the usability of application, even though they are not strictly required in order to conform with WCAG 2. We develop the best practice rules to help content developers to identify these and adhere to them.

We recognize that this topic is somewhat controversial and the rules we have represent Deque's opinion on what constitutes a best practice.
