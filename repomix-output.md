This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: .all-contributorsrc, .browserslistrc, .bundler-audit.yml, .codeclimate.yml, .dockerignore, .editorconfig, .env.example, .eslintrc.js, .nvmrc, .prettierrc, .ruby-version, .scss-lint.yml, .slugignore, Capfile, chatwoot.pem, CODE_OF_CONDUCT.md, config.ru, CONTRIBUTING.md, docker-compose.production.yml, docker-compose.yml, docker-compose.test.yml, Gemfile, Gemfile.lock, histore.config.ts, LICENSE, Makefile, package.json, pnpm-lock.yaml, postcss.config.js, Procfile, Procfile.dev, Procfile.test, Rakefile, README.md, repomix-output.txt, schema.rb, SECURITY.md, semantic.yml, tailwind.config.js, VERSION_CW, VERSION_CWCTL, vite.config.js, vitest.setup.js, workbox-config.js
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded

## Additional Info

# Directory Structure
```
.all-contributorsrc
.browserslistrc
.bundler-audit.yml
.codeclimate.yml
.dockerignore
.editorconfig
.eslintrc.js
.nvmrc
.prettierrc
.ruby-version
.scss-lint.yml
.slugignore
Capfile
CODE_OF_CONDUCT.md
config.ru
CONTRIBUTING.md
Gemfile
LICENSE
Makefile
package.json
postcss.config.js
Procfile
Procfile.dev
Procfile.test
Rakefile
README.md
SECURITY.md
semantic.yml
tailwind.config.js
VERSION_CW
VERSION_CWCTL
vitest.setup.js
workbox-config.js
```

# Files

## File: .all-contributorsrc
```
{
  "files": [
    "docs/contributors.md"
  ],
  "imageSize": 48,
  "commit": false,
  "contributors": [
    {
      "login": "nithindavid",
      "name": "Nithin David Thomas",
      "avatar_url": "https://avatars2.githubusercontent.com/u/1277421?v=4",
      "profile": "http://nithindavid.me",
      "contributions": [
        "bug",
        "blog",
        "code",
        "doc",
        "design",
        "maintenance",
        "review"
      ]
    }
    {
      "login": "sojan-official",
      "name": "Sojan Jose",
      "avatar_url": "https://avatars1.githubusercontent.com/u/73185?v=4",
      "profile": "http://sojan.me",
      "contributions": [
        "bug",
        "blog",
        "code",
        "doc",
        "design",
        "maintenance",
        "review"
      ]
    },
    {
      "login": "pranavrajs",
      "name": "Pranav Raj S",
      "avatar_url": "https://avatars3.githubusercontent.com/u/2246121?v=4",
      "profile": "https://github.com/pranavrajs",
      "contributions": [
        "bug",
        "blog",
        "code",
        "doc",
        "design",
        "maintenance",
        "review"
      ]
    },
    {
      "login": "subintp",
      "name": "Subin T P",
      "avatar_url": "https://avatars1.githubusercontent.com/u/1742357?v=4",
      "profile": "http://www.linkedin.com/in/subintp",
      "contributions": [
        "bug",
        "code"
      ]
    },
    {
      "login": "manojmj92",
      "name": "Manoj M J",
      "avatar_url": "https://avatars1.githubusercontent.com/u/4034241?v=4",
      "profile": "https://github.com/manojmj92",
      "contributions": [
        "bug",
        "code",
      ]
    }
  ],
  "contributorsPerLine": 7,
  "projectName": "chatwoot",
  "projectOwner": "chatwoot",
  "repoType": "github",
  "repoHost": "https://github.com"
}
```

## File: .browserslistrc
```
defaults
```

## File: .bundler-audit.yml
```yaml
---
ignore:
  - CVE-2021-41098 # https://github.com/chatwoot/chatwoot/issues/3097 (update once azure blob storage is updated)
```

## File: .codeclimate.yml
```yaml
version: '2'
plugins:
  rubocop:
    enabled: false
    channel: rubocop-0-73
  eslint:
    enabled: false
  csslint:
    enabled: true
  scss-lint:
    enabled: true
  brakeman:
    enabled: false
checks:
  similar-code:
    enabled: false
  method-count:
    enabled: true
    config:
      threshold: 32
  file-lines:
    enabled: true
    config:
      threshold: 300
  method-lines:
    config:
      threshold: 50
exclude_patterns:
  - 'spec/'
  - '**/specs/**/**'
  - '**/spec/**/**'
  - 'db/*'
  - 'bin/**/*'
  - 'db/**/*'
  - 'config/**/*'
  - 'public/**/*'
  - 'vendor/**/*'
  - 'node_modules/**/*'
  - 'lib/tasks/auto_annotate_models.rake'
  - 'app/test-matchers.js'
  - 'docs/*'
  - '**/*.md'
  - '**/*.yml'
  - 'app/javascript/dashboard/i18n/locale'
  - '**/*.stories.js'
  - 'stories/'
  - 'app/javascript/dashboard/components/widgets/conversation/advancedFilterItems/index.js'
  - 'app/javascript/shared/constants/countries.js'
  - 'app/javascript/dashboard/components/widgets/conversation/advancedFilterItems/languages.js'
  - 'app/javascript/dashboard/routes/dashboard/contacts/contactFilterItems/index.js'
  - 'app/javascript/dashboard/routes/dashboard/settings/automation/constants.js'
  - 'app/javascript/dashboard/components/widgets/FilterInput/FilterOperatorTypes.js'
  - 'app/javascript/dashboard/routes/dashboard/settings/reports/constants.js'
  - 'app/javascript/dashboard/store/captain/storeFactory.js'
  - 'app/javascript/dashboard/i18n/index.js'
  - 'app/javascript/widget/i18n/index.js'
  - 'app/javascript/survey/i18n/index.js'
  - 'app/javascript/shared/constants/locales.js'
  - 'app/javascript/dashboard/helper/specs/macrosFixtures.js'
  - 'app/javascript/dashboard/routes/dashboard/settings/macros/constants.js'
  - '**/fixtures/**'
  - '**/*/fixtures.js'
```

## File: .dockerignore
```
.bundle
.env
.env.*
docker-compose.*
docker/Dockerfile
docker/dockerfiles
log
storage
public/system
tmp
.codeclimate.yml
public/packs
node_modules
vendor/bundle
.DS_Store
*.swp
*~
```

## File: .editorconfig
```
# EditorConfig helps developers define and maintain consistent coding styles between different editors and IDEs
# @see http://editorconfig.org
root = true

[*]
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
indent_style = space
tab_width = 2

[*.{rb,erb,js,coffee,json,yml,css,scss,sh,markdown,md,html}]
indent_size = 2
```

