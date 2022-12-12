# Server-side integration

There are some servers that are not compliant with the [RFC 6265](http://tools.ietf.org/html/rfc6265). For those, some characters that are not encoded by JavaScript Cookie might be treated differently.

Here we document the most important server-side peculiarities and their workarounds. Feel free to send a [Pull Request](https://github.com/js-cookie/js-cookie/blob/master/CONTRIBUTING.md#pull-requests) if you see something that can be improved.

*Disclaimer: This documentation is entirely based on community provided information. The examples below should be used only as a reference.*

## PHP

In PHP, `setcookie()` function encodes cookie values using `urlencode()` function, which applies `%`-encoding but also encodes spaces as `+` signs, [for historical reasons](http://php.net/manual/en/function.urlencode.php#function.urlencode). When cookies are read back via `$_COOKIE` or `filter_input(INPUT_COOKIE)`, they would go trough a decoding process which decodes `%`-encoded sequences and also converts `+` signs back to spaces. However, the plus (`+`) sign is valid cookie character by itself, which means that libraries that adhere to standards will interpret `+` signs differently to PHP.

This presents two types of problems:

1. PHP writes a cookie via `setcookie()` and all spaces get converted to `+` signs. JavaScript Cookie read `+` signs and uses them literally, since it is a valid cookie character.
2. JavaScript Cookie writes a cookie with a value that contains `+` signs and stores it as is, since it is a valid cookie character. PHP read a cookie and converts `+` signs to spaces.

To make both PHP and JavaScript Cookie play nicely together?

**In PHP**, use `setrawcookie()` instead of `setcookie()`:

```php
setrawcookie($name, rawurlencode($value));
```

**In JavaScript**, use a custom converter.

**Example**:

```javascript
var PHPCookies = Cookies.withConverter({
    write: function (value) {
        // Encode all characters according to the "encodeURIComponent" spec
        return encodeURIComponent(value)
            // Revert the characters that are unnecessarily encoded but are
            // allowed in a cookie value, except for the plus sign (%2B)
            .replace(/%(23|24|26|3A|3C|3E|3D|2F|3F|40|5B|5D|5E|60|7B|7D|7C)/g, decodeURIComponent);
    },
    read: function (value) {
        return value
            // Decode the plus sign to spaces first, otherwise "legit" encoded pluses
            // will be replaced incorrectly
            .replace(/\+/g, ' ')
            // Decode all characters according to the "encodeURIComponent" spec
            .replace(/(%[0-9A-Z]{2})+/g, decodeURIComponent);
    }
});
```

Rack seems to have [a similar problem](https://github.com/js-cookie/js-cookie/issues/70#issuecomment-132503017).

## Tomcat

### Version >= 7.x

It seems that there is a situation where Tomcat does not [read the parens correctly](https://github.com/js-cookie/js-cookie/issues/92#issue-107743407). To fix this you need to write a custom write converter.

**Example**:

```javascript
var TomcatCookies = Cookies.withConverter({
  write: function (value) {
      // Encode all characters according to the "encodeURIComponent" spec
      return encodeURIComponent(value)
          // Revert the characters that are unnecessarily encoded but are
          // allowed in a cookie value
          .replace(/%(23|24|26|2B|3A|3C|3E|3D|2F|3F|40|5B|5D|5E|60|7B|7D|7C)/g, decodeURIComponent)
          // Encode the parens that are interpreted incorrectly by Tomcat
          .replace(/[\(\)]/g, escape);
  }
});
```

### Version >= 8.0.15

Since Tomcat 8.0.15, it is possible to configure RFC 6265 compliance by changing your `conf/context.xml` file and adding the new [CookieProcessor](https://tomcat.apache.org/tomcat-8.0-doc/config/cookie-processor.html) nested inside the Context element. It would be like this:

```xml
<Context>
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"/>
</context>
```
And you're all done.

Alternatively, you can check the [Java Cookie](https://github.com/js-cookie/java-cookie) project, which integrates nicely with JavaScript Cookie.

## JBoss 7.1.1

It seems that the servlet implementation of JBoss 7.1.1 [does not read some characters correctly](https://github.com/js-cookie/js-cookie/issues/70#issuecomment-148944674), even though they are allowed as per [RFC 6265](https://tools.ietf.org/html/rfc6265#section-4.1.1). To fix this you need to write a custom converter to send those characters correctly.

**Example**:

```javascript
var JBossCookies = Cookies.withConverter({
    write: function (value) {
        // Encode all characters according to the "encodeURIComponent" spec
        return encodeURIComponent(value)
            // Revert the characters that are unnecessarily encoded but are
            // allowed in a cookie value
            .replace(/%(23|24|26|2B|3A|3C|3E|3D|2F|3F|40|5B|5D|5E|60|7B|7D|7C)/g, decodeURIComponent)
            // Encode again the characters that are not allowed in JBoss 7.1.1, like "[" and "]":
            .replace(/[\[\]]/g, encodeURIComponent);
    }
});
```

Alternatively, you can check the [Java Cookie](https://github.com/js-cookie/java-cookie) project, which integrates nicely with JavaScript Cookie.
