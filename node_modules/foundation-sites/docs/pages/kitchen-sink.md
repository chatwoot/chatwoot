---
title: Kitchen Sink
description: Everything but.
---

## Abide


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/qmoKbK?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<form data-abide novalidate>
  <div class="grid-x grid-margin-x">
    <div class="cell">
      <div data-abide-error class="alert callout" style="display: none;">
        <p><i class="fi-alert"></i> There are some errors in your form.</p>
      </div>
    </div>
  </div>
  <div class="grid-x grid-margin-x">
    <div class="cell small-12">
      <label>Number Required
        <input type="text" placeholder="1234" aria-describedby="exampleHelpText" required pattern="number">
        <span class="form-error">
          Yo, you had better fill this out, it's required.
        </span>
      </label>
      <p class="help-text" id="exampleHelpText">Here's how you use this input field!</p>
    </div>
    <div class="cell small-12">
      <label>Nothing Required!
        <input type="text" placeholder="Use me, or don't" aria-describedby="exampleHelpTex" data-abide-ignore>
      </label>
      <p class="help-text" id="exampleHelpTex">This input is ignored by Abide using `data-abide-ignore`</p>
    </div>
    <div class="cell small-12">
      <label>Password Required
        <input type="password" id="password" placeholder="yeti4preZ" aria-describedby="exampleHelpText" required >
        <span class="form-error">
          I'm required!
        </span>
      </label>
      <p class="help-text" id="exampleHelpText">Enter a password please.</p>
    </div>
    <div class="cell small-12">
      <label>Re-enter Password
        <input type="password" placeholder="yeti4preZ" aria-describedby="exampleHelpText2" required pattern="alpha_numeric" data-equalto="password">
        <span class="form-error">
          Hey, passwords are supposed to match!
        </span>
      </label>
      <p class="help-text" id="exampleHelpText2">This field is using the `data-equalto="password"` attribute, causing it to match the password field above.</p>
    </div>
  </div>
  <div class="grid-x grid-margin-x">
    <div class="cell medium-6">
      <label>URL Pattern, not required, but throws error if it doesn't match the Regular Expression for a valid URL.
        <input type="text" placeholder="https://foundation.zurb.com" pattern="url">
      </label>
    </div>
    <div class="cell medium-6">
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
  </div>
  <div class="grid-x grid-margin-x">
    <fieldset class="cell medium-6">
      <legend>Choose Your Favorite, and this is required, so you have to pick one.</legend>
      <input type="radio" name="pokemon" value="Red" id="pokemonRed"><label for="pokemonRed">Red</label>
      <input type="radio" name="pokemon" value="Blue" id="pokemonBlue" required><label for="pokemonBlue">Blue</label>
      <input type="radio" name="pokemon" value="Yellow" id="pokemonYellow"><label for="pokemonYellow">Yellow</label>
    </fieldset>
    <fieldset class="cell medium-6">
      <legend>Choose Your Favorite - not required, you can leave this one blank.</legend>
      <input type="radio" name="pockets" value="Red" id="pocketsRed"><label for="pocketsRed">Red</label>
      <input type="radio" name="pockets" value="Blue" id="pocketsBlue"><label for="pocketsBlue">Blue</label>
      <input type="radio" name="pockets" value="Yellow" id="pocketsYellow"><label for="pocketsYellow">Yellow</label>
    </fieldset>
    <fieldset class="cell medium-6">
      <legend>Check these out</legend>
      <input id="checkbox1" type="checkbox"><label for="checkbox1">Checkbox 1</label>
      <input id="checkbox2" type="checkbox" required><label for="checkbox2">Checkbox 2</label>
      <input id="checkbox3" type="checkbox"><label for="checkbox3">Checkbox 3</label>
    </fieldset>
  </div>
  <div class="grid-x grid-margin-x">
    <fieldset class="cell medium-6">
      <button class="button" type="submit" value="Submit">Submit</button>
    </fieldset>
    <fieldset class="cell medium-6">
      <button class="button" type="reset" value="Reset">Reset</button>
    </fieldset>
  </div>
