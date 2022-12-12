---
title: Forms
description: We set out to create an easy, powerful and versatile form layout system. A combination of form styles and the Foundation grid means you can do almost anything.
video: 'pJDXFNJ2jkA'
sass:
  - scss/forms/*.scss
  - '!scss/forms/_error.scss'
tags:
  - input
  - select
  - radio
  - checkbox
flex: true
---

<div class="callout training-callout">
  <p>Learn the right way to tackle your project and at same time saving time and money. We offer in depth online webinars for you to gain the skills to become a Foundation front-end master.</p>
  <a href="http://zurb.com/university/foundation-intro" target="_blank">Check out our upcoming training opportunities →</a>
</div>

## Form Basics

Creating a form in Foundation is designed to be easy but extremely flexible. Forms are built with a combination of standard form elements, as well as grid rows and columns or cells.

---

#### Text Inputs

These input types create a text field: `text`, `date`, `datetime`, `datetime-local`, `email`, `month`, `number`, `password`, `search`, `tel`, `time`, `url`, and `week`.

<p>
  <a class="" data-open-video="0:38"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/wdmQrr?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example

<form>
  <div class="grid-container">
    <div class="grid-x grid-padding-x">
      <div class="medium-6 cell">
        <label>Input Label
          <input type="text" placeholder=".medium-6.cell">
        </label>
      </div>
      <div class="medium-6 cell">
        <label>Input Label
          <input type="text" placeholder=".medium-6.cell">
        </label>
      </div>
    </div>
  </div>
</form>
```

---

#### Number Inputs

In most desktop browsers, `<input type="number">` elements will have up/down controls inside them, which increment and decrement the number inside the field. These are called *spin buttons*. You can disable them by setting the `$input-number-spinners` Sass variable to `false`.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/WjzYJJ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<label>
  How many puppies?
  <input type="number" value="100">
</label>
```

---

#### Text Areas

The `<textarea>` element creates a multi-line text input.

<p>
  <a class="" data-open-video="5:20"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/rmdQrg?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<label>
  What books did you read over summer break?
  <textarea placeholder="None"></textarea>
</label>
```

---

#### Select Menus

Use select menus to combine many choices into one menu.

<p>
  <a class="" data-open-video="7:27"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/XREyxv?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<label>Select Menu
  <select>
    <option value="husker">Husker</option>
    <option value="starbuck">Starbuck</option>
    <option value="hotdog">Hot Dog</option>
    <option value="apollo">Apollo</option>
  </select>
</label>
```

Add the `multiple` attribute to allow more than one option to be selected. Hold down the Ctrl (windows) / Command (Mac) button to select multiple options.

```html_example
<label>Multiple Select Menu
  <select multiple>
    <option value="showboat">Showboat</option>
    <option value="redwing">Redwing</option>
    <option value="narcho">Narcho</option>
    <option value="hardball">Hardball</option>
  </select>
</label>
```

---

#### Checkboxes and Radio Buttons

Use groups of checkboxes when the user may select multiple choices from a list, and use radio buttons when the user must select just one choice.

Wrap a group of checkboxes or radio buttons in a `<fieldset>` element, and give them a common label using the `<legend>` element. Each individual control should also have its own label, created using a typical `<label>`.

<p>
  <a class="" data-open-video="9:03"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/Omvadz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x">
  <fieldset class="large-5 cell">
    <legend>Choose Your Favorite</legend>
    <input type="radio" name="pokemon" value="Red" id="pokemonRed" required><label for="pokemonRed">Red</label>
    <input type="radio" name="pokemon" value="Blue" id="pokemonBlue"><label for="pokemonBlue">Blue</label>
    <input type="radio" name="pokemon" value="Yellow" id="pokemonYellow"><label for="pokemonYellow">Yellow</label>
  </fieldset>
  <fieldset class="large-7 cell">
    <legend>Check these out</legend>
    <input id="checkbox1" type="checkbox"><label for="checkbox1">Checkbox 1</label>
    <input id="checkbox2" type="checkbox"><label for="checkbox2">Checkbox 2</label>
    <input id="checkbox3" type="checkbox"><label for="checkbox3">Checkbox 3</label>
  </fieldset>
</div>
```

---

#### Fieldset Styles

To encourage their use as an accessibility tool, the `<fieldset>` element is no longer styled by default. Those styles are now contained in the `.fieldset` class.

<p>
  <a class="" data-open-video="9:03"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/XREyxv?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<fieldset class="fieldset">
  <legend>Check these out</legend>
  <input id="checkbox12" type="checkbox"><label for="checkbox12">Checkbox 1</label>
  <input id="checkbox22" type="checkbox"><label for="checkbox22">Checkbox 2</label>
  <input id="checkbox32" type="checkbox"><label for="checkbox32">Checkbox 3</label>
</fieldset>
```

---

## Help Text (Accessibility)

Place help text below a field to clarify its purpose. Whenever you use help text, give the text a unique ID, and add the attribute `aria-describedby` to the input. Doing so associates the helper text to the input. A screen reader then can read the helper text when the user focusses on the input.

<p>
  <a class="" data-open-video="11:19"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/wdmOqr?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<label>Password
  <input type="password" aria-describedby="passwordHelpText">
</label>
<p class="help-text" id="passwordHelpText">Your password must have at least 10 characters, a number, and an Emoji.</p>
```

---

## Label Positioning

Sometimes you want a form with labels to the left of your inputs. Piece of cake! You can put the label inside a different cell or column to the left of the input. Then use the class `.text-right` or `.float-right` (or add `text-align: right` yourself) to realign the label.

<a class="" data-open-video="12:00"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
<div class="warning callout">
  <p>In a <a href="rtl.html">right-to-left</a> environment, use <code>.float-left</code> instead.</p>
</div>

<div class="docs-video-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/eWMXex?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<form>
  <div class="grid-x grid-padding-x">
    <div class="small-3 cell">
      <label for="right-label" class="text-right">Label</label>
    </div>
    <div class="small-9 cell">
      <input type="text" id="right-label" placeholder="Right-aligned text input">
    </div>
  </div>
</form>
```

<div class="medium-8 grid-x grid-padding-x cell align-center">
  <div class="grid-x grid-padding-x">
    <div class="small-3 cell">
      <label for="right-label" class="text-right">Label</label>
    </div>
    <div class="small-9 cell">
      <input type="text" id="right-label" placeholder="Right-aligned text input">
    </div>
  </div>
</div>

---

Add the `.middle` class to vertically align the label with its input.

```html
<form>
  <div class="grid-x grid-padding-x">
    <div class="small-3 cell">
      <label for="middle-label" class="text-right middle">Label</label>
    </div>
    <div class="small-9 cell">
      <input type="text" id="middle-label" placeholder="Right- and middle-aligned text input">
    </div>
  </div>
</form>
```

<div class="medium-8 grid-x grid-padding-x cell align-center">
  <div class="grid-x grid-padding-x">
    <div class="small-3 cell">
      <label for="middle-label" class="text-right middle">Label</label>
    </div>
    <div class="small-9 cell">
      <input type="text" id="middle-label" placeholder="Right- and middle-aligned text input">
    </div>
  </div>
</div>

---

## Inline Labels and Buttons

To attach extra text or controls to the left or right of an input field, wrap the elements in an `.input-group` container, then add these classes to the elements inside:

- `.input-group-field` on the text field.
- `.input-group-label` on a text label.
- `.input-group-button` on a button. **Place the button inside this wrapper.**

<a class="" data-open-video="14:53"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
<div class="primary callout">
  <p>This component supports flexbox mode. <a href="flexbox.html">Learn how to enable flexbox mode</a>.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/rmdRqg?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="input-group">
  <span class="input-group-label">$</span>
  <input class="input-group-field" type="number">
  <div class="input-group-button">
    <input type="submit" class="button" value="Submit">
  </div>
</div>
```

---

## File Upload Button

Use `<input type="file">` to create a file upload button. For security reasons, most browsers don't let you style file inputs. To work around that, we can style a form label as a button, and point it to the `<input>`. To properly mask the input, the `.show-for-sr` class is added.

<p>
  <a class="" data-open-video="17:45"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/NjYJZB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<label for="exampleFileUpload" class="button">Upload File</label>
<input type="file" id="exampleFileUpload" class="show-for-sr">
```

---

## Custom Controls (Accessibility)

Custom form controls, like date pickers, range sliders, or switches need some extra attention to be made accessible. Our custom inputs, such as the range slider and switch, do most of this work for you.

Custom inputs with labels or help text need the attributes `aria-labelledby` and `aria-describedby` added to them, so screen readers know how to describe the control.

```html
<label id="ageLabel">Age</label>
<div class="slider" aria-labelledby="ageLabel" aria-describedby="ageHelpText" data-slider data-initial-start="50" data-end="200">
  <span class="slider-handle"  data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <input type="hidden">
</div>
<p id="ageHelpText">How old are you?</p>
```
