---
title: Abide
description: Abide is a form validation library that extends the HTML5 validation API with custom validators.
sass: scss/forms/_error.scss
js: js/foundation.abide.js
video: '4bN0qr5pxjs'
tags:
  - forms
  - validation
---

## Abide Demo

These input types create a text field: `text`, `date`, `datetime`, `datetime-local`, `email`, `month`, `number`, `password`, `search`, `tel`, `time`, `url` and `week`. Note the use of the novalidate attribute to disable any browser validation that could conflict with Abide.

<p>
  <a class="" data-open-video="0:27"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/brettsmason/pen/wdXRWP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<form data-abide novalidate>
  <div data-abide-error class="alert callout" style="display: none;">
    <p><i class="fi-alert"></i> There are some errors in your form.</p>
  </div>
  <div class="grid-container">
    <div class="grid-x grid-margin-x">
      <div class="cell small-12">
        <label>Number Required
          <input type="text" placeholder="1234" aria-describedby="example1Hint1" aria-errormessage="example1Error1" required pattern="number">
          <span class="form-error" id="example1Error1">
            Yo, you had better fill this out, it's required.
          </span>
        </label>
        <p class="help-text" id="example1Hint1">Here's how you use this input field!</p>
      </div>
      <div class="cell small-12">
        <label>Password Required
          <input type="password" id="password" placeholder="yeti4preZ" aria-describedby="example1Hint2" aria-errormessage="example1Error2" required >
          <span class="form-error" id="example1Error2">
            I'm required!
          </span>
        </label>
        <p class="help-text" id="example1Hint2">Enter a password please.</p>
      </div>
      <div class="cell small-12">
        <label>Re-enter Password
          <input type="password" placeholder="yeti4preZ" aria-describedby="example1Hint3" aria-errormessage="example1Error3" required pattern="alpha_numeric" data-equalto="password">
          <span class="form-error" id="example1Error3">
            Hey, passwords are supposed to match!
          </span>
        </label>
        <p class="help-text" id="example1Hint3">This field is using the `data-equalto="password"` attribute, causing it to match the password field above.</p>
      </div>
    </div>
  </div>
  <div class="grid-container">
    <div class="grid-x grid-margin-x">
      <div class="cell large-6">
        <label>URL Pattern, not required, but throws error if it doesn't match the Regular Expression for a valid URL.
          <input type="text" placeholder="https://foundation.zurb.com" pattern="url">
        </label>
      </div>
      <div class="cell large-6">
        <label>Website Pattern, not required, but throws error if it doesn't match the Regular Expression for a valid URL or a Domain.
          <input type="text" placeholder="https://zurb.com or zurb.com" pattern="website">
        </label>
      </div>
    </div>
  </div>
  <div class="grid-container">
    <div class="grid-x grid-margin-x">
      <div class="cell large-6">
        <label>European Cars, Choose One, it can't be the blank option.
          <select id="select" required>
            <option value=""></option>
            <option value="volvo">Volvo</option>
            <option value="saab">Saab</option>
            <option value="mercedes">Mercedes</option>
            <option value="audi">Audi</option>
          </select>
        </label>
      </div>
      <fieldset class="cell large-6">
        <legend>Check these out</legend>
        <input id="checkbox1" type="checkbox"><label for="checkbox1">Checkbox 1</label>
        <input id="checkbox2" type="checkbox" required><label for="checkbox2">Checkbox 2</label>
        <input id="checkbox3" type="checkbox"><label for="checkbox3">Checkbox 3</label>
      </fieldset>
    </div>
  </div>
  <div class="grid-container">
    <div class="grid-x grid-margin-x">
      <fieldset class="cell large-6">
        <legend>Choose Your Favorite - not required, you can leave this one blank.</legend>
        <input type="radio" name="pockets" value="Red" id="pocketsRed"><label for="pocketsRed">Red</label>
        <input type="radio" name="pockets" value="Blue" id="pocketsBlue"><label for="pocketsBlue">Blue</label>
        <input type="radio" name="pockets" value="Yellow" id="pocketsYellow"><label for="pocketsYellow">Yellow</label>
      </fieldset>
      <fieldset class="cell large-6">
        <legend>Choose Your Favorite, and this is required, so you have to pick one.</legend>
        <input type="radio" name="pokemon" value="Red" id="pokemonRed"><label for="pokemonRed">Red</label>
        <input type="radio" name="pokemon" value="Blue" id="pokemonBlue" required><label for="pokemonBlue">Blue</label>
        <input type="radio" name="pokemon" value="Yellow" id="pokemonYellow"><label for="pokemonYellow">Yellow</label>
      </fieldset>
    </div>
  </div>
  <div class="grid-container">
    <div class="grid-x grid-margin-x">
      <fieldset class="cell large-6">
        <button class="button" type="submit" value="Submit">Submit</button>
      </fieldset>
      <fieldset class="cell large-6">
        <button class="button" type="reset" value="Reset">Reset</button>
      </fieldset>
    </div>
  </div>
