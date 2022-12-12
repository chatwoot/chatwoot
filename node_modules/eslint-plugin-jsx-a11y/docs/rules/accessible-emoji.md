# [Deprecated] accessible-emoji

Emoji have become a common way of communicating content to the end user. To a person using a screenreader, however, they may not be aware that this content is there at all. By wrapping the emoji in a `<span>`, giving it the `role="img"`, and providing a useful description in `aria-label`, the screenreader will treat the emoji as an image in the accessibility tree with an accessible name for the end user.

## Rule details

This rule takes no arguments.

### Succeed
```jsx
<span role="img" aria-label="Snowman">&#9731;</span>
<span role="img" aria-label="Panda">🐼</span>
<span role="img" aria-labelledby="panda1">🐼</span>
```

### Fail
```jsx
<span>🐼</span>
<i role="img" aria-label="Panda">🐼</i>
```

## Accessibility guidelines
- [WCAG 1.1.1](https://www.w3.org/WAI/WCAG21/Understanding/non-text-content.html)

### Resources
- [Léonie Watson, Accessible Emoji](http://tink.uk/accessible-emoji/)