</form>
```

---

## Accordion


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/WjzKqa?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="accordion" data-accordion>
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content >
      <p>Panel 1. Lorem ipsum dolor</p>
      <a href="#">Nowhere to Go</a>
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 2</a>
    <div class="accordion-content" data-tab-content>
      <textarea></textarea>
      <button class="button">I do nothing!</button>
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 3</a>
    <div class="accordion-content" data-tab-content>
      Type your name!
      <input type="text"></input>
    </div>
  </li>
</ul>
```


---

## Accordion Menu


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/XREPVK?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical menu" data-accordion-menu>
  <li>
    <a href="#0">Item 1</a>
    <ul class="menu vertical nested is-active">
      <li>
        <a href="#0">Item 1A</a>
        <ul class="menu vertical nested">
          <li><a href="#0">Item 1Ai</a></li>
          <li><a href="#0">Item 1Aii</a></li>
          <li><a href="#0">Item 1Aiii</a></li>
        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
      <li><a href="#0">Item 1C</a></li>
    </ul>
  </li>
  <li>
    <a href="#0">Item 2</a>
    <ul class="menu vertical nested">
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
    </ul>
  </li>
  <li><a href="#0">Item 3</a></li>
</ul>
```

---

## Badge


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/JNvKZj?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<span class="primary badge">1</span>
<span class="secondary badge">2</span>
<span class="success badge">3</span>
<span class="alert badge">A</span>
<span class="warning badge">B</span>
```

---

## Breadcrumbs


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/MmGeMx?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<nav aria-label="You are here:" role="navigation">
  <ul class="breadcrumbs">
    <li><a href="#0">Home</a></li>
    <li><a href="#0">Features</a></li>
    <li class="disabled">Gene Splicing</li>
    <li>
      <span class="show-for-sr">Current: </span> Cloning
    </li>
  </ul>
</nav>
```

---

## Button


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ybjagd?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<!-- Anchors (links) -->
<a href="#0" class="button">Learn More</a>
<a href="#features" class="button">View All Features</a>

<!-- Buttons (actions) -->
<button type="button" class="success button">Save</button>
<button type="button" class="alert button">Delete</button>

<a class="tiny button" href="#0">So Tiny</a>
<a class="small button" href="#0">So Small</a>
<a class="large button" href="#0">So Large</a>
<a class="expanded button" href="#0">Such Expand</a>

<div class="button-group">
  <a class="button">One</a>
  <a class="button">Two</a>
  <a class="button">Three</a>
</div>
```

---

## Callout


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/XRqjxj?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="callout">
  <h5>This is a callout.</h5>
  <p>It has an easy to override visual style, and is appropriately subdued.</p>
  <a href="#0">It's dangerous to go alone, take this.</a>
</div>

<div class="callout primary">
  <h5>This is a primary callout.</h5>
  <p>It has an easy to override visual style, and is appropriately subdued.</p>
  <a href="#0">It's dangerous to go alone, take this.</a>
</div>

<div class="callout secondary">
  <h5>This is a secondary callout</h5>
  <p>It has an easy to override visual style, and is appropriately subdued.</p>
  <a href="#0">It's dangerous to go alone, take this.</a>
</div>

<div class="callout success">
  <h5>This is a success callout</h5>
  <p>It has an easy to override visual style, and is appropriately subdued.</p>
  <a href="#0">It's dangerous to go alone, take this.</a>
</div>

<div class="callout warning">
  <h5>This is a warning callout</h5>
  <p>It has an easy to override visual style, and is appropriately subdued.</p>
  <a href="#0">It's dangerous to go alone, take this.</a>
</div>

<div class="callout alert">
  <h5>This is an alert callout</h5>
  <p>It has an easy to override visual style, and is appropriately subdued.</p>
  <a href="#0">It's dangerous to go alone, take this.</a>
</div>
```

---

## Close Button


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/dWepJz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="callout" data-closable>
  <button class="close-button" aria-label="Close alert" type="button" data-close>
    <span aria-hidden="true">&times;</span>
  </button>
  <p>This is a close button example.</p>
</div>
```

