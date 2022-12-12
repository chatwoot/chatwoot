---
title: Right-to-Left Support
description: Foundation can easily adapt its components to work with languages that read from right to left.
video: 'TPz2Uzr4urE'
---

## HTML

You'll need to make a few changes to your markup to get the Javascript components working nice and smooth. In the `<html>` tag, you'll need to add a `dir` attribute with a value of `rtl`. Here's what your `<html>` tag should look like:

```html
<!-- This example is for a right-to-left Arabic layout -->
<html class="no-js" lang="ar" dir="rtl">
```

### Language Code

You'll need to change your lang attribute value to match your language. Here's a handy list of common right-to-left languages and their html codes.

- **Arabic:** `ar`
- **Chinese:** `zh`
- **Farsi:** `fa`
- **Hebrew:** `he`, `iw`
- **Japanese:** `ja`
- **Urdu:** `ur`
- **Yiddish:** `yi`, `ji`

View of a [full list of language codes](http://www.loc.gov/standards/iso639-2/php/code_list.php) on the website of the Library of Congress.

---

## CSS Download

If you use a CSS version of Foundation (the ones you can find on the [download page](http://foundation.zurb.com/sites/download)), you'll need to create a custom download that includes RTL CSS instead of LTR. Just select "Right-to-left" under the Text Direction section of the customizer.

---

## Sass Configuration

If you're using the Sass version of Foundation, open your project's [settings file](sass.html#the-settings-file) (`settings.scss`) and change this variable in the Global section:

```scss
$global-text-direction: rtl;
```

This will convert the framework's components to RTL format.
