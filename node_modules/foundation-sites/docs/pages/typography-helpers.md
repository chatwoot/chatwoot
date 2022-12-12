---
title: Typography Helpers
description: Our helper classes allow you to scaffold certain typographic styles faster.
video: dq7s3PVpQ7M
sass:
  - scss/typography/_helpers.scss
  - scss/typography/_alignment.scss
tags:
  - alignment
  - subheader
  - lead
  - statistic
---

## Text Alignment

You can change the text alignment of an element by adding `.text-left`, `.text-right`, `.text-center` or `.text-justify` to an element.

Adding a breakpoint to the front of a text alignment class will cause it to only be applied on that size screen or larger. For example, `.medium-text-center` will keep text left-aligned on the smallest screens, but switch to center-aligned on medium screens and larger.

<p>
  <a class="" data-open-video="1:01"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/IamManchanda/pen/QvBQOe?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<p class="text-left"><!-- ... --></p>
<p class="text-right"><!-- ... --></p>
<p class="text-center"><!-- ... --></p>
<p class="text-justify"><!-- ... --></p>
```

<p class="text-left"><strong>This text is left-aligned.</strong> Set in the year 0 F.E. ("Foundation Era"), The Psychohistorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

<p class="text-right"><strong>This text is right-aligned.</strong> Set in the year 0 F.E. ("Foundation Era"), The Psychohistorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

<p class="text-center"><strong>This text is center-aligned.</strong> Set in the year 0 F.E. ("Foundation Era"), The Psychohistorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

<p class="text-justify"><strong>This text is justified.</strong> Set in the year 0 F.E. ("Foundation Era"), The Psychohistorians opens on Trantor, the capital of the 12,000-year-old Galactic Empire. Though the empire appears stable and powerful, it is slowly decaying in ways that parallel the decline of the Western Roman Empire.</p>

---

## Subheader

Lighten up your headers by adding a class of `.subheader` to any header element.

<p>
  <a class="" data-open-video="3:50"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/IamManchanda/pen/vmadjr?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<h1 class="subheader">h1.subheader</h1>
<h2 class="subheader">h2.subheader</h2>
<h3 class="subheader">h3.subheader</h3>
<h4 class="subheader">h4.subheader</h4>
<h5 class="subheader">h5.subheader</h5>
<h6 class="subheader">h6.subheader</h6>
```

---

## Lead Paragraph

A slightly-larger-than-normal block of text, useful for decks, blurbs, or other descriptive text.

<p>
  <a class="" data-open-video="3:24"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/IamManchanda/pen/GmBQGY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p class="lead">What are your cats <em>really</em> dreaming about while they sleep?</p>
```

---

## Un-bulleted List

In Foundation, the `<ul>` is a bulleted list and `<ol>` is a numbered list by default, but you can add the class `.no-bullet` to remove the bullets and numbers respectively.

#### Unordered List

<p>
  <a class="" data-open-video="5:18"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/IamManchanda/pen/wdxyxb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="no-bullet">
  <li>List item with a much longer description or more content.</li>
  <li>List item</li>
  <li>List item
    <ul>
      <li>Nested list item</li>
      <li>Nested list item</li>
      <li>Nested list item</li>
    </ul>
  </li>
  <li>List item</li>
  <li>List item</li>
  <li>List item</li>
</ul>
```

#### Ordered List

```html_example
<ol class="no-bullet">
  <li>List item with a much longer description or more content.</li>
  <li>List item</li>
  <li>List item
    <ol>
      <li>Nested list item</li>
      <li>Nested list item</li>
      <li>Nested list item</li>
    </ol>
  </li>
  <li>List item</li>
  <li>List item</li>
  <li>List item</li>
</ol>
```

---

## Typescale

Adjust font-size by overriding an element’s default size. This can be useful to size a `<p>` or `<h1>` through `<h6>` using Foundation's existing header sizes.

<div class="callout primary">
  <p><strong>Especially useful because:</strong> It's important to avoid skipping heading levels when structuring your document, as it confuses screen readers. For example, after using an <code>&lt;h2&gt;</code> in your code, the next heading used should be either <code>&lt;h2&gt;</code> or <code>&lt;h3&gt;</code>. If you need a heading to look bigger or smaller to match a specific style, use CSS to override the default size.</p>
</div>

For headers:

```html
<h2 class="h1">Lorem Ipsum Dolor</h2>
<h3 class="h2">Lorem Ipsum Dolor</h3>
<h4 class="h3">Lorem Ipsum Dolor</h4>
<h5 class="h4">Lorem Ipsum Dolor</h5>
<h6 class="h5">Lorem Ipsum Dolor</h6>
```

For text:

```html_example
<p class="h1">Lorem Ipsum Dolor</p>
<p class="h2">Lorem Ipsum Dolor</p>
<p class="h3">Lorem Ipsum Dolor</p>
<p class="h4">Lorem Ipsum Dolor</p>
<p class="h5">Lorem Ipsum Dolor</p>
<p class="h6">Lorem Ipsum Dolor</p>
```

---

## Statistics

If you're building a dashboard, you might need to display some important numbers *real big*. Just add the `.stat` class to any element to amp up the font size.

<p>
  <a class="" data-open-video="4:38"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/IamManchanda/pen/XRBZxp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p>Days without merge conflict</p>
<div class="stat">128</div>
```