---

## Drilldown Menu


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/mmLrZz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical menu" data-drilldown style="width: 200px" id="m1">
  <li>
    <a href="#0">Item 1</a>
    <ul class="vertical menu" id="m2">
      <li>
        <a href="#0">Item 1A</a>
        <ul class="vertical menu" id="m3">
          <li><a href="#0">Item 1Aa</a></li>
          <li><a href="#0">Item 1Ba</a></li>
          <li><a href="#0">Item 1Ca</a></li>
          <li><a href="#0">Item 1Da</a></li>
          <li><a href="#0">Item 1Ea</a></li>
        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
      <li><a href="#0">Item 1C</a></li>
      <li><a href="#0">Item 1D</a></li>
      <li><a href="#0">Item 1E</a></li>
    </ul>
  </li>
  <li>
    <a href="#0">Item 2</a>
    <ul class="vertical menu">
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
      <li><a href="#0">Item 2C</a></li>
      <li><a href="#0">Item 2D</a></li>
      <li><a href="#0">Item 2E</a></li>
    </ul>
  </li>
  <li>
    <a href="#0">Item 3</a>
    <ul class="vertical menu">
      <li><a href="#0">Item 3A</a></li>
      <li><a href="#0">Item 3B</a></li>
      <li><a href="#0">Item 3C</a></li>
      <li><a href="#0">Item 3D</a></li>
      <li><a href="#0">Item 3E</a></li>
    </ul>
  </li>
  <li><a href='#0'> Item 4</a></li>
</ul>
```

---

## Dropdown Menu


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/jmxVPP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="dropdown menu" data-dropdown-menu>
  <li>
    <a>Item 1</a>
    <ul class="menu">
      <li><a href="#0">Item 1A Loooong</a></li>
      <li>
        <a href='#0'> Item 1 sub</a>
        <ul class="menu">
          <li><a href='#0'>Item 1 subA</a></li>
          <li><a href='#0'>Item 1 subB</a></li>
          <li>
            <a href='#0'> Item 1 sub</a>
            <ul class="menu">
              <li><a href='#0'>Item 1 subA</a></li>
              <li><a href='#0'>Item 1 subB</a></li>
            </ul>
          </li>
          <li>
            <a href='#0'> Item 1 sub</a>
            <ul class="menu">
              <li><a href='#0'>Item 1 subA</a></li>
            </ul>
          </li>
        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
    </ul>
  </li>
  <li>
    <a href="#0">Item 2</a>
    <ul class="menu">
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
    </ul>
  </li>
  <li><a href="#0">Item 3</a></li>
  <li><a href='#0'>Item 4</a></li>
</ul>
```

---

## Dropdown Pane


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/QvrGGj?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<button class="button" type="button" data-toggle="example-dropdown">Toggle Dropdown</button>
<div class="dropdown-pane" id="example-dropdown" data-dropdown>
  Just some junk that needs to be said. Or not. Your choice.
</div>
```

---

## Equalizer


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/mmLBEa?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-margin-x" data-equalizer data-equalize-on="medium" id="test-eq">
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch>
      <img src= "assets/img/generic/square-1.jpg">
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch>
      <p>Pellentesque habitant morbi tristique senectus et netus et, ante.</p>
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch>
      <img src= "assets/img/generic/rectangle-1.jpg">
    </div>
  </div>
</div>
```

---

## Flex Grid


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/dWmVax?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="small-6 columns">6 columns</div>
  <div class="small-6 columns">6 columns</div>
</div>
<div class="row">
  <div class="medium-6 large-4 columns">12/6/4 columns</div>
  <div class="medium-6 large-8 columns">12/6/8 columns</div>
</div>
```

<div class="row display">
  <div class="small-6 columns">6 columns</div>
  <div class="small-6 columns">6 columns</div>
</div>
<div class="row display">
  <div class="medium-6 large-4 columns">12/6/4 columns</div>
  <div class="medium-6 large-8 columns">12/6/8 columns</div>
</div>

---

## Responsive Embed


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/MmGEbb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="responsive-embed">
  <iframe width="420" height="315" src="https://www.youtube.com/embed/mM5_T-F1Yn4" frameborder="0" allowfullscreen></iframe>
</div>
```