## File: .eslintrc.js
```javascript
module.exports = {
  extends: [
    'airbnb-base/legacy',
    'prettier',
    'plugin:vue/vue3-recommended',
    'plugin:vitest-globals/recommended',
    // use recommended-legacy when upgrading the plugin to v4
    'plugin:@intlify/vue-i18n/recommended',
  ],
  overrides: [
    {
      files: ['**/*.spec.{j,t}s?(x)'],
      env: {
        'vitest-globals/env': true,
      },
    },
    {
      files: ['**/*.story.vue'],
      rules: {
        'vue/no-undef-components': [
          'error',
          {
            ignorePatterns: ['Variant', 'Story'],
          },
        ],
        // Story files can have static strings, it doesn't need to handle i18n always.
        'vue/no-bare-strings-in-template': 'off',
        'no-console': 'off',
      },
    },
  ],
  plugins: ['html', 'prettier'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'prettier/prettier': ['error'],
    camelcase: 'off',
    'no-param-reassign': 'off',
    'import/no-extraneous-dependencies': 'off',
    'import/prefer-default-export': 'off',
    'import/no-named-as-default': 'off',
    'jsx-a11y/no-static-element-interactions': 'off',
    'jsx-a11y/click-events-have-key-events': 'off',
    'jsx-a11y/label-has-associated-control': 'off',
    'jsx-a11y/label-has-for': 'off',
    'jsx-a11y/anchor-is-valid': 'off',
    'import/no-unresolved': 'off',
    'vue/html-indent': 'off',
    'vue/multi-word-component-names': 'off',
    'vue/next-tick-style': ['error', 'callback'],
    'vue/block-order': [
      'error',
      {
        order: ['script', 'template', 'style'],
      },
    ],
    'vue/component-name-in-template-casing': [
      'error',
      'PascalCase',
      {
        registeredComponentsOnly: true,
      },
    ],
    'vue/component-options-name-casing': ['error', 'PascalCase'],
    'vue/custom-event-name-casing': ['error', 'camelCase'],
    'vue/define-emits-declaration': ['error'],
    'vue/define-macros-order': [
      'error',
      {
        order: ['defineProps', 'defineEmits'],
        defineExposeLast: false,
      },
    ],
    'vue/define-props-declaration': ['error', 'runtime'],
    'vue/match-component-import-name': ['error'],
    'vue/no-bare-strings-in-template': [
      'error',
      {
        allowlist: [
          '(',
          ')',
          ',',
          '.',
          '&',
          '+',
          '-',
          '=',
          '*',
          '/',
          '#',
          '%',
          '!',
          '?',
          ':',
          '[',
          ']',
          '{',
          '}',
          '<',
          '>',
          '⌘',
          '📄',
          '🎉',
          '💬',
          '👥',
          '📥',
          '🔖',
          '❌',
          '✅',
          '\u00b7',
          '\u2022',
          '\u2010',
          '\u2013',
          '\u2014',
          '\u2212',
          '|',
        ],
        attributes: {
          '/.+/': [
            'title',
            'aria-label',
            'aria-placeholder',
            'aria-roledescription',
            'aria-valuetext',
          ],
          input: ['placeholder'],
        },
        directives: ['v-text'],
      },
    ],
    'vue/no-empty-component-block': 'error',
    'vue/no-multiple-objects-in-class': 'error',
    'vue/no-root-v-if': 'warn',
    'vue/no-static-inline-styles': [
      'error',
      {
        allowBinding: false,
      },
    ],
    'vue/no-template-target-blank': [
      'error',
      {
        allowReferrer: false,
        enforceDynamicLinks: 'always',
      },
    ],
    'vue/no-required-prop-with-default': [
      'error',
      {
        autofix: false,
      },
    ],
    'vue/no-this-in-before-route-enter': 'error',
    'vue/no-undef-components': [
      'error',
      {
        ignorePatterns: [
          '^woot-',
          '^fluent-',
          '^multiselect',
          '^router-link',
          '^router-view',
          '^ninja-keys',
          '^FormulateForm',
          '^FormulateInput',
          '^highlightjs',
        ],
      },
    ],
    'vue/no-unused-emit-declarations': 'error',
    'vue/no-unused-refs': 'error',
    'vue/no-use-v-else-with-v-for': 'error',
    'vue/prefer-true-attribute-shorthand': 'error',
    'vue/no-useless-v-bind': [
      'error',
      {
        ignoreIncludesComment: false,
        ignoreStringEscape: false,
      },
    ],
    'vue/no-v-text': 'error',
    'vue/padding-line-between-blocks': ['error', 'always'],
    'vue/prefer-separate-static-class': 'error',
    'vue/require-explicit-slots': 'error',
    'vue/require-macro-variable-name': [
      'error',
      {
        defineProps: 'props',
        defineEmits: 'emit',
        defineSlots: 'slots',
        useSlots: 'slots',
        useAttrs: 'attrs',
      },
    ],
    'vue/no-unused-properties': [
      'error',
      {
        groups: ['props'],
        deepData: false,
        ignorePublicMembers: false,
        unreferencedOptions: [],
      },
    ],
    'vue/max-attributes-per-line': [
      'error',
      {
        singleline: {
          max: 20,
        },
        multiline: {
          max: 1,
        },
      },
    ],
    'vue/html-self-closing': [
      'error',
      {
        html: {
          void: 'always',
          normal: 'always',
          component: 'always',
        },
        svg: 'always',
        math: 'always',
      },
    ],
    'vue/no-v-html': 'off',
    'vue/component-definition-name-casing': 'off',
    'vue/singleline-html-element-content-newline': 'off',
    'import/extensions': ['off'],
    'no-console': 'error',
    '@intlify/vue-i18n/no-dynamic-keys': 'warn',
    '@intlify/vue-i18n/no-unused-keys': [
      'warn',
      {
        extensions: ['.js', '.vue'],
      },
    ],
  },
  settings: {
    'vue-i18n': {
      localeDir: './app/javascript/*/i18n/**.json',
    },
  },
  env: {
    browser: true,
    node: true,
  },
  globals: {
    bus: true,
    vi: true,
  },
};
```

## File: .nvmrc
```
20.5.1
```

## File: .prettierrc
```
{
  "printWidth": 80,
  "singleQuote": true,
  "trailingComma": "es5",
  "arrowParens": "avoid"
}
```

## File: .ruby-version
```
3.3.3
```

