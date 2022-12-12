---
title: Prototyping Utilities
description: Quickly prototype layouts and UI with Foundation's Prototyping Utilities. These optional classes and mixins are great for quickly turning sketches and mockups into coded prototypes.
video: Xhc_KUJMEuk
sass:
  - scss/prototype/*.scss
---

<h4><strong>Prototype to Production</strong></h4>

Prototyping allows us to see problems more clearly—and often earlier—in the development process. Designs in sketches or wireframes only get us so far in understanding the behavior, feasibility, and cost (time or resources) of implementation. Prototyping processes foster collaboration where designers and developers work closely together find better solutions.

Sometimes prototype code is meant to be thrown away, and that's ok. While in early stage development it's extremely valuable to get ideas and interactions up and shared with stakeholders for scrutiny. This is how ideas get fleshed out and improved. It's not code we're delivering, it's a solution to a problem. Get the idea out, get feedback, iterate, repeat. Then when all parties are satisfied the right approach is being taken, go back to clean it up and refactor.

Foundation's Prototyping Utilities help you build coded prototypes from scratch ultra-fast. This allows you to get to right answer faster through feedback and experimentation. From positioning to visual styles, there are a range of utilities to choose from. Every Utility has a mixin, so you can use your own custom classes or swap classes for mixins in production for cleaner markup.

#### Prototype mode is **disabled by default!**

Not all projects require Prototyping Utilities and adding utility classes like these increase your CSS file size especially if you're not using all of them. For these reasons Prototype mode is *disabled by default*.

<div class="primary callout">
	<p>
		Many Prototype classes use `!important` to ensure that these they aren't overridden by more specific selectors. This framework conscientiously avoids using `!important` declarations. Please note that we have only inserted `!important` on those specific **CSS** properties which in no case should be overridden.
	</p>
</div>

---

## Enabling Prototype Mode

<div class="warning callout">
	<p>
		Prototyping classes like these below should only be used for prototyping tasks. Also if you are using **Sass**, we encourage you to use **[Prototyping Mixins](#sass-mixins)** instead.
	</p>
</div>

If you're using the CSS version of Foundation, you can generate a <a href="https://foundation.zurb.com/sites/download">custom download of Foundation</a> with prototype mode enabled. If you're using the Sass version of Foundation, you can enable prototype mode in two ways:

If you use the `foundation-everything()` mixin in your main Sass file, just pass in `$prototype: true` to enable the prototype mode.

```scss
@include foundation-everything($prototype: true);
```

If you included each component manually (like our starter projects do), open up your `app.scss` file and simply comment in:

```scss
// @include foundation-prototype-classes;
```

So it will look like:

```scss
@include foundation-prototype-classes;
```

You can instead import only the specific utility classes that you need. To make it easy, the full list is included below:

```scss
@include foundation-prototype-typescale;
@include foundation-prototype-text-utilities;
@include foundation-prototype-text-transformation;
@include foundation-prototype-text-decoration;
@include foundation-prototype-font-styling;
@include foundation-prototype-list-style-type;
@include foundation-prototype-rounded;
@include foundation-prototype-bordered;
@include foundation-prototype-shadow;
@include foundation-prototype-arrow;
@include foundation-prototype-separator;
@include foundation-prototype-overflow;
@include foundation-prototype-display;
@include foundation-prototype-position;
@include foundation-prototype-border-box;
@include foundation-prototype-border-none;
@include foundation-prototype-sizing;
@include foundation-prototype-spacing;
```

Looking for more customization? Click here for the [Sass Reference](#sass-reference)

---

## Responsive breakpoints

<div class="alert callout">
  <p>Responsive breakpoints is disabled by default.</p>
</div>

These prototype classes also have an optional mobile first responsive classes  so that setting a class will apply to the small breakpoint and large unless overridden by a class for a larger breakpoint. <br>
You can easily enable these classes by setting `$global-prototype-breakpoints` to `true`.

```html
<p class="medium-text-uppercase">This text will be uppercase for medium and up.</p>
<p class="large-text-lowercase">This text will be lowercase for large breakpoint.</p>
```

You can also customise things by choosing to add responsive breakpoints only for specific prototype helpers that you would need as responsive classes. <br>
For example, text transformation classes have a breakpoint variable `$prototype-transformation-breakpoints` which is set to `$global-prototype-breakpoints` which is set to `false` by default. For enabling responsive breakpoints for text transformation classes, simply set:

```scss
$prototype-transformation-breakpoints: true;
```

---

## Component Styling

These `.radius`, `.rounded`, `.bordered` & `.shadow` classes can be used independently or together to style the component by rounding its corners, giving light borders, and creating shadow to it respectively. Mostly used in buttons, cards, tables, images and many more.

<div class="primary callout">
	**Sass Tip**: You can use [Shadow](#shadow) mixin to create something like `shadow-hover-focus`. [Codepen example](http://codepen.io/IamManchanda/pen/XMRMwo)
</div>

<p>
  <a class="" data-open-video="1:06"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

#### Buttons

```html_example
<button type="button" class="button radius bordered shadow primary">Primary</button>
<button type="button" class="button rounded bordered shadow secondary">Secondary</button>
<button type="button" class="button radius bordered shadow success">Success</button>
<button type="button" class="button rounded bordered shadow alert">Alert</button>
<button type="button" class="button radius bordered shadow warning">Warning</button>
```

#### Switches

Please note that you need to add `rounded` class with `switch-paddle` and not `switch`.

```html_example
<div class="switch">
  <input class="switch-input" id="exampleSwitch" type="checkbox" name="exampleSwitch">
  <label class="switch-paddle rounded" for="exampleSwitch">
    <span class="show-for-sr">Download Kittens</span>
  </label>
</div>
```

#### Cards

```html
<div class="radius bordered shadow card">
  <img src="https://placehold.it/500x250">
  <div class="card-divider">
    Styled Card
  </div>
  <div class="card-section">
    <h4>This is a card.</h4>
    <p>It has an easy to override visual style, and is appropriately subdued.</p>
  </div>
</div>
```

<div class="docs-code-live">
	<div class="grid-x grid-margin-x">
		<div class="cell medium-4">
			<div class="radius bordered shadow card">
			  <img src="assets/img/generic/rectangle-1.jpg">
			  <div class="card-divider">
			    Styled Card
			  </div>
			  <div class="card-section">
			    <h4>This is a card.</h4>
			    <p>It has an easy to override visual style, and is appropriately subdued.</p>
			  </div>
			</div>
		</div>
		<div class="cell medium-4">
			<div class="radius bordered shadow card">
			  <img src="assets/img/generic/rectangle-1.jpg">
			  <div class="card-divider">
			    Styled Card
			  </div>
			  <div class="card-section">
			    <h4>This is a card.</h4>
			    <p>It has an easy to override visual style, and is appropriately subdued.</p>
			  </div>
			</div>
		</div>
		<div class="cell medium-4">
			<div class="radius bordered shadow card">
			  <img src="assets/img/generic/rectangle-1.jpg">
			  <div class="card-divider">
			    Styled Card
			  </div>
			  <div class="card-section">
			    <h4>This is a card.</h4>
			    <p>It has an easy to override visual style, and is appropriately subdued.</p>
			  </div>
			</div>
		</div>
	</div>
</div>

#### Tables

```html
<table class="radius bordered shadow">
	<!-- My Table goes here -->
</table>
```

<div class="docs-code-live">
	<table class="radius bordered shadow">
	  <thead>
	    <tr>
	      <th width="200">Table Header</th>
	      <th>Table Header</th>
	      <th width="150">Table Header</th>
	      <th width="150">Table Header</th>
	    </tr>
	  </thead>
	  <tbody>
	    <tr>
	      <td>Content Goes Here</td>
	      <td>This is longer content Donec id elit non mi porta gravida at eget metus.</td>
	      <td>Content Goes Here</td>
	      <td>Content Goes Here</td>
	    </tr>
	    <tr>
	      <td>Content Goes Here</td>
	      <td>This is longer Content Goes Here Donec id elit non mi porta gravida at eget metus.</td>
	      <td>Content Goes Here</td>
	      <td>Content Goes Here</td>
	    </tr>
	    <tr>
	      <td>Content Goes Here</td>
	      <td>This is longer content Donec id elit non mi porta gravida at eget metus.</td>
	      <td>Content Goes Here</td>
	      <td>Content Goes Here</td>
	    </tr>
	    <tr>
	      <td>Content Goes Here</td>
	      <td>This is longer Content Goes Here Donec id elit non mi porta gravida at eget metus.</td>
	      <td>Content Goes Here</td>
	      <td>Content Goes Here</td>
	    </tr>
	  </tbody>
	</table>
</div>

#### Images

```html
<img src="https://placehold.it/150x150" class="radius">
```

<div class="docs-code-live margin-bottom-1">
	<img src="https://placehold.it/150x150" class="radius">
</div>

---

## Arrow Utility

Mostly used as dropdown arrows for navigation.

```html
<div class="arrow-down"></div>
<div class="arrow-up"></div>
<div class="arrow-right"></div>
<div class="arrow-left"></div>
```

<div class="arrow-down display-inline-block margin-right-1"></div>
<div class="arrow-up display-inline-block margin-right-1"></div>
<div class="arrow-right display-inline-block margin-right-1"></div>
<div class="arrow-left display-inline-block"></div>

---

## Separator

This creates a tiny separator below the heading of an element and is usually used within the heading of a section.

<div class="primary callout">
	You don't need to use [Text alignment classes](typography-helpers.html#text-alignment) as this separator utility deals with the alignment of the text itself.
</div>

```html
<h3 class="separator-left">Lorem</h3>
<h3 class="separator-center">Ipsum Dolor</h3>
<h3 class="separator-right">Tempor</h3>
```

<div class="docs-code-live">
	<div class="grid-x grid-margin-x">
		<div class="cell small-12 medium-4">
			<h3 class="separator-left">Lorem</h3>
		</div>
		<div class="cell small-12 medium-4">
			<h3 class="separator-center">Ipsum Dolor</h3>
		</div>
		<div class="cell small-12 medium-4">
			<h3 class="separator-right">Tempor</h3>
		</div>
	</div>
</div>

---

## Font Styling

You can use font styling to style your text. You can change the font styling by adding `font-normal`, `font-bold`, `font-italic` to an element. You can also wider the text of an element with `font-wide`.

```html_example
<p class="font-wide">Lorem ipsum dolor sit amet, consectetur adipisicing elit.</p>
<p class="font-normal">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
<p class="font-bold">Perspiciatis tempore cumque, magni aspernatur, quidem. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse</p>
<p class="font-italic">Lorem minus, placeat, cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.iure voluptas aliquam tempora neque?</p>
```

---

## List Styling

<div class="primary callout">
	Please note that [Unbulleted lists](typography-helpers.html#un-bulleted-list), `.no-bullet` is enabled by default for both ordered and unordered lists.
</div>

#### Unordered Lists

```html
<ul class="no-bullet"></ul>
<ul class="list-disc"></ul>
<ul class="list-circle"></ul>
<ul class="list-square"></ul>
```

#### Ordered Lists

```html
<ol class="no-bullet"></ol>
<ol class="list-decimal"></ol>
<ol class="list-lower-alpha"></ol>
<ol class="list-lower-latin"></ol>
<ol class="list-lower-roman"></ol>
<ol class="list-upper-alpha"></ol>
<ol class="list-upper-latin"></ol>
<ol class="list-upper-roman"></ol>
```

---

## Text Helpers

### Image Replacement (Text Hide)

You can include an image with visually hidden helper text for the sake of accessibility and improving SEO. The `.text-hide` class will visually hide an element’s text within the context of an image.

```html
<a href="#" class="text-hide">
  <img src="https://placehold.it/100x30" alt="zurb logo">
  Zurb <!-- Logo Text  -->
</a>
```
<a href="#" class="text-hide">
  <img src="assets/img/logos/zurb-logo.svg" alt="zurb logo">
  Zurb <!-- Logo Text  -->
</a>

---

### Text Transformation

Text transformation lets you control the capitalization of text. You can change the text transformation by adding `.text-uppercase`, `text-lowercase`, `text-capitalize` to an element.

```html
<p class="text-uppercase"><!-- Text here --></p>
<p class="text-lowercase"><!-- Text here --></p>
<p class="text-capitalize"><!-- Text here --></p>
```

<p class="text-uppercase"><strong>This is a upper-cased text.</strong> Set in the year 0 F.E. ("Foundation Era"), The Psychohistorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

<p class="text-lowercase"><strong>This is a lower-cased text.</strong> Set in the year 0 F.E. ("Foundation Era"), The Psychohistorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

<p class="text-capitalize"><strong>This is a caPitAlized teXt.</strong> Set in the yEar 0 F.E. ("Foundation Era"), The PsychohisTorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

<div class="callout primary">
  <strong>Note:</strong> `.text-capitalize` changes the first letter of every single word, leaving the case of other letters unaffected.
</div>

---

### Text Decoration

Text Decoration can be used to underline, overline, or line-through a text. You can change the text decoration by adding `.text-underline`, `.text-overline`, or `.text-line-through` to an element.

```html_example
<p class="text-underline">Lorem ipsum dolor sit amet, consectetur adipisicing elit. </p>
<p class="text-overline">Perspiciatis tempore cumque, magni aspernatur, quidem</p>
<p class="text-line-through">Lorem minus, placeat, iure voluptas aliquam tempora neque?</p>
```

---

### Text Truncate

The `.text-truncate` class will truncate your text and display an elipsis. This class works for a single line of text.

```html_example
<p class="text-truncate">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aperiam voluptatem similique officiis recusandae esse cum in totam quisquam perspiciatis quod! Magnam culpa vitae, tempore eos explicabo cupiditate. Deserunt, quisquam, quos!</p>
```

---

### Text No-wrap

If you would like to prevent the text wrapping into the next line you can utilize `.text-nowrap`. Please note that the text will continue to be in same line unless the `<br>` tag is used.

```html
<p class="text-nowrap">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aperiam voluptatem similique officiis recusandae esse cum in totam quisquam perspiciatis quod! Magnam culpa vitae, tempore eos explicabo cupiditate. Deserunt, quisquam, quos!</p>
```

### Text Wrap

To force text to wrap to the next line, you can use `.text-wrap`.

```html
<p class="text-wrap">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aperiam voluptatem similique officiis recusandae esse cum in totam quisquam perspiciatis quod! Magnam culpa vitae, tempore eos explicabo cupiditate. Deserunt, quisquam, quos!</p>
```

---

## Margin Helpers

Generate spacing around elements with these easy to use margin classes.

<div class="primary callout">
	Please note that here below, `1 = 1 * $global-margin` and so on. By default `$global-margin` is equal to `1rem` which you can easily customize through [Sass Variables](#sass-variables).
</div>

<p>
  <a class="" data-open-video="1:28"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

#### Margin (All Sides)

```html
<div class="margin-0"></div>
<div class="margin-1"></div>
<div class="margin-2"></div>
<div class="margin-3"></div>
```

#### Margin Top

```html
<div class="margin-top-0"></div>
<div class="margin-top-1"></div>
<div class="margin-top-2"></div>
<div class="margin-top-3"></div>
```

#### Margin Bottom

```html
<div class="margin-bottom-0"></div>
<div class="margin-bottom-1"></div>
<div class="margin-bottom-2"></div>
<div class="margin-bottom-3"></div>
```

#### Margin Left

```html
<div class="margin-left-0"></div>
<div class="margin-left-1"></div>
<div class="margin-left-2"></div>
<div class="margin-left-3"></div>
```

#### Margin Right

```html
<div class="margin-right-0"></div>
<div class="margin-right-1"></div>
<div class="margin-right-2"></div>
<div class="margin-right-3"></div>
```

#### Margin Left Right (Horizontal Axis)

```html
<div class="margin-horizontal-0"></div>
<div class="margin-horizontal-1"></div>
<div class="margin-horizontal-2"></div>
<div class="margin-horizontal-3"></div>
```

#### Margin Top Bottom (Vertical Axis)

```html
<div class="margin-vertical-0"></div>
<div class="margin-vertical-1"></div>
<div class="margin-vertical-2"></div>
<div class="margin-vertical-3"></div>
```

#### Margin: Usage as a Mixin

```scss
.foo {
  @include margin(1, 0, 2, null);
}
```

This above code will generate the below output

```scss
.foo {
  margin-top: 1rem !important;
  margin-right: 0 !important;
  margin-bottom: 2rem !important;
}
```

Note: The `margin-left` property wasn't printed as this mixin also accept `null` as a value to reduce CSS output. [See Sass Reference here](#margin)

---

## Padding Helpers

Generate spaces around the content with these easy to use padding classes.

<div class="primary callout">
	Please note that here below, `1 = 1 * $global-padding` and so on. By default `$global-padding` is equal to `1rem` which you can easily customize through [Sass Variables](#sass-variables).
</div>

#### Padding (All Sides)

```html
<div class="padding-0"></div>
<div class="padding-1"></div>
<div class="padding-2"></div>
<div class="padding-3"></div>
```

#### Padding Top

```html
<div class="padding-top-0"></div>
<div class="padding-top-1"></div>
<div class="padding-top-2"></div>
<div class="padding-top-3"></div>
```

#### Padding Bottom

```html
<div class="padding-bottom-0"></div>
<div class="padding-bottom-1"></div>
<div class="padding-bottom-2"></div>
<div class="padding-bottom-3"></div>
```

#### Padding Left

```html
<div class="padding-left-0"></div>
<div class="padding-left-1"></div>
<div class="padding-left-2"></div>
<div class="padding-left-3"></div>
```

#### Padding Right

```html
<div class="padding-right-0"></div>
<div class="padding-right-1"></div>
<div class="padding-right-2"></div>
<div class="padding-right-3"></div>
```

#### Padding Left Right (Horizontal Axis)

```html
<div class="padding-horizontal-0"></div>
<div class="padding-horizontal-1"></div>
<div class="padding-horizontal-2"></div>
<div class="padding-horizontal-3"></div>
```

#### Padding Top Bottom (Vertical Axis)

```html
<div class="padding-vertical-0"></div>
<div class="padding-vertical-1"></div>
<div class="padding-vertical-2"></div>
<div class="padding-vertical-3"></div>
```

#### Padding: Usage as a Mixin

```scss
.bar {
  @include padding(1, 0, 2, null);
}
```

This above code will generate the below output

```scss
.bar {
  padding-top: 1rem !important;
  padding-right: 0 !important;
  padding-bottom: 2rem !important;
}
```

Note: The `padding-left` property wasn't printed as this mixin also accept `null` as a value to reduce CSS output. [See Sass Reference here](#padding)

---

## Sizing

These width and height classes help you to easily make an element as wide or as tall as needed relative to its parent. By default it supports `25%`, `50%`, `75%` and `100%`. You can add more sizes though, through Sass map variable.

#### Width

```html
<div class="width-25"></div>
<div class="width-50"></div>
<div class="width-75"></div>
<div class="width-100"></div>

<div class="max-width-100"></div>
```

#### Height

```html
<div class="height-25"></div>
<div class="height-50"></div>
<div class="height-75"></div>
<div class="height-100"></div>

<div class="max-height-100"></div>
```

---

## Border box

Border box lets you only add the content, padding and border, but not the margin within the width and height CSS properties.

```html
<div class="border-box"></div>
```

---

## Border none

Border none lets you quickly resets border to `none` for any element.

```html_example
<div class="callout primary border-none">
  Hi! I am a callout with no Borders
</div>
```

---

## Display Classes

Display classes allow you to change the display property of any element.

```html
<div class="display-inline"></div>
<div class="display-inline-block"></div>
<div class="display-block"></div>
<div class="display-table"></div>
<div class="display-table-cell"></div>
```

These cover some of the most used display types. There are many other display values as specified by MDN [here](https://developer.mozilla.org/en-US/docs/Web/CSS/display). If you need some of those classes, then you can add them easily through Sass variables with `$prototype-display`. Sass Reference [here](#sass-reference)

<div class="primary callout">
  <ul>
  	<li>For `display: flex` use `.flex-container`. See [Flexbox Reference](flexbox.html)</li>
  	<li>For `display: none` use `.hide`. or Foundation's [Visibility Classes](visibility.html)</li>
  </ul>
</div>

---

## Positioning

Positioning classes help you change an element's position value. By default, an element's postion value is `static`.

```html
<div class="position-relative"></div>
<div class="position-absolute"></div>
<div class="position-fixed"></div>
<div class="position-fixed-top"></div>
<div class="position-fixed-bottom"></div>
<div class="position-static"></div>
```

#### Positioning: Usage as a Mixin

The position mixin can be used to set a position and to set the `top` `right` `bottom` and/or `left` property all in one.

```scss
.foo {
  @include position(fixed, 1, 2, 0, null);
}
```

This above code will generate the below output

```scss
.foo {
  position: fixed !important;
  top: 1rem !important;
  right: 2rem !important;
  bottom: 0 !important;
}
```

See how the `left` offset wasn't printed as this mixin also accepts `null` as a value. Sass Reference [here](#position)

---

## Overflow

These overflow classes helps you to clip content, render scrollbars or simply just display the content when it overflows its block level container.

#### All sides

```html
<div class="overflow-visible"></div>
<div class="overflow-hidden"></div>
<div class="overflow-scroll"></div>
```

#### Horizontal Axis

```html
<div class="overflow-x-visible"></div>
<div class="overflow-x-hidden"></div>
<div class="overflow-x-scroll"></div>
```

#### Vertical Axis

```html
<div class="overflow-y-visible"></div>
<div class="overflow-y-hidden"></div>
<div class="overflow-y-scroll"></div>
```

Note: Combining `overflow: hidden` in either the X or Y direction with the `overflow: visible` in the opposite direction does not work as expected in CSS spec. [More info](https://stackoverflow.com/questions/6421966/css-overflow-x-visible-and-overflow-y-hidden-causing-scrollbar-issue#answer-6433475)

---

## Sass Mixin Helpers

We also provides some extra utility mixins that you can use for your next prototype project.

### Box Mixin

This mixin helps you to easily create a square, rectangle or a circle. Sass Reference [here](#box)

```scss
.foo {
	@include box(1rem, 2rem); // Rectangle
}

.bar {
	@include box(1rem); // Square
}

.baz {
	@include box(1rem, $circle: true); // Circle
}
```

### Rotate Mixin
These Rotate mixins lets you rotate an element to a certain degree. Clockwise is the default direction but adding a `-` in front of the degrees will make it counter-clockwise.

```scss
.foo {
	@include rotate(30); // 30 Degree
}

.bar {
	@include rotateX(60); // 60 Degree on X axis
}

.baz {
	@include rotateY(90); // 90 Degree on Y axis
}

.shaz {
	@include rotateZ(120); // 120 Degree on Z axis
}
```

### Relational Mixins (AKA: nth:child mixins)

These relational mixins helps you to manage styling of :nth-child’ified elements through easy Sass mixins.

```scss
@include first($num) {} // applies style to first n children
@include first-child {} // applies style to first child only
@include last($num) {}  // applies style to last n children
@include last-child {}  // applies style to first child only
@include every($num) {} // applies style to every n children
@include first-last {}  // applies style to first and last child only
@include after-first($num) {} // applies style to all after nth child
@include from-last($num) {} // applies style to all after and including nth child
@include from-first-last($num) {} // applies style to nth child from first child and last child
@include all-but($num) {} // applies style to all except nth child
@include all-but-first-last($num) {} // applies style all except first and last child
@include unique {} // applies style to a child who has no siblings
@include not-unique {} // applies style to all children except a child who has no siblings
@include between($first, $last) {} // applies style to all except first and last child
@include even {} // applies style to all even children
@include even-between($first, $last) {} // applies style to all even children except first and last
@include odd {} // applies style to all odd children
@include odd-between($first, $last) {} // applies style to all odd children except first and last
@include number-between($num, $first, $last) {} // applies style to every n children from first child and last child
```