---

## Float Classes


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/zwjEPP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="callout clearfix">
  <a class="button float-left">Left</a>
  <a class="button float-right">Right</a>
</div>
```

---

## Forms


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/jmxGGr?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<form>
  <label>Input Label
    <input type="text" placeholder=".small-12.columns" aria-describedby="exampleHelpText">
  </label>
  <p class="help-text" id="exampleHelpText">Here's how you use this input field!</p>
  <label>
    How many puppies?
    <input type="number" value="100">
  </label>
  <label>
    What books did you read over summer break?
    <textarea placeholder="None"></textarea>
  </label>
  <label>Select Menu
    <select>
      <option value="husker">Husker</option>
      <option value="starbuck">Starbuck</option>
      <option value="hotdog">Hot Dog</option>
      <option value="apollo">Apollo</option>
    </select>
  </label>
  <div class="grid-x grid-margin-x">
    <fieldset class="cell large-6">
      <legend>Choose Your Favorite</legend>
      <input type="radio" name="pokemon" value="Red" id="formRed" required><label for="formRed">Red</label>
      <input type="radio" name="pokemon" value="Blue" id="formBlue"><label for="formBlue">Blue</label>
      <input type="radio" name="pokemon" value="Yellow" id="formYellow"><label for="formYellow">Yellow</label>
    </fieldset>
    <fieldset class="cell large-6">
      <legend>Check these out</legend>
      <input id="formCheckbox1" type="checkbox"><label for="formCheckbox1">Checkbox 1</label>
      <input id="formCheckbox2" type="checkbox"><label for="formCheckbox2">Checkbox 2</label>
      <input id="formCheckbox3" type="checkbox"><label for="formCheckbox3">Checkbox 3</label>
    </fieldset>
  </div>
  <div class="grid-x grid-margin-x">
    <div class="cell small-3">
      <label for="middle-label" class="text-right middle">Label</label>
    </div>
    <div class="cell small-9">
      <input type="text" id="middle-label" placeholder="Right- and middle-aligned text input">
    </div>
  </div>
  <div class="input-group">
    <span class="input-group-label">$</span>
    <input class="input-group-field" type="url">
    <div class="input-group-button">
      <input type="submit" class="button" value="Submit">
    </div>
  </div>
</form>
```

---

## Grid


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/rmvEBJ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="small-2 medium-3 large-4 columns">2/3/4 columns</div>
  <div class="small-4 medium-3 large-4 columns">4/3/4 columns</div>
  <div class="small-6 large-4 columns">6/6/4 columns</div>
</div>
<div class="row">
  <div class="large-3 columns">12/12/3 columns</div>
  <div class="large-6 columns">12/12/6 columns</div>
  <div class="large-3 columns">12/12/3 columns</div>
</div>
<div class="row">
  <div class="small-6 large-2 columns">6/6/2 columns</div>
  <div class="small-6 large-8 columns">6/6/8 columns</div>
  <div class="small-12 large-2 columns">12/12/2 columns</div>
</div>
<div class="row">
  <div class="small-3 columns">3 columns</div>
  <div class="small-9 columns">9 columns</div>
</div>
<div class="row">
  <div class="medium-8 large-4 columns">12/8/4 columns</div>
  <div class="medium-4 large-8 columns">12/4/8 columns</div>