## File: .scss-lint.yml
```yaml
# Default application configuration that all configurations inherit from.

scss_files: '**/*.scss'
plugin_directories: ['.scss-linters']

# List of gem names to load custom linters from (make sure they are already
# installed)
plugin_gems: []

# Default severity of all linters.
severity: warning

linters:
  BangFormat:
    enabled: true
    space_before_bang: true
    space_after_bang: false

  BemDepth:
    enabled: false
    max_elements: 1

  BorderZero:
    enabled: true
    convention: zero # or `none`

  ChainedClasses:
    enabled: false

  ColorKeyword:
    enabled: true

  ColorVariable:
    enabled: true

  Comment:
    enabled: true
    style: silent

  DebugStatement:
    enabled: true

  DeclarationOrder:
    enabled: true

  DisableLinterReason:
    enabled: false

  DuplicateProperty:
    enabled: true

  ElsePlacement:
    enabled: true
    style: new_line

  EmptyLineBetweenBlocks:
    enabled: true
    ignore_single_line_blocks: true

  EmptyRule:
    enabled: true

  ExtendDirective:
    enabled: false

  FinalNewline:
    enabled: true
    present: true

  HexLength:
    enabled: true
    style: short # or 'long'

  HexNotation:
    enabled: true
    style: lowercase # or 'uppercase'

  HexValidation:
    enabled: true

  IdSelector:
    enabled: true

  ImportantRule:
    enabled: false

  ImportPath:
    enabled: true
    leading_underscore: false
    filename_extension: false

  Indentation:
    enabled: true
    allow_non_nested_indentation: false
    character: space # or 'tab'
    width: 2

  LeadingZero:
    enabled: false

  MergeableSelector:
    enabled: true
    force_nesting: true

  NameFormat:
    enabled: true
    allow_leading_underscore: true
    convention: hyphenated_lowercase # or 'camel_case', or 'snake_case', or a regex pattern

  NestingDepth:
    enabled: true
    max_depth: 6
    ignore_parent_selectors: false

  PlaceholderInExtend:
    enabled: true

  PrivateNamingConvention:
    enabled: false
    prefix: _

  PropertyCount:
    enabled: false
    include_nested: false
    max_properties: 10

  PropertySortOrder:
    enabled: true
    ignore_unspecified: false
    min_properties: 2
    separate_groups: false

  PropertySpelling:
    enabled: true
    extra_properties: []
    disabled_properties: []

  PropertyUnits:
    enabled: true
    global: [
        'ch',
        'em',
        'ex',
        'rem', # Font-relative lengths
        'cm',
        'in',
        'mm',
        'pc',
        'pt',
        'px',
        'q', # Absolute lengths
        'vh',
        'vw',
        'vmin',
        'vmax', # Viewport-percentage lengths
        'fr', # Grid fractional lengths
        'deg',
        'grad',
        'rad',
        'turn', # Angle
        'ms',
        's', # Duration
        'Hz',
        'kHz', # Frequency
        'dpi',
        'dpcm',
        'dppx', # Resolution
        '%',
      ] # Other
    properties: {}

  PseudoElement:
    enabled: true

  QualifyingElement:
    enabled: true
    allow_element_with_attribute: false
    allow_element_with_class: false
    allow_element_with_id: false
    exclude:
      - 'app/assets/stylesheets/administrate/components/_buttons.scss'

  SelectorDepth:
    enabled: true
    max_depth: 5

  SelectorFormat:
    enabled: false

  Shorthand:
    enabled: true
    allowed_shorthands: [1, 2, 3, 4]

  SingleLinePerProperty:
    enabled: true
    allow_single_line_rule_sets: true

  SingleLinePerSelector:
    enabled: true

  SpaceAfterComma:
    enabled: true
    style: one_space # or 'no_space', or 'at_least_one_space'

  SpaceAfterComment:
    enabled: false
    style: one_space # or 'no_space', or 'at_least_one_space'
    allow_empty_comments: true

  SpaceAfterPropertyColon:
    enabled: true
    style: one_space # or 'no_space', or 'at_least_one_space', or 'aligned'

  SpaceAfterPropertyName:
    enabled: true

  SpaceAfterVariableColon:
    enabled: false
    style: one_space # or 'no_space', 'at_least_one_space' or 'one_space_or_newline'

  SpaceAfterVariableName:
    enabled: true

  SpaceAroundOperator:
    enabled: true
    style: one_space # or 'at_least_one_space', or 'no_space'

  SpaceBeforeBrace:
    enabled: true
    style: space # or 'new_line'
    allow_single_line_padding: false

  SpaceBetweenParens:
    enabled: true
    spaces: 0

  StringQuotes:
    enabled: true
    style: single_quotes # or double_quotes

  TrailingSemicolon:
    enabled: true

  TrailingWhitespace:
    enabled: true

  TrailingZero:
    enabled: false

  TransitionAll:
    enabled: false

  UnnecessaryMantissa:
    enabled: false

  UnnecessaryParentReference:
    enabled: false

  UrlFormat:
    enabled: true

  UrlQuotes:
    enabled: true

  VariableForProperty:
    enabled: false
    properties: []

  VendorPrefix:
    enabled: true
    identifier_list: base
    additional_identifiers: []
    excluded_identifiers: []

  ZeroUnit:
    enabled: true

  Compass::*:
    enabled: false

exclude:
  - 'app/javascript/widget/assets/scss/_reset.scss'
  - 'app/javascript/widget/assets/scss/sdk.css'
  - 'app/assets/stylesheets/administrate/reset/_normalize.scss'
  - 'app/javascript/shared/assets/stylesheets/*.scss'
```

## File: .slugignore
```
/spec
```

## File: Capfile
```
# Load DSL and Setup Up Stages
require 'capistrano/setup'
require 'capistrano/deploy'

require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rvm'
require 'capistrano/puma'
install_plugin Capistrano::Puma

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
```

