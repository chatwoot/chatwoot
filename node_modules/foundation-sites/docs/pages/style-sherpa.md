---
title: Style Sherpa
description: Bundled with the ZURB Template, Style Sherpa makes it easy to create a style guide for your codebase, with just two files.
library:
  github: https://github.com/zurb/style-sherpa
  docs: https://github.com/zurb/style-sherpa
video: 'paIqrjCm9_k'
---

Style guides are a critical component of a CSS codebase, especially one used by many people. It's important that everyone on a team knows how to build a component. Style guides are that documentation. The docs you're reading right now are a style guide of sorts, for the core Foundation styles.

[Style Sherpa](https://github.com/zurb/style-sherpa) is a small tool bundled with the [ZURB Template](starter-projects.html#zurb-template) that can generate a basic style guide for you quickly. The style guide is created from a single Markdown file, which contains all of the page content, and an HTML template, which defines the structure around the content.

---

## Usage

<p>
  <a class="" data-open-video="1:43"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

The ZURB Template includes the folder `src/styleguide/`, which contains both of the files you need to build your style guide. Like everything else in the ZURB Template, just edit the files and your changes will instantly be compiled

One is a Markdown file, `index.md`. This file contains the contents of your style guide.

The other is a Handlebars template, `template.html`. The contents of your style guide are inserted into this template as HTML. The final file is included in the `dist/` folder of your project as `styleguide.html`.

---

## Writing Content

<p>
  <a class="" data-open-video="5:09"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

The style guide is divided into sections. Generally, each component in your codebase&mdash;think buttons, panels, modals, form controls, and so on&mdash;will have its own section.

Sections are titled with a Markdown heading, which is a single hash mark:

```markdown
# Buttons

Lorem ipsum dolor sit amet, **consectetur adipisicing** elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```

To create a new section, add four line breaks and a new heading:

```markdown
# Buttons

Lorem ipsum dolor sit amet, **consectetur adipisicing** elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.



# Forms

Lorem ipsum dolor sit amet, `<form>` elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```

### Code Samples

<p>
  <a class="" data-open-video="6:28"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

A style guide should always have HTML examples, which explain how to build something. To create a code block in Markdown, surround the code with three backticks. You can also set the language of the code block after the first set of backticks. Style Sherpa will color the syntax for you in the final output.

    ```html
    <button class="button" type="button">This is a button.</button>
    ```

You'll also want to show a live demo of the component below the code sample, so developers can see both the HTML for an element, and what the HTML looks live rendered in one place. Style Sherpa has a shortcut for this: instead of setting `html` as the language in Markdown, set it to `html_example`. This will print a code sample and a live demo with the same code all in one go.

    ```html_example
    <button class="button" type="button">This is a button.</button>
    ```

The output looks something like this:

```html_example
<button class="button" type="button">This is a button.</button>
```

---

## Changing the Template

<p>
  <a class="" data-open-video="3:32"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

The ZURB Template includes a minimal boilerplate for your style guide, but you're free to customize it however you want.

The boilerplate uses Foundation's Vertical Menu&mdash;one item is made for each section. Here's what the Handlebars code looks like:

{{{{raw}}}}
```handlebars
<div class="row">
      
  <div class="large-3 medium-4 columns">
    <dl class="vertical tabs" data-tab>
      {{#each pages}}
        <dd{{#if @first}} class="active"{{/if}}><a href="#{{ anchor }}">{{ title }}</a></dd>
      {{/each}}
    </dl>
  </div>

  <div class="large-9 medium-8 columns">
    <div class="tabs-content">
      {{#each pages}}
        <section class="content {{#if @first}}active{{/if}}" id="{{ anchor }}">
          {{ body }}
        </section>
      {{/each}}
    </div>
  </div>

</div>
```

The template has access to a `pages` variable, which is an array with the data for each page. When looping through `pages` using `{{#each}}`, you have access to these variables:

- `title`: The name of the section.
- `anchor`: The name of the section, formatted as a URL anchor.
- `body`: The content of the section.

{{{{/raw}}}}