</div>
```

<div class="row display">
  <div class="small-2 medium-3 large-4 columns">2/3/4 columns</div>
  <div class="small-4 medium-3 large-4 columns">4/3/4 columns</div>
  <div class="small-6 large-4 columns">6/6/4 columns</div>
</div>
<div class="row display">
  <div class="large-3 columns">12/12/3 columns</div>
  <div class="large-6 columns">12/12/6 columns</div>
  <div class="large-3 columns">12/12/3 columns</div>
</div>
<div class="row display">
  <div class="small-6 large-2 columns">6/6/2 columns</div>
  <div class="small-6 large-8 columns">6/6/8 columns</div>
  <div class="small-12 large-2 columns">12/12/2 columns</div>
</div>
<div class="row display">
  <div class="small-3 columns">3 columns</div>
  <div class="small-9 columns">9 columns</div>
</div>
<div class="row display">
  <div class="medium-8 large-4 columns">12/8/4 columns</div>
  <div class="medium-4 large-8 columns">12/4/8 columns</div>
</div>

---

## Interchange


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/xdjXYj?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<img data-interchange="[assets/img/interchange/small.jpg, small], [assets/img/interchange/medium.jpg, medium], [assets/img/interchange/large.jpg, large]">
```

---

## Label


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/VbxMXq?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<span class="primary label">Primary Label</span>
<span class="secondary label">Secondary Label</span>
<span class="success label">Success Label</span>
<span class="alert label">Alert Label</span>
<span class="warning label">Warning Label</span>
```

---

## Magellan


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/MmGEXo?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="horizontal menu" data-magellan>
  <li><a href="#first">First Arrival</a></li>
  <li><a href="#second">Second Arrival</a></li>
  <li><a href="#third">Third Arrival</a></li>
</ul>
<div class="sections">
  <section id="first" data-magellan-target="first">
    <h4>First section</h4>
    <p>Duis scelerisque ligula ut metus rhoncus scelerisque. Integer ut egestas metus. Nulla facilisi. Aenean luctus magna lobortis ligula rhoncus, sit amet lacinia lorem sagittis. Sed ultrices at metus id aliquet. Vestibulum in condimentum quam, id ornare erat. Vivamus nec justo quis ex fringilla condimentum ac non quam.</p>
  </section>
  <section id="second" data-magellan-target="second">
    <h4>Second section</h4>
    <p>Sed vulputate, felis interdum molestie viverra, neque urna placerat dui, ac efficitur est magna eu tellus. Nunc sodales consequat eros at bibendum. Vestibulum hendrerit gravida elit non eleifend. Nunc at vehicula ipsum. Vestibulum eu suscipit felis. Proin ipsum felis, consequat congue quam ac, efficitur tincidunt ex. Morbi accumsan sem iaculis nunc malesuada tincidunt.</p>
  </section>
  <section id="third" data-magellan-target="third">
    <h4>Third section</h4>
    <p>Aliquam orci orci, maximus a pulvinar id, tincidunt a neque. Suspendisse eros diam, finibus et faucibus ac, suscipit feugiat orci. Morbi scelerisque sem id blandit malesuada. Donec suscipit tincidunt dolor in blandit. Nam rhoncus risus vitae lacinia dictum. Cras lobortis, nulla non faucibus mattis, tellus nibh condimentum eros, posuere volutpat arcu risus vel ante. In ut ullamcorper eros, et vestibulum risus. Fusce auctor risus vitae diam viverra tincidunt.</p>
  </section>
</div>
```

<ul class="horizontal menu" data-magellan>
  <li><a href="#first">First Arrival</a></li>
  <li><a href="#second">Second Arrival</a></li>
  <li><a href="#third">Third Arrival</a></li>
</ul>

---

## Media Object


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/NjMaEr?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="media-object">
  <div class="media-object-section">
    <img src= "https://placeimg.com/200/200/people">
  </div>
  <div class="media-object-section">
    <h4>Dreams feel real while we're in them.</h4>
    <p>I'm going to improvise. Listen, there's something you should know about me... about inception. An idea is like a virus, resilient, highly contagious. The smallest seed of an idea can grow. It can grow to define or destroy you.</p>
  </div>
</div>
```

---

## Menu


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/bWMMzZ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu">
  <li><a href="#0"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```

---

## Off-canvas


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/oWdrLR?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<!-- Set up Off-canvas -->
<body>
  <div class="off-canvas-wrapper">
    <div class="off-canvas-wrapper-inner" data-off-canvas-wrapper>
      <div class="off-canvas position-left" id="offCanvasLeft" data-off-canvas>
        <!-- left off-canvas markup -->
      </div>
      <div class="off-canvas position-right" id="offCanvasRight" data-off-canvas data-position="right">
        <!-- right off-canvas markup -->
      </div>
      <div class="off-canvas-content" data-off-canvas-content>
        <!-- page content -->
      </div>
    </div>
  </div>