## File: CODE_OF_CONDUCT.md
```markdown
# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming,
diverse, inclusive, and healthy community.

## Our Standards

Examples of behavior that contributes to a positive environment for our
community include:

* Demonstrating empathy and kindness toward other people
* Being respectful of differing opinions, viewpoints, and experiences
* Giving and gracefully accepting constructive feedback
* Accepting responsibility and apologizing to those affected by our mistakes,
  and learning from the experience
* Focusing on what is best not just for us as individuals, but for the
  overall community

Examples of unacceptable behavior include:

* The use of sexualized language or imagery, and sexual attention or
  advances of any kind
* Trolling, insulting or derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or email
  address, without their explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards of
acceptable behavior and will take appropriate and fair corrective action in
response to any behavior that they deem inappropriate, threatening, offensive,
or harmful.

Community leaders have the right and responsibility to remove, edit, or reject
comments, commits, code, wiki edits, issues, and other contributions that are
not aligned to this Code of Conduct, and will communicate reasons for moderation
decisions when appropriate.

## Scope

This Code of Conduct applies within all community spaces and also applies when
an individual is officially representing the community in public spaces.
Examples of representing our community include using an official e-mail address,
posting via an official social media account, or acting as an appointed
representative at an online or offline event.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the community leaders responsible for enforcement at
hello@chatwoot.com.
All complaints will be reviewed and investigated promptly and fairly.

All community leaders are obligated to respect the privacy and security of the
reporter of any incident.

## Enforcement Guidelines

Community leaders will follow these Community Impact Guidelines in determining
the consequences for any action they deem in violation of this Code of Conduct:

### 1. Correction

**Community Impact**: Use of inappropriate language or other behavior deemed
unprofessional or unwelcome in the community.

**Consequence**: A private, written warning from community leaders, providing
clarity around the nature of the violation and an explanation of why the
behavior was inappropriate. A public apology may be requested.

### 2. Warning

**Community Impact**: A violation through a single incident or series
of actions.

**Consequence**: A warning with consequences for continued behavior. No
interaction with the people involved, including unsolicited interaction with
those enforcing the Code of Conduct, for a specified period of time. This
includes avoiding interactions in community spaces as well as external channels
like social media. Violating these terms may lead to a temporary or
permanent ban.

### 3. Temporary Ban

**Community Impact**: A serious violation of community standards, including
sustained inappropriate behavior.

**Consequence**: A temporary ban from any sort of interaction or public
communication with the community for a specified period of time. No public or
private interaction with the people involved, including unsolicited interaction
with those enforcing the Code of Conduct, is allowed during this period.
Violating these terms may lead to a permanent ban.

### 4. Permanent Ban

**Community Impact**: Demonstrating a pattern of violation of community
standards, including sustained inappropriate behavior,  harassment of an
individual, or aggression toward or disparagement of classes of individuals.

**Consequence**: A permanent ban from any sort of public interaction within
the community.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage],
version 2.0, available at
https://www.contributor-covenant.org/version/2/0/code_of_conduct.html.

Community Impact Guidelines were inspired by [Mozilla's code of conduct
enforcement ladder](https://github.com/mozilla/diversity).

[homepage]: https://www.contributor-covenant.org

For answers to common questions about this code of conduct, see the FAQ at
https://www.contributor-covenant.org/faq. Translations are available at
https://www.contributor-covenant.org/translations.
```

## File: config.ru
```
# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

run Rails.application
```

## File: CONTRIBUTING.md
```markdown
# Contributing to Chatwoot

Thanks for taking the time to contribute! :tada::+1:

Please refer to our [Contributing Guide](https://www.chatwoot.com/docs/contributing-guide) for detailed instructions on how to contribute.
```

## File: Gemfile
```
source 'https://rubygems.org'

ruby '3.3.3'

##-- base gems for rails --##
gem 'rack-cors', '2.0.0', require: 'rack/cors'
gem 'rails', '~> 7.0.8.4'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

##-- rails application helper gems --##
gem 'acts-as-taggable-on'
gem 'attr_extras'
gem 'browser'
gem 'hashie'
gem 'jbuilder'
gem 'kaminari'
gem 'responders', '>= 3.1.1'
gem 'rest-client'
gem 'telephone_number'
gem 'time_diff'
gem 'tzinfo-data'
gem 'valid_email2'
# compress javascript config.assets.js_compressor
gem 'uglifier'
##-- used for single column multiple binary flags in notification settings/feature flagging --##
gem 'flag_shih_tzu'
# Random name generator for user names
gem 'haikunator'
# Template parsing safely
gem 'liquid'
# Parse Markdown to HTML
gem 'commonmarker'
# Validate Data against JSON Schema
gem 'json_schemer'
# Rack middleware for blocking & throttling abusive requests
gem 'rack-attack', '>= 6.7.0'
# a utility tool for streaming, flexible and safe downloading of remote files
gem 'down'
# authentication type to fetch and send mail over oauth2.0
gem 'gmail_xoauth'
# Lock net-smtp to 0.3.4 to avoid issues with gmail_xoauth2
gem 'net-smtp',  '~> 0.3.4'
# Prevent CSV injection
gem 'csv-safe'

##-- for active storage --##
gem 'aws-sdk-s3', require: false
# original gem isn't maintained actively
# we wanted updated version of faraday which is a dependency for slack-ruby-client
gem 'azure-storage-blob', git: 'https://github.com/chatwoot/azure-storage-ruby', branch: 'chatwoot', require: false
gem 'google-cloud-storage', '>= 1.48.0', require: false
gem 'image_processing'

##-- gems for database --#
gem 'groupdate'
gem 'pg'
gem 'redis'
gem 'redis-namespace'
# super fast record imports in bulk
gem 'activerecord-import'

##--- gems for server & infra configuration ---##
gem 'dotenv-rails', '>= 3.0.0'
gem 'foreman'
gem 'puma'
gem 'vite_rails'
# metrics on heroku
gem 'barnes'

##--- gems for authentication & authorization ---##
gem 'devise', '>= 4.9.4'
gem 'devise-secure_password', git: 'https://github.com/chatwoot/devise-secure_password', branch: 'chatwoot'
gem 'devise_token_auth', '>= 1.2.3'
# authorization
gem 'jwt'
gem 'pundit'
# super admin
gem 'administrate', '>= 0.20.1'
gem 'administrate-field-active_storage', '>= 1.0.3'
gem 'administrate-field-belongs_to_search', '>= 0.9.0'

##--- gems for pubsub service ---##
# https://karolgalanciak.com/blog/2019/11/30/from-activerecord-callbacks-to-publish-slash-subscribe-pattern-and-event-driven-design/
gem 'wisper', '2.0.0'

##--- gems for channels ---##
gem 'facebook-messenger'
gem 'line-bot-api'
gem 'twilio-ruby', '~> 5.66'
# twitty will handle subscription of twitter account events
# gem 'twitty', git: 'https://github.com/chatwoot/twitty'
gem 'twitty', '~> 0.1.5'
# facebook client
gem 'koala'
# slack client
gem 'slack-ruby-client', '~> 2.5.2'
# for dialogflow integrations
gem 'google-cloud-dialogflow-v2', '>= 0.24.0'
gem 'grpc'
# Translate integrations
# 'google-cloud-translate' gem depends on faraday 2.0 version
# this dependency breaks the slack-ruby-client gem
gem 'google-cloud-translate-v3', '>= 0.7.0'

##-- apm and error monitoring ---#
# loaded only when environment variables are set.
# ref application.rb
gem 'ddtrace', require: false
gem 'elastic-apm', require: false
gem 'newrelic_rpm', require: false
gem 'newrelic-sidekiq-metrics', '>= 1.6.2', require: false
gem 'scout_apm', require: false
gem 'sentry-rails', '>= 5.19.0', require: false
gem 'sentry-ruby', require: false
gem 'sentry-sidekiq', '>= 5.19.0', require: false

##-- background job processing --##
gem 'sidekiq', '>= 7.3.1'
# We want cron jobs
gem 'sidekiq-cron', '>= 1.12.0'

##-- Push notification service --##
gem 'fcm'
gem 'web-push', '>= 3.0.1'

##-- geocoding / parse location from ip --##
# http://www.rubygeocoder.com/
gem 'geocoder'
# to parse maxmind db
gem 'maxminddb'

# to create db triggers
gem 'hairtrigger'

gem 'procore-sift'

# parse email
gem 'email_reply_trimmer'

gem 'html2text'

# to calculate working hours
gem 'working_hours'

# full text search for articles
gem 'pg_search'

# Subscriptions, Billing
gem 'stripe'

## - helper gems --##
## to populate db with sample data
gem 'faker'

# Include logrange conditionally in intializer using env variable
gem 'lograge', '~> 0.14.0', require: false

# worked with microsoft refresh token
gem 'omniauth-oauth2'

gem 'audited', '~> 5.4', '>= 5.4.1'

# need for google auth
gem 'omniauth', '>= 2.1.2'
gem 'omniauth-google-oauth2', '>= 1.1.3'
gem 'omniauth-rails_csrf_protection', '~> 1.0', '>= 1.0.2'

## Gems for reponse bot
# adds cosine similarity to postgres using vector extension
gem 'neighbor'
gem 'pgvector'
# Convert Website HTML to Markdown
gem 'reverse_markdown'

gem 'ruby-openai'

### Gems required only in specific deployment environments ###
##############################################################

group :production do
  # we dont want request timing out in development while using byebug
  gem 'rack-timeout'
  # for heroku autoscaling
  gem 'judoscale-rails', require: false
  gem 'judoscale-sidekiq', require: false
end

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'letter_opener'
  gem 'scss_lint', require: false
  gem 'web-console', '>= 4.2.1'

  # used in swagger build
  gem 'json_refs'

  # When we want to squash migrations
  gem 'squasher'

  # profiling
  gem 'rack-mini-profiler', '>= 3.2.0', require: false
  gem 'stackprof'
  # Should install the associated chrome extension to view query logs
  gem 'meta_request', '>= 0.8.3'
end

group :test do
  # fast cleaning of database
  gem 'database_cleaner'
  # mock http calls
  gem 'webmock'
  # test profiling
  gem 'test-prof'
end

group :development, :test do
  gem 'active_record_query_trace'
  ##--- gems for debugging and error reporting ---##
  # static analysis
  gem 'brakeman'
  gem 'bundle-audit', require: false
  gem 'byebug', platform: :mri
  gem 'climate_control'
  gem 'debug', '~> 1.8'
  gem 'factory_bot_rails', '>= 6.4.3'
  gem 'listen'
  gem 'mock_redis'
  gem 'pry-rails'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails', '>= 6.1.5'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'seed_dump'
  gem 'shoulda-matchers'
  gem 'simplecov', '0.17.1', require: false
  gem 'spring'
  gem 'spring-watcher-listen'
end
```

