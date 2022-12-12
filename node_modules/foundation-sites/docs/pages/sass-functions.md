---
title: Sass Functions
description: Behind the scenes, Foundation is powered by a set of utility Sass functions that help us work with colors, units, selectors, and more.
sass:
  - scss/util/*.scss
  - '!scss/util/_breakpoint.scss'
  - '!scss/util/_mixins.scss'
---

## Importing
 
All of Foundation's Sass utilities are in the folder `scss/util`, and broken up into multiple files by category. You can import every utility file at once using this line of code:

```scss
@import 'util/util';
```

Or, utilities can be imported individually.

```scss
// Color manipulation
@import 'util/color';

// Selector generation
@import 'util/selector';

// Unit manipulation and conversion
@import 'util/unit';

// Value checking and extraction
@import 'util/value';
```

<div class="callout warning">
  <p>Variables, functions, or mixins prefixed with <code>-zf-</code> are considered part of the internal API, which means they could change, break, or disappear without warning. We recommend sticking to only the public API, which is documented below.</p>
</div>