</body>

<!-- Fire Off-canvas -->
<button type="button" class="button" data-toggle="offCanvasLeft">Open Menu</button>
```

---

## Orbit


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/zwjjgN?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="orbit" role="region" aria-label="Favorite Text Ever" data-orbit>
  <ul class="orbit-container">
    <button class="orbit-previous" aria-label="previous"><span class="show-for-sr">Previous Slide</span>&#9664;</button>
    <button class="orbit-next" aria-label="next"><span class="show-for-sr">Next Slide</span>&#9654;</button>
    <li class="is-active orbit-slide">
      <div class="docs-example-orbit-slide">
        <p><strong>This is dodgerblue.</strong> Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
      </div>
    </li>
    <li class="orbit-slide">
      <div class="docs-example-orbit-slide">
        <p><strong>This is rebeccapurple.</strong> Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
      </div>
    </li>
    <li class="orbit-slide">
      <div class="docs-example-orbit-slide">
        <p><strong>This is darkgoldenrod.</strong> Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
      </div>
    </li>
    <li class="orbit-slide">
      <div class="docs-example-orbit-slide">
        <p><strong>This is lightseagreen.</strong> Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
      </div>
    </li>
  </ul>
  <nav class="orbit-bullets">
    <button class="is-active" data-slide="0"><span class="show-for-sr">First slide details.</span><span class="show-for-sr">Current Slide</span></button>
    <button data-slide="1"><span class="show-for-sr">Second slide details.</span></button>
    <button data-slide="2"><span class="show-for-sr">Third slide details.</span></button>
    <button data-slide="3"><span class="show-for-sr">Fourth slide details.</span></button>
  </nav>
</div>
```

---

## Pagination


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/BRxVmB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="pagination" role="navigation" aria-label="Pagination">
  <li class="disabled">Previous <span class="show-for-sr">page</span></li>
  <li class="current"><span class="show-for-sr">You're on page</span> 1</li>
  <li><a href="#0" aria-label="Page 2">2</a></li>
  <li><a href="#0" aria-label="Page 3">3</a></li>
  <li><a href="#0" aria-label="Page 4">4</a></li>
  <li class="ellipsis" aria-hidden="true"></li>
  <li><a href="#0" aria-label="Page 12">12</a></li>
  <li><a href="#0" aria-label="Page 13">13</a></li>
  <li><a href="#0" aria-label="Next page">Next <span class="show-for-sr">page</span></a></li>
</ul>
```

---

## Progress Bar


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/YVLvvB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="primary progress" role="progressbar" tabindex="0" aria-valuenow="25" aria-valuemin="0" aria-valuetext="25 percent" aria-valuemax="100">
  <div class="progress-meter" style="width: 25%">
    <p class="progress-meter-text">25%</p>
  </div>
</div>

<div class="warning progress">
  <div class="progress-meter" style="width: 50%">
    <p class="progress-meter-text">50%</p>
  </div>
</div>

<div class="alert progress">
  <div class="progress-meter" style="width: 75%">
    <p class="progress-meter-text">75%</p>
  </div>
</div>

<div class="success progress" role="progressbar" tabindex="0" aria-valuenow="100" aria-valuemin="0" aria-valuetext="100 percent" aria-valuemax="100">
  <div class="progress-meter" style="width: 100%">
    <p class="progress-meter-text">100%</p>
  </div>
</div>
```

---

