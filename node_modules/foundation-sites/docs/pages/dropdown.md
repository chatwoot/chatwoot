---
title: Dropdown
description: Dropdown panes are little happy sprites which can be revealed on click or hover.
sass: scss/components/_dropdown.scss
js: js/foundation.dropdown.js
video: '0F68zptD_nQ'
---

<div class="primary callout">
  <p>You might be looking for <a href="dropdown-menu.html">dropdown menus</a>, which are a separate plugin.</p>
</div>

## Basics

To create a dropdown pane, add the class `.dropdown-pane` and the attribute `data-dropdown` to an element. Give the dropdown a unique ID as well.

To create the dropdown trigger, add `data-toggle` to a `<button>`. The value of `data-toggle` is the ID of the dropdown.

<p>
  <a class="" data-open-video="0:47"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/NjzByp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>


```html_example
<button class="button" type="button" data-toggle="example-dropdown">Toggle Dropdown</button>
<div class="dropdown-pane" id="example-dropdown" data-dropdown data-auto-focus="true">
  Example form in a dropdown.
  <form>
    <div class="grid-container">
      <div class="grid-x grid-margin-x">
        <div class="cell medium-6">
          <label>Name
            <input type="text" placeholder="Kirk, James T.">
          </label>
        </div>
        <div class="cell medium-6">
          <label>Rank
            <input type="text" placeholder="Captain">
          </label>
        </div>
      </div>
    </div>
  </form>
</div>

<button class="button" type="button" data-toggle="example-dropdown-1">Hoverable Dropdown</button>
<div class="dropdown-pane" id="example-dropdown-1" data-dropdown data-hover="true" data-hover-pane="true">
  Just some junk that needs to be said. Or not. Your choice.
</div>
```

---

## Positioning

By default, a dropdown anchors below the button that opened it. Add the class `.top`, `.right`, or `.bottom` to the dropdown to change this.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/YVvjvz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<button class="button" type="button" data-toggle="example-dropdown2">Top Aligned</button>

<div class="dropdown-pane top" id="example-dropdown2" data-dropdown>
  Just some junk that needs to be said. Or not. Your choice.
</div>
```

<button class="button" type="button" data-toggle="example-dropdown3" style="float: right;">Left Aligned</button>
<div class="dropdown-pane left" id="example-dropdown3" data-dropdown>
  Just some junk that needs to be said. Or not. Your choice.
</div>

<button class="button" type="button" data-toggle="example-dropdown4">Right Aligned</button>
<div class="dropdown-pane right" id="example-dropdown4" data-dropdown>
  Just some junk that needs to be said. Or not. Your choice.
</div>


Adding `.float-right` or `.float-left` to the anchor will change the direction of the dropdown as well.

<button class="button float-right" type="button" data-toggle="example-dropdown5">Bottom-right Aligned</button>
<div class="dropdown-pane bottom" id="example-dropdown5" data-dropdown>
  Just some junk that needs to be said. Or not. Your choice.
</div>

<button class="button float-left" type="button" data-toggle="example-dropdown6">Bottom-left Aligned</button>
<div class="dropdown-pane bottom" id="example-dropdown6" data-dropdown>
  Just some junk that needs to be said. Or not. Your choice.
</div>

---

## Explicit Positioning

<div class="callout primary">
  <p><strong>New in v6.4:</strong> Heads up! This explicit positioning model is a new feature in v6.4.</p>
</div>

Wouldn't it be great if you can define both positions at the dropdown element. Dropdown has a fully explicit positioning model through which you can use both `data-position` and `data-alignment` to define both positions of the box.

These dropdowns test various positioning and alignments. Valid positions are left/right/top/bottom. Valid alignments are left/right/top/bottom/center. Left align means left sides should line up. Right align means right sides should line up. Center align means centers should line up.

#### Top and Bottom positioned

```html
<!-- Bottom Left -->
<button class="button" type="button" data-toggle="example-dropdown-bottom-left">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="bottom" data-alignment="left" id="example-dropdown-bottom-left" data-dropdown data-auto-focus="true">
  <!-- My dropdown content in here -->
</div>

<!-- Bottom Center -->
<button class="button" type="button" data-toggle="example-dropdown-bottom-center">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="bottom" data-alignment="center" id="example-dropdown-bottom-center" data-dropdown data-auto-focus="true">
  <!-- My dropdown content in here -->
</div>

<!-- Bottom Right -->
<button class="button" type="button" data-toggle="example-dropdown-bottom-right">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="bottom" data-alignment="right" id="example-dropdown-bottom-right" data-dropdown data-auto-focus="true">
  <!-- My dropdown content in here -->
</div>

<!-- Top Left -->
<button class="button" type="button" data-toggle="example-dropdown-top-left">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="top" data-alignment="left" id="example-dropdown-top-left" data-dropdown data-auto-focus="true">
  <!-- My dropdown content in here -->
</div>

<!-- Top Center -->
<button class="button" type="button" data-toggle="example-dropdown-top-center">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="top" data-alignment="center" id="example-dropdown-top-center" data-dropdown data-auto-focus="true">
  <!-- My dropdown content in here -->
</div>

<!-- Top Right -->
<button class="button" type="button" data-toggle="example-dropdown-top-right">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="top" data-alignment="right" id="example-dropdown-top-right" data-dropdown data-auto-focus="true">
  <!-- My dropdown content in here -->
