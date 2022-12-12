---
title: Breadcrumbs
description: Breadcrumbs come in handy to show a navigation trail for users clicking through your site.
video: 'vQz-Kv5f_Ts'
sass: scss/components/_breadcrumbs.scss
---

To make a set of breadcrumb links, just add the class `.breadcrumbs` to a `<ul>`, and then add links inside of the `<li>` elements. The current page doesn't require a link or a class, but you should add some explanatory text for AT that indicates which item is the current page.

To mark a disabled item, add the class `.disabled` to the `<li>`, and just use plain text instead of a link.

<a class="" data-open-video="2:05"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="warning callout">
  <p>We use a CSS <code>::after</code> element containing a slash character to create the separator between items. Some screen readers will read this character out loud&mdash;if this is an issue, you can use a background image or a separate element with <code>aria-hidden="true"</code> to create the separator instead.</p>
</div>


<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/MmGeMx?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

<div class="warning callout">
  <p>If your site is visited by search engines, then you should consider adding Schema.org structure data. This will allow your site to appear more attractive in search results. </p>
  <p>For more information, see <a href="https://developers.google.com/search/docs/data-types/breadcrumbs">Breadcrumbs - Google Developers</a>, <a href="http://schema.org/BreadcrumbList">BreadcrumbList - schema.org</a>.</p>
</div>

```html_example
<nav aria-label="You are here:" role="navigation">
  <ul class="breadcrumbs">
    <li><a href="#">Home</a></li>
    <li><a href="#">Features</a></li>
    <li class="disabled">Gene Splicing</li>
    <li>
      <span class="show-for-sr">Current: </span> Cloning
    </li>
  </ul>
</nav>
```