</form>
```
---

<p>&nbsp;</p>

<div class="alert callout">
  <p><i class="fi-alert"></i> There are some errors in your form.</p>
</div>

<label class="is-invalid-label">
  Required Thing
  <input type="text" class="is-invalid-input" aria-describedby="exemple2Error" data-invalid aria-invalid="true">
  <span class="form-error is-visible" id="exemple2Error">
    Yo, you had better fill this out.
  </span>
</label>

<label class="is-invalid-label">
  Required Thing
  <textarea type="text" class="is-invalid-input" data-invalid aria-invalid="true"></textarea>
</label>

---

### Form Errors

Abide automatically detects Form Errors of an input by their class (`.form-error` by default, see the `formErrorSelector` option) when they are siblings of the input or inside the same parent.

When the Form Errors cannot be placed next to its field, like in an Input Group, the relation can be declared with `[data-form-error-for]` attribute.

```html_example
<form data-abide novalidate>
  <div data-abide-error class="sr-only">
    There are some errors in your form.
  </div>

  <div>
    Amount
    <div class="input-group">
      <span class="input-group-label">$</span>
      <input class="input-group-field" id="example3Input" type="number" required pattern="number"/>
    </div>
    <label class="form-error" data-form-error-for="example3Input">Amount is required.</label>
  </div>

  <button class="button" type="submit" value="Submit">Submit</button>
</form>
```


## Initial State

```html
<form data-abide>
  <!-- Add "display: none" right away -->
  <div data-abide-error class="alert callout" aria-live="assertive" style="display: none;">
    <p><i class="fi-alert"></i> There are some errors in your form.</p>
  </div>
  <label>
    Name
    <input id="example4Input" aria-describedby="example4Error" type="text" required>
    <span id="example4Error" class="form-error">This field is required.</span>
  </label>
</form>
```

## Error State

```html
<form data-abide>
  <!-- Add role="alert" -->
  <!-- Add "display: block" -->
  <div data-abide-error class="alert callout" aria-live="assertive" role="alert" style="display: block;">
    <p><i class="fi-alert"></i> There are some errors in your form.</p>
  </div>
  <!-- Add "is-invalid-label" -->
  <label class="is-invalid-label">
    Name
    <!-- Add "is-invalid-input" -->
    <!-- Add aria-invalid="true" -->
    <input id="example4Input" aria-describedby="example4Error" type="text" required
      class="is-invalid-input" aria-invalid="true">
    <!-- Add "is-visible" -->
    <span id="example4Error" class="form-error is-visible">This field is required.</span>
  </label>
</form>
```

---

## Ignored Inputs

```html
<form data-abide>
  <div class="grid-x grid-margin-x">
    <div class="cell small-12">
      <label>Nothing Required!
        <input type="text" placeholder="Use me, or don't" aria-describedby="example5Hint1" data-abide-ignore>
      </label>
      <p class="help-text" id="example5Hint1">This input is ignored by Abide using `data-abide-ignore`</p>
    </div>
    <div class="cell small-12">
      <label>Disabled!
        <input type="text" placeholder="Disabled input" aria-describedby="example5Hint2" disabled>
      </label>
      <p class="help-text" id="example5Hint2">This input is ignored by Abide using `disabled`</p>
    </div>
    <div class="cell small-12">
      <label>Hidden!
        <input type="hidden" placeholder="Hidden input" aria-describedby="example5Hint3" >
      </label>
      <p class="help-text" id="example5Hint3">This input is ignored by Abide using `type="hidden"`</p>
    </div>
  </div>
  <div class="grid-container">
    <div class="grid-x grid-margin-x">
      <fieldset class="cell small-12">
        <button class="button" type="submit" value="Submit">Submit</button>
      </fieldset>
      <fieldset class="cell small-12">
        <button class="button" type="reset" value="Reset">Reset</button>
      </fieldset>
    </div>
  </div>
</form>
```

## Event Listener
Setup event listener after foundation is initialized (especially for formvalid/forminvalid). Easier to chain via document selector.
* valid.zf.abide and invalid.zf.abide are field level events, triggered in validateInput function 
  *   ev.target is the DOM field element, 
  *   elem is jQuery selector for field element
* formvalid.zf.abide and forminvalid.zf.abide are form events, triggered in validateForm function
  *   ev.target is the DOM form element, 
  *   frm is jQuery selector for form element

```javascript
$(document)
  // field element is invalid
  .on("invalid.zf.abide", function(ev,elem) {
    console.log("Field id "+ev.target.id+" is invalid");
  })
  // field element is valid
  .on("valid.zf.abide", function(ev,elem) {
    console.log("Field name "+elem.attr('name')+" is valid");
  })
  // form validation failed
  .on("forminvalid.zf.abide", function(ev,frm) {
    console.log("Form id "+ev.target.id+" is invalid");
  })
  // form validation passed, form will submit if submit event not returned false
  .on("formvalid.zf.abide", function(ev,frm) {
    console.log("Form id "+frm.attr('id')+" is valid");
    // ajax post form 
  })
  // to prevent form from submitting upon successful validation
  .on("submit", function(ev) {
    ev.preventDefault();
    console.log("Submit for form id "+ev.target.id+" intercepted");
  });