## File: LICENSE
```
Copyright (c) 2017-2024 Chatwoot Inc.

Portions of this software are licensed as follows:

* All content that resides under the "enterprise/" directory of this repository, if that directory exists, is licensed under the license defined in "enterprise/LICENSE".
* All third party components incorporated into the Chatwoot Software are licensed under the original license provided by the owner of the applicable component.
* Content outside of the above mentioned directories or restrictions above is available under the "MIT Expat" license as defined below.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## File: Makefile
```
# Variables
APP_NAME := chatwoot
RAILS_ENV ?= development

# Targets
setup:
	gem install bundler
	bundle install
	pnpm install

db_create:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:create

db_migrate:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:migrate

db_seed:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:seed

db_reset:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:reset

db:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:chatwoot_prepare

console:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails console

server:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails server -b 0.0.0.0 -p 3000

burn:
	bundle && pnpm install

run:
	@if [ -f ./.overmind.sock ]; then \
		echo "Overmind is already running. Use 'make force_run' to start a new instance."; \
	else \
		overmind start -f Procfile.dev; \
	fi

force_run:
	rm -f ./.overmind.sock
	overmind start -f Procfile.dev

debug:
	overmind connect backend

debug_worker:
	overmind connect worker

docker: 
	docker build -t $(APP_NAME) -f ./docker/Dockerfile .