## Responsive Menu


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/qmYKgJ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical medium-horizontal menu">
  <li><a href="#0"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```

---

## Responsive Toggle


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/LymroM?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="title-bar" data-responsive-toggle="example-menu" data-hide-for="medium">
  <button class="menu-icon" type="button" data-toggle></button>
  <div class="title-bar-title">Menu</div>
</div>

<div class="top-bar" id="example-menu">
  <div class="top-bar-left">
    <ul class="dropdown menu" data-dropdown-menu>
      <li class="menu-text">Site Title</li>
      <li class="has-submenu">
        <a href="#0">One</a>
        <ul class="submenu menu vertical" data-submenu>
          <li><a href="#0">One</a></li>
          <li><a href="#0">Two</a></li>
          <li><a href="#0">Three</a></li>
        </ul>
      </li>
      <li><a href="#0">Two</a></li>
      <li><a href="#0">Three</a></li>
    </ul>
  </div>
  <div class="top-bar-right">
    <ul class="menu">
      <li><input type="search" placeholder="Search"></li>
      <li><button type="button" class="button">Search</button></li>
    </ul>
  </div>
</div>
```

---

## Reveal


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/RVyBPw?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><a data-open="exampleModal1">Click me for a modal</a></p>

<div class="reveal" id="exampleModal1" data-reveal>
  <h1>Awesome. I Have It.</h1>
  <p class="lead">Your couch. It is mine.</p>
  <p>I'm a cool paragraph that lives inside of an even cooler modal. Wins!</p>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```

---

## Slider


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/xdjJVm?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="slider" data-slider data-initial-start="50" data-end="200">
  <span class="slider-handle"  data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <input type="hidden">
</div>

<div class="slider vertical" data-slider data-initial-start="25" data-end="200" data-vertical="true">
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <input type="hidden">
</div>

<div class="slider" data-slider data-initial-start="25" data-initial-end="75">
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <input type="hidden">
  <input type="hidden">
</div>
```

---

## Sticky


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ZKodJR?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns small-6" id="example1" data-something>
    <p id="doodle">
      Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>
    <p>
      Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>
    <p>
      Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>
    <p>
      Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>
  </div>
  <div class="columns small-6 right" data-sticky-container>
    <div class="sticky" data-sticky data-margin-top="6" data-anchor="example1">
      <img class="thumbnail" src="assets/img/generic/rectangle-3.jpg">
    </div>
  </div>
</div>
```

---

## Switch


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/dWejpx?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="switch tiny">
  <input class="switch-input" id="tinySwitch" type="checkbox" name="exampleSwitch">
  <label class="switch-paddle" for="tinySwitch">
    <span class="show-for-sr">Tiny Sandwiches Enabled</span>
  </label>
</div>

<div class="switch small">
  <input class="switch-input" id="smallSwitch" type="checkbox" name="exampleSwitch">
  <label class="switch-paddle" for="smallSwitch">
    <span class="show-for-sr">Small Portions Only</span>
  </label>
</div>

<div class="switch large">
  <input class="switch-input" id="largeSwitch" type="checkbox" name="exampleSwitch">
  <label class="switch-paddle" for="largeSwitch">
    <span class="show-for-sr">Show Large Elephants</span>
  </label>
</div>
```

---

## Table


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/eWrjQx?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<table>
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
      <td>This is longer Content Goes Here Donec id elit non mi porta gravida at eget metus.</td>
      <td>Content Goes Here</td>
      <td>Content Goes Here</td>
    </tr>
  </tbody>
</table>
```

---

## Tabs


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/qmYygE?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="tabs" data-tabs id="example-tabs">
  <li class="tabs-title is-active"><a href="#panel1" aria-selected="true">Tab 1</a></li>
  <li class="tabs-title"><a href="#panel2">Tab 2</a></li>
  <li class="tabs-title"><a href="#panel3">Tab 3</a></li>
  <li class="tabs-title"><a href="#panel4">Tab 4</a></li>
  <li class="tabs-title"><a href="#panel5">Tab 5</a></li>
  <li class="tabs-title"><a href="#panel6">Tab 6</a></li>
</ul>

<div class="tabs-content" data-tabs-content="example-tabs">
  <div class="tabs-panel is-active" id="panel1">
    <p>One</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel2">
    <p>Two</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-7.jpg">
  </div>
  <div class="tabs-panel" id="panel3">
    <p>Three</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel4">
    <p>Four</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-2.jpg">
  </div>
  <div class="tabs-panel" id="panel5">
    <p>Five</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel6">
    <p>Six</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-8.jpg">
  </div>
