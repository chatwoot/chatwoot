# ecma-re-validator

Pass in a string to validate if it would work in ECMA-262, aka JavaScript.

The information for what is valid and what isn't comes from <http://www.regular-expressions.info/javascript.html>.

## Usage

Pass in either a string or a Regexp:

``` ruby
require 'ecma-re-validator'

re = "[Ss]mith\\\\b"

EcmaReValidator.valid?(re) # true

re = /(?<=a)b/

EcmaReValidator.valid?(re) # false--lookbehinds don't exist in JS
```