.PHONY: setup db_create db_migrate db_seed db_reset db console server burn docker run force_run debug debug_worker
```

## File: package.json
```json
{
  "name": "@chatwoot/chatwoot",
  "version": "4.0.3",
  "license": "MIT",
  "scripts": {
    "eslint": "eslint app/**/*.{js,vue}",
    "eslint:fix": "eslint app/**/*.{js,vue} --fix",
    "test": "TZ=UTC vitest --no-watch --no-cache --no-coverage --logHeapUsage",
    "test:watch": "TZ=UTC vitest --no-cache --no-coverage",
    "test:coverage": "TZ=UTC vitest --no-watch --no-cache --coverage",
    "start:dev": "foreman start -f ./Procfile.dev",
    "start:test": "RAILS_ENV=test foreman start -f ./Procfile.test",
    "dev": "overmind start -f ./Procfile.dev",
    "ruby:prettier": "bundle exec rubocop -a",
    "build:sdk": "BUILD_MODE=library vite build",
    "prepare": "husky install",
    "size": "size-limit",
    "story:dev": "histoire dev",
    "story:build": "histoire build",
    "story:preview": "histoire preview",
    "sync:i18n": "bin/sync_i18n_file_change"
  },
  "size-limit": [
    {
      "path": "public/vite/assets/widget-*.js",
      "limit": "300 KB"
    },
    {
      "path": "public/packs/js/sdk.js",
      "limit": "40 KB"
    }
  ],
  "dependencies": {
    "@breezystack/lamejs": "^1.2.7",
    "@chatwoot/ninja-keys": "1.2.3",
    "@chatwoot/prosemirror-schema": "1.1.1-next",
    "@chatwoot/utils": "^0.0.40",
    "@formkit/core": "^1.6.7",
    "@formkit/vue": "^1.6.7",
    "@hcaptcha/vue3-hcaptcha": "^1.3.0",
    "@highlightjs/vue-plugin": "^2.1.0",
    "@iconify-json/material-symbols": "^1.2.10",
    "@june-so/analytics-next": "^2.0.0",
    "@lk77/vue3-color": "^3.0.6",
    "@radix-ui/colors": "^3.0.0",
    "@rails/actioncable": "6.1.3",
    "@rails/ujs": "^7.1.400",
    "@scmmishra/pico-search": "0.5.4",
    "@sentry/vue": "^8.31.0",
    "@sindresorhus/slugify": "2.2.1",
    "@tailwindcss/typography": "^0.5.15",
    "@tanstack/vue-table": "^8.20.5",
    "@vitejs/plugin-vue": "^5.1.4",
    "@vue/compiler-sfc": "^3.5.8",
    "@vuelidate/core": "^2.0.3",
    "@vuelidate/validators": "^2.0.4",
    "@vueuse/components": "^12.0.0",
    "@vueuse/core": "^12.0.0",
    "activestorage": "^5.2.6",
    "axios": "^1.7.7",
    "camelcase-keys": "^9.1.3",
    "chart.js": "~4.4.4",
    "color2k": "^2.0.2",
    "company-email-validator": "^1.1.0",
    "core-js": "3.38.1",
    "countries-and-timezones": "^3.6.0",
    "date-fns": "2.21.1",
    "date-fns-tz": "^1.3.3",
    "dompurify": "3.2.4",
    "flag-icons": "^7.2.3",
    "floating-vue": "^5.2.2",
    "highlight.js": "^11.10.0",
    "idb": "^8.0.0",
    "js-cookie": "^3.0.5",
    "lettersanitizer": "^1.0.6",
    "libphonenumber-js": "^1.11.9",
    "markdown-it": "^13.0.2",
    "markdown-it-link-attributes": "^4.0.1",
    "md5": "^2.3.0",
    "mitt": "^3.0.1",
    "opus-recorder": "^8.0.5",
    "semver": "7.6.3",
    "snakecase-keys": "^8.0.1",
    "timezone-phone-codes": "^0.0.2",
    "tinykeys": "^3.0.0",
    "turbolinks": "^5.2.0",
    "urlpattern-polyfill": "^10.0.0",
    "video.js": "7.18.1",
    "videojs-record": "4.5.0",
    "videojs-wavesurfer": "3.8.0",
    "vue": "^3.5.12",
    "vue-chartjs": "5.3.1",
    "vue-datepicker-next": "^1.0.3",
    "vue-dompurify-html": "^5.1.0",
    "vue-i18n": "9.14.3",
    "vue-letter": "^0.2.1",
    "vue-multiselect": "3.1.0",
    "vue-router": "~4.4.5",
    "vue-upload-component": "^3.1.17",
    "vue-virtual-scroller": "^2.0.0-beta.8",
    "vue3-click-away": "^1.2.4",
    "vuedraggable": "^4.1.0",
    "vuex": "~4.1.0",
    "vuex-router-sync": "6.0.0-rc.1",
    "wavesurfer.js": "7.8.6"
  },
  "devDependencies": {
    "@egoist/tailwindcss-icons": "^1.8.1",
    "@histoire/plugin-vue": "0.17.15",
    "@iconify-json/logos": "^1.2.3",
    "@iconify-json/lucide": "^1.2.11",
    "@iconify-json/ph": "^1.2.1",
    "@iconify-json/ri": "^1.2.3",
    "@iconify-json/teenyicons": "^1.2.1",
    "@intlify/eslint-plugin-vue-i18n": "^3.2.0",
    "@size-limit/file": "^8.2.4",
    "@vitest/coverage-v8": "3.0.5",
    "@vue/test-utils": "^2.4.6",
    "autoprefixer": "^10.4.20",
    "eslint": "^8.57.0",
    "eslint-config-airbnb-base": "15.0.0",
    "eslint-config-prettier": "^9.1.0",
    "eslint-interactive": "^11.1.0",
    "eslint-plugin-html": "7.1.0",
    "eslint-plugin-import": "2.30.0",
    "eslint-plugin-prettier": "5.2.1",
    "eslint-plugin-vitest-globals": "^1.5.0",
    "eslint-plugin-vue": "^9.28.0",
    "fake-indexeddb": "^6.0.0",
    "histoire": "0.17.15",
    "husky": "^7.0.0",
    "jsdom": "^24.1.3",
    "lint-staged": "14.0.1",
    "postcss": "^8.4.47",
    "postcss-preset-env": "^8.5.1",
    "prettier": "^3.3.3",
    "prosemirror-model": "^1.22.3",
    "size-limit": "^8.2.4",
    "tailwindcss": "^3.4.13",
    "vite": "^5.4.12",
    "vite-plugin-ruby": "^5.0.0",
    "vitest": "3.0.5"
  },
  "engines": {
    "node": "23.x",
    "pnpm": "10.x"
  },
  "husky": {
    "hooks": {
      "pre-push": "sh bin/validate_push"
    }
  },
  "pnpm": {
    "overrides": {
      "vite-node": "2.0.1",
      "vite": "5.4.12",
      "vitest": "3.0.5"
    }
  },
  "lint-staged": {
    "app/**/*.{js,vue}": [
      "eslint --fix",
      "git add"
    ],
    "*.scss": [
      "scss-lint"
    ]
  },
  "packageManager": "pnpm@10.2.0+sha512.0d27364e0139c6aadeed65ada153135e0ca96c8da42123bd50047f961339dc7a758fc2e944b428f52be570d1bd3372455c1c65fa2e7aa0bfbf931190f9552001"
}
```

## File: postcss.config.js
```javascript
/* eslint-disable */
module.exports = {
  plugins: [
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009',
      },
      stage: 3,
    }),
    require('postcss-import'),
    require('tailwindcss'),
    require('autoprefixer'),
  ],
};
```

## File: Procfile
```
release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && echo $SOURCE_VERSION > .git_sha
web: bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
```

## File: Procfile.dev
```
backend: bin/rails s -p 3000
# https://github.com/mperham/sidekiq/issues/3090#issuecomment-389748695
worker: dotenv bundle exec sidekiq -C config/sidekiq.yml
vite: bin/vite dev
```

## File: Procfile.test
```
backend: RAILS_ENV=test bin/rails s -p 5050
vite: bin/vite dev
worker: RAILS_ENV=test dotenv bundle exec sidekiq -C config/sidekiq.yml
```

## File: Rakefile
```
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks
```

## File: README.md
```markdown
## 🚨 Note: This branch is unstable. For the stable branch's source code, please use the branch [3.x](https://github.com/chatwoot/chatwoot/tree/3.x)


<img src="https://user-images.githubusercontent.com/2246121/282256557-1570674b-d142-4198-9740-69404cc6a339.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="https://user-images.githubusercontent.com/2246121/282256632-87f6a01b-6467-4e0e-8a93-7bbf66d03a17.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

___

# Chatwoot

Customer engagement suite, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.
<p>
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img width="150" alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
  <a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
     <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
  </a>
</p>

<p>
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/e6e3f66332c91e5a4c0c/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fuptime.json" alt="uptime"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fresponse-time.json" alt="response time"></a>
  <a href="https://artifacthub.io/packages/helm/chatwoot/chatwoot"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/artifact-hub" alt="Artifact HUB"></a>
</p>

<img src="https://user-images.githubusercontent.com/2246121/282255783-ee8a50c9-f42d-4752-8201-2d59965a663d.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="https://user-images.githubusercontent.com/2246121/282255784-3d1994ec-d895-4ff5-ac68-d819987e1869.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

