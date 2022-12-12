---
title: Sass Mixins
description: Mixins allow us to reuse code in various parts of the framework. Foundation includes mixins for clearfixes, visibility, icons, shapes, and more.
sass:
  - scss/util/_mixins.scss
  - scss/prototype/*.scss
video: 'aiO5nFepdcw'
---

## Importing

Foundation's Sass mixins are all kept in one file: `scss/util/_mixins.scss`. To import it in Sass, use this line of code:

```scss
@import 'util/mixins';
```

Note: These mixins are included by default when using the [ZURB Stack](starter-projects.html#zurb-template) and [Basic Template](starter-projects.html#basic-template) Starter Projects.

## General Mixins

Foundation includes some handy Sass mixins to quickly create styles or to extend and truly customize an existing component. Here is a list of available mixins:

- [CSS Triangle mixin](#css-triangle)
- [Hamburger Icon mixin](#hamburger)
- [Background triangle](#background-triangle)
- [Clearfix](#clearfix)
- [Auto width children](#auto-width)
- [Disable Mouse Outline](#disable-mouse-outline)
- [Element Invisible](#element-invisible)
- [Element Invisible Off](#element-invisible-off)
- [Vertical Center](#vertical-center)
- [Horizontal Center](#horizontal-center)
- [Absolute Center](#absolute-center)

## Prototyping Utility Mixins

Quickly prototype layouts and UI with Foundation's Prototyping Utility mixins. These mixins are great realizing your sketches and mockups into hi-fi coded prototype's ultra fast. [Learn more about Prototyping Utilities](prototyping-utilities.html)

Here is a list of available mixins:

- [Border Box](#border-box)
- [Border None](#border-none)
- [Bordered](#bordered)
- [Box](#box)
- [Display](#display)
- [Font Wide](#font-wide)
- [Font Normal](#font-normal)
- [Font Bold](#font-bold)
- [Font Italic](#font-italic)
- [Style Type Unordered](#style-type-unordered)
- [Style Type Ordered](#style-type-ordered)
- [Overflow](#overflow)
- [Overflow-x](#overflow-x)
- [Overflow-y](#overflow-y)
- [Position](#position)
- [Position Fixed Top](#position-fixed-top)
- [Position Fixed Bottom](#position-fixed-bottom)
- [Rotate](#rotate)
- [RotateX](#rotatex)
- [RotateY](#rotatey)
- [RotateZ](#rotateZ)
- [Border Radius](#border-radius)
- [Border Rounded](#border-rounded)
- [Separator](#separator)
- [Shadow](#shadow)
- [Max Width 100%](#max-width-100)
- [Margin](#margin)
- [Padding](#padding)
- [Text Decoration](#text-decoration)
- [Text Transform](#text-transform)
- [Text Hide](#text-hide)
- [Text Truncate](#text-truncate)
- [Text Nowrap](#text-nowrap)
- [Nth Child](#first)
