# html-has-lang

<html> elements must have the lang prop.

## Rule details

This rule takes no arguments.

### Succeed
```jsx
<html lang="en">
<html lang="en-US">
<html lang={language}>
```

### Fail

```jsx
<html>
```

## Accessibility guidelines
- [WCAG 3.1.1](https://www.w3.org/WAI/WCAG21/Understanding/language-of-page)

### Resources
- [axe-core, html-has-lang](https://dequeuniversity.com/rules/axe/3.2/html-has-lang)
- [axe-core, html-lang-valid](https://dequeuniversity.com/rules/axe/3.2/html-lang-valid)