Chatwoot is an open-source, self-hosted customer engagement suite. Chatwoot lets you view and manage your customer data, communicate with them irrespective of which medium they use, and re-engage them based on their profile.

## Features

Chatwoot supports the following conversation channels:

 - **Website**: Talk to your customers using our live chat widget and make use of our SDK to identify a user and provide contextual support.
 - **Facebook**: Connect your Facebook pages and start replying to the direct messages to your page.
 - **Instagram**: Connect your Instagram profile and start replying to the direct messages.
 - **Twitter**: Connect your Twitter profiles and reply to direct messages or the tweets where you are mentioned.
 - **Telegram**: Connect your Telegram bot and reply to your customers right from a single dashboard.
 - **WhatsApp**: Connect your WhatsApp business account and manage the conversation in Chatwoot.
 - **Line**: Connect your Line account and manage the conversations in Chatwoot.
 - **SMS**: Connect your Twilio SMS account and reply to the SMS queries in Chatwoot.
 - **API Channel**: Build custom communication channels using our API channel.
 - **Email**: Forward all your email queries to Chatwoot and view it in our integrated dashboard.

And more.

Other features include:

- **CRM**: Save all your customer information right inside Chatwoot, use contact notes to log emails, phone calls, or meeting notes.
- **Custom Attributes**: Define custom attribute attributes to store information about a contact or a conversation and extend the product to match your workflow.
- **Shared multi-brand inboxes**: Manage multiple brands or pages using a shared inbox.
- **Private notes**: Use @mentions and private notes to communicate internally about a conversation.
- **Canned responses (Saved replies)**: Improve the response rate by adding saved replies for frequently asked questions.
- **Conversation Labels**: Use conversation labels to create custom workflows.
- **Auto assignment**: Chatwoot intelligently assigns a ticket to the agents who have access to the inbox depending on their availability and load.
- **Conversation continuity**: If the user has provided an email address through the chat widget, Chatwoot will send an email to the customer under the agent name so that the user can continue the conversation over the email.
- **Multi-lingual support**: Chatwoot supports 10+ languages.
- **Powerful API & Webhooks**: Extend the capability of the software using Chatwoot’s webhooks and APIs.
- **Integrations**: Chatwoot natively integrates with Slack right now. Manage your conversations in Slack without logging into the dashboard.

## Documentation

