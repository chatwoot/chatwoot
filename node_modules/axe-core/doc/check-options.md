# Check Options

## Table of Contents

- [How Checks Work](#how-checks-work)
- [Options](#options)
  - [Global Options](#global-options)
  - [aria-allowed-role](#aria-allowed-role)
  - [aria-required-children](#aria-required-children)
  - [aria-roledescription](#aria-roledescription)
  - [color-contrast](#color-contrast)
  - [page-has-heading-one](#page-has-heading-one)
  - [page-has-main](#page-has-main)
  - [page-no-duplicate-banner](#page-no-duplicate-banner)
  - [page-no-duplicate-contentinfo](#page-no-duplicate-contentinfo)
  - [page-no-duplicate-main](#page-no-duplicate-main)
  - [duplicate-img-label](#duplicate-img-label)
  - [label-content-name-mismatch](#label-content-name-mismatch)
  - [has-lang](#has-lang)
  - [valid-lang](#valid-lang)
  - [frame-tested](#frame-tested)
  - [no-autoplay-audio](#no-autoplay-audio)
  - [css-orientation-lock](#css-orientation-lock)
  - [meta-viewport-large](#meta-viewport-large)
  - [meta-viewport](#meta-viewport)
  - [header-present](#header-present)
  - [landmark](#landmark)
  - [p-as-heading](#p-as-heading)
  - [avoid-inline-spacing](#avoid-inline-spacing)
  - [scope-value](#scope-value)
  - [region](#region)

## How Checks Work

[Rules in axe-core](../lib/rules) are made up of one or more individual checks that dictate how the rule works. Each check is typically designed to look for a specific requirement and report back its findings to the rule.

For example, the rule [image-alt](../lib/rules/image-alt.json) uses the checks `has-alt`, `aria-label`, `aria-labelledby`, and `non-empty-title` to determine if the image has an accessible name from an `alt`, `aria-label`, `aria-labelledby`, or `title` attribute (respectively).

Many checks allow you to change how they work through `options` properties. These options can be found in the [checks metadata file](../lib/checks).

For example, the check [has-lang](../lib/checks/language/has-lang.json) takes an `attributes` option which dictates which attributes to check for a lang value.

To customize a check's options, you can use [`axe.configure`](./API.md#api-name-axeconfigure) to configure the check and modify the options as desired.

```js
// configure has-lang check to look at the `hreflang` attribute as well
axe.configure({
  checks: [
    {
      id: 'has-lang',
      options: {
        attributes: ['lang', 'xml:lang', 'hreflang']
      }
    }
  ]
});
```

## Options

### Global Options

All checks allow these global options:

| Option         | Default | Description                                                     |
| -------------- | :------ | :-------------------------------------------------------------- |
| `reviewOnFail` | `false` | Have the check return as "Needs Review" rather than a violation |

### aria-allowed-role

| Option          | Default | Description                                                       |
| --------------- | :------ | :---------------------------------------------------------------- |
| `allowImplicit` | `true`  | Allow the explicit role to match the implicit role of the element |
| `ignoredTags`   | `[]`    | Do not check for allowed roles in the provided HTML elements list |

### aria-required-children

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th align="left">Default</th>
      <th align="left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>reviewEmpty</code>
      </td>
      <td align="left">
        <pre lang=js><code>[
  'doc-bibliography',
  'doc-endnotes',
  'grid',
  'list',
  'listbox',
  'table',
  'tablist',
  'tree',
  'treegrid',
  'rowgroup'
]</code></pre>
        </td>
      <td align="left">List of ARIA roles that should be flagged as "Needs Review" rather than a violation if the element has no owned children</td>
    </tr>
  </tbody>
</table>

### aria-roledescription

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th align="left">Default</th>
      <th align="left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>supportedRoles</code>
      </td>
      <td align="left">
        <pre lang=js><code>[
  'button',
  'img',
  'checkbox',
  'radio',
  'combobox',
  'menuitemcheckbox',
  'menuitemradio'
]</code></pre>
        </td>
      <td align="left">List of ARIA roles that support the <code>aria-roledescription</code> attribute</td>
    </tr>
  </tbody>
</table>

### color-contrast

| Option                                                      | Default | Description                                                                                                                                                                                  |
| ----------------------------------------------------------- | :------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ignoreUnicode`                                             | `true`  | Do not check the color contrast of Unicode characters                                                                                                                                        |
| `ignoreLength`                                              | `false` | Do not check the color contrast of short text content                                                                                                                                        |
| `boldValue`                                                 | `700`   | The minimum CSS `font-weight` value that designates bold text                                                                                                                                |
| `boldTextPt`                                                | `14`    | The minimum CSS `font-size` pt value that designates bold text as being large                                                                                                                |
| `largeTextPt`                                               | `18`    | The minimum CSS `font-size` pt value that designates text as being large                                                                                                                     |
| `shadowOutlineEmMax`                                        | `0.1`   | The maximum `blur-radius` value (in ems) of the CSS `text-shadow` property. `blur-radius` values greater than this value will be treated as a background color rather than an outline color. |
| `contrastRatio`                                             | N/A     | Contrast ratio options                                                                                                                                                                       |
| &nbsp;&nbsp;`contrastRatio.normal`                          | N/A     | Contrast ratio requirements for normal text (non-bold text or text smaller than `largeTextPt`)                                                                                               |
| &nbsp;&nbsp;&nbsp;&nbsp;`contrastRatio.normal.expected`     | `4.5`   | The expected contrast ratio for normal text                                                                                                                                                  |
| &nbsp;&nbsp;&nbsp;&nbsp;`contrastRatio.normal.minThreshold` | N/A     | The minimum contrast ratio the check will apply to. Contrast ratios less than this value will be ignored                                                                                     |
| &nbsp;&nbsp;&nbsp;&nbsp;`contrastRatio.normal.maxThreshold` | N/A     | The maximum contrast ratio the check will apply to. Contrast ratios greater than this value will be ignored                                                                                  |
| &nbsp;&nbsp;`contrastRatio.large`                           | N/A     | Contrast ratio requirements for large text (bold text or text larger than `largeTextPt`)                                                                                                     |
| &nbsp;&nbsp;&nbsp;&nbsp;`contrastRatio.large.expected`      | `4.5`   | The expected contrast contrast ratio for large text                                                                                                                                          |
| &nbsp;&nbsp;&nbsp;&nbsp;`contrastRatio.large.minThreshold`  | N/A     | The minimum contrast ratio the check will apply to. Contrast ratios less than this value will be ignored                                                                                     |
| &nbsp;&nbsp;&nbsp;&nbsp;`contrastRatio.large.maxThreshold`  | N/A     | The maximum contrast ratio the check will apply to. Contrast ratios greater than this value will be ignored                                                                                  |

### page-has-heading-one

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th align="left">Default</th>
      <th align="left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>selector</code>
      </td>
      <td align="left">
        <pre lang=css><code>h1:not([role]):not([aria-level]), 
h1:not([role])[aria-level=1], 
h2:not([role])[aria-level=1], 
h3:not([role])[aria-level=1], 
h4:not([role])[aria-level=1], 
h5:not([role])[aria-level=1], 
h6:not([role])[aria-level=1], 
[role=heading][aria-level=1]</code></pre>
        </td>
      <td align="left">Selector used to determine if a page has a level one heading</td>
    </tr>
  </tbody>
</table>

### page-has-main

| Option     | Default                                             | Description                                                |
| ---------- | :-------------------------------------------------- | :--------------------------------------------------------- |
| `selector` | <pre lang=css>main:not([role]), [role='main']</pre> | Selector used to determine if a page has a `main` landmark |

### page-no-duplicate-banner

| Option              | Default                                                | Description                                                                             |
| ------------------- | :----------------------------------------------------- | :-------------------------------------------------------------------------------------- |
| `selector`          | <pre lang=css>header:not([role]), [role=banner]</pre>  | Selector used to determine if a page has a `banner` landmark                            |
| `nativeScopeFilter` | <pre lang=css>article, aside, main, nav, section</pre> | Selector used to ignore `banner` landmarks that have a parent that matches the selector |

### page-no-duplicate-contentinfo

| Option              | Default                                                    | Description                                                                                           |
| ------------------- | :--------------------------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| `selector`          | <pre lang=css>footer:not([role]), [role=contentinfo]</pre> | Selector used to determine if a page has a `contentinfo` landmark                                     |
| `nativeScopeFilter` | <pre lang=css>article, aside, main, nav, section</pre>     | Option values used to ignore `contentinfo` landmarks that have a selector matching the parent element |

### page-no-duplicate-main

| Option     | Default                                             | Description                                                |
| ---------- | :-------------------------------------------------- | :--------------------------------------------------------- |
| `selector` | <pre lang=css>main:not([role]), [role='main']</pre> | Selector used to determine if a page has a `main` landmark |

### duplicate-img-label

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th align="left">Default</th>
      <th align="left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>parentSelector</code>
      </td>
      <td align="left">
        <pre lang=css><code>button,
[role=button],
a[href],
p,
li,
td,
th</code></pre>
        </td>
      <td align="left">Selector used to look at an image parent that may duplicate the image label</td>
    </tr>
  </tbody>
</table>

### label-content-name-mismatch

| Option               | Default | Description                                                                                                                                                               |
| -------------------- | :------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `pixelThreshold`     | `0.1`   | Percent of difference in pixel data or pixel width required to determine if a font is a ligature font. Ligature fonts are ignored when comparing the label to the content |
| `occuranceThreshold` | `3`     | Number of times the font is encountered before auto-assigning the font as a ligature or not                                                                               |

### has-lang

| Option       | Default                                 | Description                         |
| ------------ | :-------------------------------------- | :---------------------------------- |
| `attributes` | <pre lang=js>['lang', 'xml:lang']</pre> | Attributes to check for lang values |

### valid-lang

| Option       | Default                                                      | Description                               |
| ------------ | :----------------------------------------------------------- | :---------------------------------------- |
| `attributes` | <pre lang=js>['lang', 'xml:lang']</pre>                      | Attributes to check for valid lang values |
| `value`      | [Array of all valid langs](../lib/core/utils/valid-langs.js) | List of valid lang values                 |

### frame-tested

| Option        | Default | Description                                                                               |
| ------------- | :------ | :---------------------------------------------------------------------------------------- |
| `isViolation` | `false` | If an `iframe` that has not been injected with axe-core should be reported as a violation |

### no-autoplay-audio

| Option            | Default | Description                                                                         |
| ----------------- | :------ | :---------------------------------------------------------------------------------- |
| `allowedDuration` | `3`     | Maximum time in seconds an audio clip may autoplay before being marked as violation |

### css-orientation-lock

| Option            | Default | Description                                                                                                                                                             |
| ----------------- | :------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `degreeThreshold` | `3`     | The difference of degrees from 180 and 90 that are considered locked to a specific display orientation (for example, 93° rotated is not considered locked while 94° is) |

### meta-viewport-large

| Option         | Default | Description                                                                                     |
| -------------- | :------ | :---------------------------------------------------------------------------------------------- |
| `scaleMinimum` | `5`     | The `scale-maximum` CSS value of the check applies to. Values above this number will be ignored |
| `lowerBound`   | `2`     | The `scale-minimum` CSS value the check applies to. Values below this number will be ignored    |

### meta-viewport

| Option         | Default | Description                                                                                  |
| -------------- | :------ | :------------------------------------------------------------------------------------------- |
| `scaleMinimum` | `2`     | The `scale-maximum` CSS value the check applies to. Values above this number will be ignored |

### header-present

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th align="left">Default</th>
      <th align="left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>selector</code>
      </td>
      <td align="left">
        <pre lang=css><code>h1:not([role]), 
h2:not([role]), 
h3:not([role]), 
h4:not([role]), 
h5:not([role]), 
h6:not([role]), 
[role=heading]</code></pre>
        </td>
      <td align="left">Selector used to determine if a page has a heading</td>
    </tr>
  </tbody>
</table>

### landmark

| Option     | Default                               | Description                                                |
| ---------- | :------------------------------------ | :--------------------------------------------------------- |
| `selector` | <pre lang=css>main, [role=main]</pre> | Selector used to determine if a page has a landmark region |

### p-as-heading

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th align="left">Default</th>
      <th align="left">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>margins</code>
      </td>
      <td align="left">
        <pre lang=js><code>[
  { "weight": 150, "italic": true }, 
  { "weight": 150, "size": 1.15 }, 
  { "italic": true, "size": 1.15 }, 
  { "size": 1.4 }
]</code></pre>
        </td>
      <td align="left">Common CSS values used to display `p` elements as `h1-h6` elements determining if a `p` element is being improperly repurposed</td>
    </tr>
  </tbody>
</table>

### avoid-inline-spacing

| Option          | Default                                                              | Description                                   |
| --------------- | :------------------------------------------------------------------- | :-------------------------------------------- |
| `cssProperties` | <pre lang=js>['line-height', 'letter-spacing', 'word-spacing']</pre> | List of inline spacing CSS properties to flag |

### scope-value

| Option   | Default                                                   | Description                |
| -------- | :-------------------------------------------------------- | :------------------------- |
| `values` | <pre lang=js>['row', 'col', 'rowgroup', 'colgroup']</pre> | List of valid scope values |

### region

| Option          | Default                                        | Description                                                                 |
| --------------- | :--------------------------------------------- | :-------------------------------------------------------------------------- |
| `regionMatcher` | <pre lang=css>dialog, [role=dialog], svg</pre> | A matcher object or CSS selector to allow elements to be treated as regions |