// You can bind field or form event selectively
$("#foo").on("invalid.zf.abide", function(ev,el) {
  alert("Input field foo is invalid");
});
$("#bar").on("formvalid.zf.abide", function(ev,frm) {
  alert("Form is valid, finally!");
  // do something perhaps
});
  ```

## Builtin Patterns and Validators

The following patterns and validators are already built in: 

`alpha`,
`alpha_numeric`,
`card`,
`color`
`cvv`,
`date`,
`dateISO`,
`datetime`,
`day_month_year`,
`domain`,
`email`,
`integer`,
`month_day_year`,
`number`,
`time`,
`url`

Apart from these standard patterns, we have a `website` pattern too which is basically a combo of both `domain` and `url` pattern and we recommend you to use this `website` pattern for validating websites.

They are defined by regular expressions as you can see below. Note, that the patterns that relate to text such as `alpha` and `alpha_numeric` do not consider special characters from other languages. You need to add these special characters yourself to the regular expressions. For instance, for the German language you need to add:

```JS
alpha : /^[a-zäöüßA-ZÄÖÜ]+$/,
alpha_numeric : /^[a-zäöüßA-ZÄÖÜ0-9]+$/,
```

Then you need to customize the builtin patterns as explained in the next section. Otherwise Abide will produce an error if a special character is input in your text field which is validated with `pattern="alpha"` or  `pattern="alpha_numeric"`.

Here are the definitions of the builtin patterns:

```JS
alpha : /^[a-zA-Z]+$/,
alpha_numeric : /^[a-zA-Z0-9]+$/,
integer : /^[-+]?\d+$/,
number : /^[-+]?\d*(?:[\.\,]\d+)?$/,

// amex, visa, diners
card : /^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})$/,
cvv : /^([0-9]){3,4}$/,

// http://www.whatwg.org/specs/web-apps/current-work/multipage/states-of-the-type-attribute.html#valid-e-mail-address
email : /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/,

// From CommonRegexJS (@talyssonoc)
// https://github.com/talyssonoc/CommonRegexJS/blob/e2901b9f57222bc14069dc8f0598d5f412555411/lib/commonregex.js#L76
// For more restrictive URL Regexs, see https://mathiasbynens.be/demo/url-regex.
url: /^((?:(https?|ftps?|file|ssh|sftp):\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))*\))+(?:\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:\'".,<>?\xab\xbb\u201c\u201d\u2018\u2019]))$/,

// abc.de
domain : /^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,8}$/,

datetime : /^([0-2][0-9]{3})\-([0-1][0-9])\-([0-3][0-9])T([0-5][0-9])\:([0-5][0-9])\:([0-5][0-9])(Z|([\-\+]([0-1][0-9])\:00))$/,
// YYYY-MM-DD
date : /(?:19|20)[0-9]{2}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-9])|(?:(?!02)(?:0[1-9]|1[0-2])-(?:30))|(?:(?:0[13578]|1[02])-31))$/,
// HH:MM:SS
time : /^(0[0-9]|1[0-9]|2[0-3])(:[0-5][0-9]){2}$/,
dateISO : /^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}$/,
// MM/DD/YYYY
month_day_year : /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.]\d{4}$/,
// DD/MM/YYYY
day_month_year : /^(0[1-9]|[12][0-9]|3[01])[- \/.](0[1-9]|1[012])[- \/.]\d{4}$/,

// #FFF or #FFFFFF
color : /^#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$/,

// Domain || URL
website: {
  test: (text) => {
    return Abide.defaults.patterns['domain'].test(text) || Abide.defaults.patterns['url'].test(text);
  }
}
```


## Adding Custom Pattern and Validator
* Override builtin patterns and validators before foundation is initialized
* Add new patterns and validators before or after foundation is initialized

```javascript
function myCustomValidator(
  $el,      /* jQuery element to validate */
  required, /* is the element required according to the `[required]` attribute */
  parent    /* parent of the jQuery element `$el` */
) {
  if (!required) return true;
  var from = $('#'+$el.attr('data-greater-than')).val(),
      to = $el.val();
  return (parseInt(to) > parseInt(from));
};

// Set default options
Foundation.Abide.defaults.patterns['dashes_only'] = /^[0-9-]*$/;
Foundation.Abide.defaults.validators['greater_than'] = myCustomValidator;

// Initialize Foundation
$(document).foundation();
```
```html
<input id="phone" type="text" pattern="dashes_only" required >
<input id="min" type="number" required >
<input id="max" type="number" data-validator="greater_than" data-greater-than="min" required>
```

## Accessibility

By default, Abide will add some accessibility attributes to your form elements. It is highly recommended to keep this option active as it improve the usability of your forms for disabled people. [Lean more about Accessibility in Foundation](accessibility.html).

However, if you think the attributes added by Abide are not correct, you can disable it by setting `a11yAttributes` (or `[data-a11y-attributes]`) to `false`.