Detailed documentation is available at [chatwoot.com/help-center](https://www.chatwoot.com/help-center).

## Translation process

The translation process for Chatwoot web and mobile app is managed at [https://translate.chatwoot.com](https://translate.chatwoot.com) using Crowdin. Please read the [translation guide](https://www.chatwoot.com/docs/contributing/translating-chatwoot-to-your-language) for contributing to Chatwoot.

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`.

## Deployment

### Heroku one-click deploy

Deploying Chatwoot to Heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://www.chatwoot.com/docs/environment-variables) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables.


### DigitalOcean 1-Click Kubernetes deployment

Chatwoot now supports 1-Click deployment to DigitalOcean as a kubernetes app.

<a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
  <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
</a>

### Other deployment options

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.


## Community? Questions? Support ?

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.


## Contributors ✨

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2025, Chatwoot Inc - Released under the MIT License.
```

## File: SECURITY.md
```markdown
Chatwoot is looking forward to working with security researchers worldwide to keep Chatwoot and our users safe. If you have found an issue in our systems/applications, please reach out to us.

## Reporting a Vulnerability

We use Github to track the security issues that affect our project. If you believe you have found a vulnerability, please disclose it via this [form](https://github.com/chatwoot/chatwoot/security/advisories/new). This will enable us to review the vulnerability, fix it promptly, and reward you for your efforts.

If you have any questions about the process, contact security@chatwoot.com. 

Please try your best to describe a clear and realistic impact for your report, and please don't open any public issues on GitHub or social media; we're doing our best to respond through Github as quickly as possible.

> Note: Please use the email for questions related to the process. Disclosures should be done via [Github](https://github.com/chatwoot/chatwoot/security/advisories/new)
## Supported versions

| Version | Supported        |
| ------- | --------------   |
| latest   | ️✅               |
| <latest   | ❌               |


## Vulnerabilities we care about 🫣
> Note: Please do not perform testing against Chatwoot production services. Use a `self-hosted instance` to perform tests.
- Remote command execution
- SQL Injection
- Authentication bypass
- Privilege Escalation
- Cross-site scripting (XSS)
- Performing limited admin actions without authorization
- CSRF

You can learn more about our triaging process [here](https://www.chatwoot.com/docs/contributing-guide/security-reports).

## Non-Qualifying Vulnerabilities

We consider the following out of scope, though there may be exceptions.

- Missing HTTP security headers
- Incomplete/Missing SPF/DKIM
- Reports from automated tools or scanners
- Theoretical attacks without proof of exploitability
- Social engineering
- Reflected file download
- Physical attacks
- Weak SSL/TLS/SSH algorithms or protocols
- Attacks involving physical access to a user's device or a device or network that's already seriously compromised (e.g., man-in-the-middle).
- The user attacks themselves
- Incomplete/Missing SPF/DKIM
- Denial of Service attacks
- Brute force attacks
- DNSSEC

If you are unsure about the scope, please create a [report](https://github.com/chatwoot/chatwoot/security/advisories/new).


## Thanks

Thank you for keeping Chatwoot and our users safe. 🙇
```

## File: semantic.yml
```yaml
titleOnly: true
types:
  - Feature
  - Fix
  - Docs
  - Style
  - Refactor
  - Perf
  - Test
  - Build
  - Chore
  - Revert
```

## File: tailwind.config.js
```javascript
const { slateDark } = require('@radix-ui/colors');
import { colors } from './theme/colors';
import { icons } from './theme/icons';
const defaultTheme = require('tailwindcss/defaultTheme');
const {
  iconsPlugin,
  getIconCollections,
} = require('@egoist/tailwindcss-icons');

const defaultSansFonts = [
  '-apple-system',
  'system-ui',
  'BlinkMacSystemFont',
  '"Segoe UI"',
  'Roboto',
  '"Helvetica Neue"',
  'Tahoma',
  'Arial',
  'sans-serif !important',
];

const tailwindConfig = {
  darkMode: 'class',
  content: [
    './enterprise/app/views/**/*.html.erb',
    './app/javascript/widget/**/*.vue',
    './app/javascript/v3/**/*.vue',
    './app/javascript/dashboard/**/*.vue',
    './app/javascript/portal/**/*.vue',
    './app/javascript/shared/**/*.vue',
    './app/javascript/survey/**/*.vue',
    './app/javascript/dashboard/components-next/**/*.vue',
    './app/javascript/dashboard/helper/**/*.js',
    './app/javascript/dashboard/components-next/**/*.js',
    './app/javascript/dashboard/routes/dashboard/**/**/*.js',
    './app/views/**/*.html.erb',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: defaultSansFonts,
        inter: ['Inter', ...defaultSansFonts],
        interDisplay: ['Inter Display', ...defaultSansFonts],
      },
      typography: {
        bubble: {
          css: {
            color: 'rgb(var(--slate-12))',
            lineHeight: '1.6',
            fontSize: '14px',
            '*': {
              '&:first-child': {
                marginTop: '0',
              },
            },
            overflowWrap: 'anywhere',

            strong: {
              color: 'rgb(var(--slate-12))',
              fontWeight: '700',
            },

            b: {
              color: 'rgb(var(--slate-12))',
              fontWeight: '700',
            },

            h1: {
              color: 'rgb(var(--slate-12))',
              fontWeight: '700',
              fontSize: '1.25rem',
              '&:first-child': {
                marginTop: '0',
              },
            },
            h2: {
              color: 'rgb(var(--slate-12))',
              fontWeight: '700',
              fontSize: '1rem',
              '&:first-child': {
                marginTop: '0',
              },
            },
            h3: {
              color: 'rgb(var(--slate-12))',
              fontWeight: '700',
              fontSize: '1rem',
              '&:first-child': {
                marginTop: '0',
              },
            },
            hr: {
              marginTop: '1.5em',
              marginBottom: '1.5em',
            },
            a: {
              color: 'rgb(var(--slate-12))',
              textDecoration: 'underline',
            },
            ul: {
              paddingInlineStart: '0.625em',
            },
            ol: {
              paddingInlineStart: '0.625em',
            },
            'ul li': {
              margin: '0 0 0.5em 1em',
              listStyleType: 'disc',
              '[dir="rtl"] &': {
                margin: '0 1em 0.5em 0',
              },
            },
            'ol li': {
              margin: '0 0 0.5em 1em',
              listStyleType: 'decimal',
              '[dir="rtl"] &': {
                margin: '0 1em 0.5em 0',
              },
            },
            blockquote: {
              color: 'rgb(var(--slate-11))',
              borderLeft: `4px solid rgb(var(--black-alpha-1))`,
              paddingLeft: '1em',
              '[dir="rtl"] &': {
                borderLeft: 'none',
                paddingLeft: '0',
                borderRight: `4px solid rgb(var(--black-alpha-1))`,
                paddingRight: '1em',
              },
              '[dir="ltr"] &': {
                borderRight: 'none',
                paddingRight: '0',
              },
            },
            code: {
              backgroundColor: 'rgb(var(--alpha-3))',
              color: 'rgb(var(--slate-11))',
              padding: '0.2em 0.4em',
              borderRadius: '4px',
              fontSize: '0.95em',
              '&::before': {
                content: `none`,
              },
              '&::after': {
                content: `none`,
              },
            },
            pre: {
              backgroundColor: 'rgb(var(--alpha-3))',
              padding: '1em',
              borderRadius: '6px',
              overflowX: 'auto',
            },
            table: {
              width: '100%',
              borderCollapse: 'collapse',
            },
            th: {
              padding: '0.75em',
              color: 'rgb(var(--slate-12))',
              border: `none`,
              textAlign: 'start',
              fontWeight: '600',
            },
            tr: {
              border: `none`,
            },
            td: {
              padding: '0.75em',
              border: `none`,
            },
            img: {
              maxWidth: '100%',
              height: 'auto',
              marginTop: 'unset',
              marginBottom: 'unset',
            },
          },
        },
      },
    },
    screens: {
      xs: '480px',
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px',
    },
    fontSize: {
      ...defaultTheme.fontSize,
      xxs: '0.625rem',
    },
    colors: {
      transparent: 'transparent',
      white: '#fff',
      'modal-backdrop-light': 'rgba(0, 0, 0, 0.4)',
      'modal-backdrop-dark': 'rgba(0, 0, 0, 0.6)',
      current: 'currentColor',
      ...colors,
      body: slateDark.slate7,
    },
    keyframes: {
      ...defaultTheme.keyframes,
      wiggle: {
        '0%': { transform: 'translateX(0)' },
        '15%': { transform: 'translateX(0.375rem)' },
        '30%': { transform: 'translateX(-0.375rem)' },
        '45%': { transform: 'translateX(0.375rem)' },
        '60%': { transform: 'translateX(-0.375rem)' },
        '75%': { transform: 'translateX(0.375rem)' },
        '90%': { transform: 'translateX(-0.375rem)' },
        '100%': { transform: 'translateX(0)' },
      },
      'fade-in-up': {
        '0%': { opacity: 0, transform: 'translateY(0.5rem)' },
        '100%': { opacity: 1, transform: 'translateY(0)' },
      },
      'loader-pulse': {
        '0%': { opacity: 0.4 },
        '50%': { opacity: 1 },
        '100%': { opacity: 0.4 },
      },
      'card-select': {
        '0%, 100%': {
          transform: 'translateX(0)',
        },
        '50%': {
          transform: 'translateX(1px)',
        },
      },
      shake: {
        '0%, 100%': { transform: 'translateX(0)' },
        '25%': { transform: 'translateX(0.234375rem)' },
        '50%': { transform: 'translateX(-0.234375rem)' },
        '75%': { transform: 'translateX(0.234375rem)' },
      },
    },
    animation: {
      ...defaultTheme.animation,
      wiggle: 'wiggle 0.5s ease-in-out',
      'fade-in-up': 'fade-in-up 0.3s ease-out',
      'loader-pulse': 'loader-pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      'card-select': 'card-select 0.25s ease-in-out',
      shake: 'shake 0.3s ease-in-out 0s 2',
    },
  },
  plugins: [
    // eslint-disable-next-line
    require('@tailwindcss/typography'),
    iconsPlugin({
      collections: {
        woot: { icons },
        ...getIconCollections([
          'lucide',
          'logos',
          'ri',
          'ph',
          'material-symbols',
          'teenyicons',
        ]),
      },
    }),
  ],
};

module.exports = tailwindConfig;
```

## File: VERSION_CW
```
3.13.0
```

## File: VERSION_CWCTL
```
3.2.0
```

## File: vitest.setup.js
```javascript
import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import i18nMessages from 'dashboard/i18n';
import FloatingVue from 'floating-vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: i18nMessages,
});

config.global.plugins = [i18n, FloatingVue];
config.global.stubs = {
  WootModal: { template: '<div><slot/></div>' },
  WootModalHeader: { template: '<div><slot/></div>' },
  WootButton: { template: '<button><slot/></button>' },
};
```

## File: workbox-config.js
```javascript
module.exports = {
  globDirectory: 'public/',
  globPatterns: ['**/*.{png,ico}'],
  swDest: 'public/sw.js',
};
```