</div>
```

---

## Thumbnail


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/EmLexY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-margin-x">
  <div class="cell small-4">
    <img class="thumbnail" src="assets/img/thumbnail/01.jpg" alt="Photo of Uranus.">
  </div>
  <div class="cell small-4">
    <img class="thumbnail" src="assets/img/thumbnail/02.jpg" alt="Photo of Neptune.">
  </div>
  <div class="cell small-4">
    <img class="thumbnail" src="assets/img/thumbnail/03.jpg" alt="Photo of Pluto.">
  </div>
</div>
```

---

## Title Bar


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/qmYMZZ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="title-bar">
  <div class="title-bar-left">
    <button class="menu-icon" type="button"></button>
    <span class="title-bar-title">Foundation</span>
  </div>
  <div class="title-bar-right">
    <button class="menu-icon" type="button"></button>
  </div>
</div>
```

---

## Toggler


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/LymJLb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><a data-toggle="menuBar">Expand!</a></p>

<ul class="menu" id="menuBar" data-toggler=".expanded">
  <li><a href="#0"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```

---

## Tooltip


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/pPVOdm?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p>The <span data-tooltip aria-haspopup="true" class="has-tip" data-disable-hover="false" tabindex=1 title="Fancy word for a beetle.">scarabaeus</span> hung quite clear of any branches, and, if allowed to fall, would have fallen at our feet. Legrand immediately took the scythe, and cleared with it a circular space, three or four yards in diameter, just beneath the insect, and, having accomplished this, ordered Jupiter to let go the string and come down from the tree.</p>
```

---

## Top Bar


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/eWrwKP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="top-bar">
  <div class="top-bar-left">
    <ul class="dropdown menu" data-dropdown-menu>
      <li class="menu-text">Site Title</li>
      <li class="has-submenu">
        <a href="#0">One</a>
        <ul class="submenu menu vertical" data-submenu>
          <li><a href="#0">One</a></li>
          <li><a href="#0">Two</a></li>
          <li><a href="#0">Three</a></li>
        </ul>
      </li>
      <li><a href="#0">Two</a></li>
      <li><a href="#0">Three</a></li>
    </ul>
  </div>
  <div class="top-bar-right">
    <ul class="menu">
      <li><input type="search" placeholder="Search"></li>
      <li><button type="button" class="button">Search</button></li>
    </ul>
  </div>
</div>
```

---

## Visibility Classes


<div class="docs-codepen-container" data-ks-codepen>
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vmjqVG?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p>You are on a small screen or larger.</p>
<p class="show-for-medium">You are on a medium screen or larger.</p>
<p class="show-for-large">You are on a large screen or larger.</p>
<p class="show-for-small-only">You are <em>definitely</em> on a small screen.</p>
<p class="show-for-medium-only">You are <em>definitely</em> on a medium screen.</p>
<p class="show-for-large-only">You are <em>definitely</em> on a large screen.</p>

<p class="hide-for-medium">You are <em>not</em> on a medium screen or larger.</p>
<p class="hide-for-large">You are <em>not</em> on a large screen or larger.</p>
<p class="hide-for-small-only">You are <em>definitely not</em> on a small screen.</p>
<p class="hide-for-medium-only">You are <em>definitely not</em> on a medium screen.</p>
<p class="hide-for-large-only">You are <em>definitely not</em> on a large screen.</p>
<p class="hide">Can't touch this.</p>

<p class="invisible">Can sort of touch this.</p>

<p class="show-for-landscape">You are in landscape orientation.</p>
<p class="show-for-portrait">You are in portrait orientation.</p>

<p class="show-for-sr">This text can only be read by a screen reader.</p>
<p>There's a line of text above this one, you just can't see it.</p>

<p aria-hidden="true">This text can be seen, but won't be read by a screen reader.</p>

<p><a class="show-on-focus" href="#mainContent">Skip to Content</a></p>
<header id="header" role="banner">
</header>
<main id="mainContent" role="main" tabindex="0">
</main>
```