</div>
```

<div class="grid-container">
  <div class="grid-x grid-margin-x small-up-1 medium-up-3">
    <div class="cell">
      <p>Bottom Left</p>
      <button class="button" type="button" data-toggle="example-dropdown-bottom-left">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="bottom" data-alignment="left" id="example-dropdown-bottom-left" data-dropdown data-auto-focus="true">
        <p>This dropdown has position bottom and alignment left should align with its top left corner at the bottom left of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Bottom Center</p>
      <button class="button" type="button" data-toggle="example-dropdown-bottom-center">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="bottom" data-alignment="center" id="example-dropdown-bottom-center" data-dropdown data-auto-focus="true">
        <p>This dropdown has position bottom and alignment center should align below the button with its center aligned with the center of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Bottom Right</p>
      <button class="button" type="button" data-toggle="example-dropdown-bottom-right">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="bottom" data-alignment="right" id="example-dropdown-bottom-right" data-dropdown data-auto-focus="true">
        <p>This dropdown has position bottom and alignment right should align with its top right corner at the bottom right of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Top Left</p>
      <button class="button" type="button" data-toggle="example-dropdown-top-left">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="top" data-alignment="left" id="example-dropdown-top-left" data-dropdown data-auto-focus="true">
        <p>This dropdown has position top and alignment left should align with its bottom left corner at the top left of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Top Center</p>
      <button class="button" type="button" data-toggle="example-dropdown-top-center">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="top" data-alignment="center" id="example-dropdown-top-center" data-dropdown data-auto-focus="true">
        <p>This dropdown has position top and alignment center should align above with its center aligned with the center of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Top Right</p>
      <button class="button" type="button" data-toggle="example-dropdown-top-right">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="top" data-alignment="right" id="example-dropdown-top-right" data-dropdown data-auto-focus="true">
        <p>This dropdown has position top and alignment right should align with its bottom right corner at the top right of the button</p>
      </div>
    </div>
  </div>
</div>

<br>

#### Left and Right Positioned

```html
<!-- Right Top -->
<button class="button" type="button" data-toggle="example-dropdown-right-top">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="right" data-alignment="top" id="example-dropdown-right-top" data-dropdown data-auto-focus="true">
</div>

<!-- Left Top -->
<button class="button" type="button" data-toggle="example-dropdown-left-top">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="left" data-alignment="top" id="example-dropdown-left-top" data-dropdown data-auto-focus="true">
</div>

<!-- Right Center -->
<button class="button" type="button" data-toggle="example-dropdown-right-center">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="right" data-alignment="center" id="example-dropdown-right-center" data-dropdown data-auto-focus="true">
</div>

<!-- Left Center -->
<button class="button" type="button" data-toggle="example-dropdown-left-center">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="left" data-alignment="center" id="example-dropdown-left-center" data-dropdown data-auto-focus="true">
</div>

<!-- Right Bottom -->
<button class="button" type="button" data-toggle="example-dropdown-right-bottom">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="right" data-alignment="bottom" id="example-dropdown-right-bottom" data-dropdown data-auto-focus="true">
</div>

<!-- Left Bottom -->
<button class="button" type="button" data-toggle="example-dropdown-left-bottom">Toggle Dropdown</button>
<div class="dropdown-pane" data-position="left" data-alignment="bottom" id="example-dropdown-left-bottom" data-dropdown data-auto-focus="true">
</div>
```

<div class="grid-container">
  <div class="grid-x grid-margin-x small-up-1 medium-up-2">
    <div class="cell">
      <p>Right Top</p>
      <button class="button" type="button" data-toggle="example-dropdown-right-top">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="right" data-alignment="top" id="example-dropdown-right-top" data-dropdown data-auto-focus="true">
        <p>This dropdown has position right and alignment top should align with its top left corner at the top right of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Left Top</p>
      <button class="button" type="button" data-toggle="example-dropdown-left-top">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="left" data-alignment="top" id="example-dropdown-left-top" data-dropdown data-auto-focus="true">
        <p>This dropdown has position left and alignment top should align with its top right corner at the top left of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Right Center</p>
      <button class="button" type="button" data-toggle="example-dropdown-right-center">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="right" data-alignment="center" id="example-dropdown-right-center" data-dropdown data-auto-focus="true">
        <p>This dropdown has position right and alignment center should align to the right of the button with the center of the dropdown vertically aligned with the center of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Left Center</p>
      <button class="button" type="button" data-toggle="example-dropdown-left-center">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="left" data-alignment="center" id="example-dropdown-left-center" data-dropdown data-auto-focus="true">
        <p>This dropdown has position left and alignment center should align to the left of the button with the center of the dropdown vertically aligned with the center of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Right Bottom</p>
      <button class="button" type="button" data-toggle="example-dropdown-right-bottom">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="right" data-alignment="bottom" id="example-dropdown-right-bottom" data-dropdown data-auto-focus="true">
        <p>This dropdown has position right and alignment bottom should align with its bottom left corner at the bottom right of the button</p>
      </div>
    </div>
    <div class="cell">
      <p>Left Bottom</p>
      <button class="button" type="button" data-toggle="example-dropdown-left-bottom">Toggle Dropdown</button>
      <div class="dropdown-pane" data-position="left" data-alignment="bottom" id="example-dropdown-left-bottom" data-dropdown data-auto-focus="true">
        <p>This dropdown has position left and alignment bottom should align with its bottom right corner at the bottom left of the button</p>
      </div>
    </div>
  </div>
</div>
