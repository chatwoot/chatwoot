---
title: Pagination
description: Pagination is a type of navigation that lets users click through pages of search results, products, or other related items.
video: '9gcGADHzz9o'
sass: scss/components/_pagination.scss
---

## Basics

A pagination list is just a `<ul>` with the class `.pagination`, and a series of `<li>`/`<a>` pairs. Add the class `.current` to an `<li>` to mark the current page, or `.disabled` to add disabled styles to a link.

Note that the list is nested inside a `<nav>` with the attributes `aria-label="Pagination"`. This explains the purpose of the component to assistive technologies.

Extra screen reader-only text should also be added to a pagination element. In the below example, users reading the page will just see "Next" and "Previous", but screen readers will read it as "Next page" and "Previous page". Additionally, the text for the current page will read as "You're on page one".

<p>
  <a class="" data-open-video="0:47"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/BRxVmB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<nav aria-label="Pagination">
  <ul class="pagination">
    <li class="pagination-previous disabled">Previous <span class="show-for-sr">page</span></li>
    <li class="current"><span class="show-for-sr">You're on page</span> 1</li>
    <li><a href="#" aria-label="Page 2">2</a></li>
    <li><a href="#" aria-label="Page 3">3</a></li>
    <li><a href="#" aria-label="Page 4">4</a></li>
    <li class="ellipsis" aria-hidden="true"></li>
    <li><a href="#" aria-label="Page 12">12</a></li>
    <li><a href="#" aria-label="Page 13">13</a></li>
    <li class="pagination-next"><a href="#" aria-label="Next page">Next <span class="show-for-sr">page</span></a></li>
  </ul>
</nav>
```

---

## Centered

The items in a pagination list are `display: inline-block`, which makes centering them easy. Use our built-in `.text-center` class, or add `text-align: center` in your CSS.

<p>
  <a class="" data-open-video="7:20"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/dWKYZb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<nav aria-label="Pagination">
  <ul class="pagination text-center">
    <li class="pagination-previous disabled">Previous</li>
    <li class="current"><span class="show-for-sr">You're on page</span> 1</li>
    <li><a href="#" aria-label="Page 2">2</a></li>
    <li><a href="#" aria-label="Page 3">3</a></li>
    <li><a href="#" aria-label="Page 4">4</a></li>
    <li class="ellipsis"></li>
    <li><a href="#" aria-label="Page 12">12</a></li>
    <li><a href="#" aria-label="Page 13">13</a></li>
    <li class="pagination-next"><a href="#" aria-label="Next page">Next</a></li>
  </ul>
</nav>
```
