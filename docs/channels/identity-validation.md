---
path: '/docs/website-sdk/identity-validation'
title: 'Identity validation in Chatwoot'
---

To make sure the conversations between the customers and the support agents are private and to disallow impersonation, you can setup identity validation Chatwoot.

Identity validation can be enabled by generating an HMAC. The key used to generate HMAC for each webwidget is different and can be copied from Inboxes -> Settings -> Configuration -> Identity Validation -> Copy the token shown there

You can generate HMAC in different languages as shown below.


```php
<?php

$key = 'webwidget.hmac_token';
$message = 'identifier';

$identifier_hash = hash_hmac('sha256', $message, $key);
?>
```

```js
const crypto = require('crypto');

const key = 'webwidget.hmac_token';
const message = 'identifier';

const hash = crypto.createHmac('sha256', key).update(message);

hash.digest('hex');
```

```rb
require 'openssl'
require 'base64'

key = 'webwidget.hmac_token'
message = 'identifier'

OpenSSL::HMAC.hexdigest('sha256', key, message)
```

```elixir
key = 'webwidget.hmac_token'
message = 'identifier'

signature = :crypto.hmac(:sha256, key, message)

Base.encode16(signature, case: :lower)
```


```go
package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
)

func main() {
  secret := []byte("webwidget.hmac_token")
  message := []byte("identifier")

  hash := hmac.New(sha256.New, secret)
  hash.Write(message)
  hex.EncodeToString(hash.Sum(nil))
}
```

```py
import hashlib
import hmac
import base64

message = bytes('webwidget.hmac_token', 'utf-8')
secret = bytes('identifier', 'utf-8')

hash = hmac.new(secret, message, hashlib.sha256)
hash.hexdigest()
```
