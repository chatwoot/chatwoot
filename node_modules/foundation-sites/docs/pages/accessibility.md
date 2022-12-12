---
title: Accessibility
description: Foundation for Sites is a fully-accessible framework. Here are some general guidelines to keep in mind as you make your pages accessible.
---

In addition to the accessibility features built into Foundation's components, be sure to follow best practices for making your site more accessible.

<div class="primary callout">
  <p>Care about accessibility or want to contribute? Submit a Pull Request or get into the [conversation on GitHub](https://github.com/zurb/foundation-sites/labels/accessibility).</p>
</div>

## Basic Principles

- **Structure your document properly.** Use the right HTML tags for the job when marking up navigation, lists, links, controls, and so on.
- **Label everything.** If a control or form element has no text label, add one. You can use the [visibility classes](visibility.html#accessibility) to hide labels visually while maintaining accessibility. Use the `alt` attribute on all images to describe what they are.
- **Don't rely on purely visual cues.** The content of a page should make sense even if page is being read to the user, or if the user is colorblind and can't make use of color-based labeling.
- **Make everything usable on a keyboard and mouse.** Lucky for you, all of our components work with keyboards, mice, and touch screens out of the box.

---

## Types of Disabilities

### Visual

Visually-impaired users may have low vision or be completely blind. For low vision users, proper typographic contrast is important, both size and color. Foreground colors should stand out from background colors. You can use tools to calculate the contrast ratio of your foreground and background colors. The contrast ratio should at least be 1:4.5 for normal text and 3:1 for large text.
Blind users consume the web by reading it using a [screen reader](https://en.wikipedia.org/wiki/Screen_reader). Screen readers read the content of a web page out loud, or write it out as Braille, using certain cues from the HTML to infer meaning.

### Motor

Users with motor disabilities may have trouble using a mouse, or don't use a mouse at all. For this reason, it's very important that your site is fully keyboard-accessible. Visually-impaired users also typically navigate websites using only their keyboard.

When using only the keyboard, the <kbd>tab</kbd> key is the primary way to navigate through a page. However, most screen readers include many shortcut keys to skip around a page. For example, a screen reader can read every heading on a page, or every link, making it easier to find the right content on the page.

More complex components like menus, tabs, or sliders can also typically be used with arrow keys, not just the <kbd>tab</kbd> keys. All of our JavaScript plugins provide advanced keyboard support by default.

### Auditory

If your site has video, provide captions so that users who are deaf or hard-of-hearing can properly view the content.

---

## Foundation and Accessibility

All of Foundation's components are keyboard-accessible and screen reader-friendly. All of our code examples include the required accessibility hooks, but there may be instances where you, as the developer, need to fine-tune the specifics of how those hooks are used. Our JavaScript plugins will automatically add many required attributes to the HTML for you. Refer to each component's documentation to learn how to ensure your markup is screen reader-friendly.

Foundation's CSS makes use of the library [what-input](https://github.com/ten1seven/what-input), which can detect the user's current input device and adjust CSS accordingly. We use it to disable outlines for mouse users, but not keyboard users, who need the outline to know what element on the page has focus.

If you're using the Sass version of Foundation, you can use this mixin to enable the feature on your own components:

```scss
.element {
  @include disable-mouse-outline;
  // ...
}
```

---

## Learn More

### Resources

- [WCAG 2.0 Guide](http://www.w3.org/TR/UNDERSTANDING-WCAG20/)
- [MDN accessibility documentation](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [w3.org Introduction to Accessibility](http://www.w3.org/WAI/intro/accessibility.php)
- [Section 508 government requirements](http://www.section508.gov/)
- [WebAIM certification and training](http://webaim.org/)
- [Web Accessibility Checklist](http://a11yproject.com/checklist.html)

### Tools

- [Tenon accessibility checker](https://tenon.io/index.php)
- [WAVE Chrome plugin - free accessibility checker](http://wave.webaim.org)
- [Color Contrast Checker](http://webaim.org/resources/contrastchecker)
- [ChromeVox screen reader plugin for Chrome](http://www.chromevox.com)
- [JAWS screen reader for Windows](http://www.freedomscientific.com/Products/Blindness/Jaws)
- [NVDA screen reader for Windows - Free](http://www.nvaccess.org/download/)
