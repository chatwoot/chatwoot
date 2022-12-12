# Check Message Template

Axe-core uses a custom template to handle dynamic check messages (messages that use the `data` property to output values or to determine which message to display). The structure for the messages is as follows:

## Simple Message

A simple message is just a string that doesn't use the `data` property. Most checks uses this format.

```json
{
  "messages": {
    "pass": "Simple message for a passing check"
  }
}
```

## Message with Data

A message can also use the `data` property to output information from the check. If `data` is a String, Boolean, or Number, you can use the syntax `${data}` to have the message output the value of the `data` property.

```js
// check.js
this.data(10);

// check.json
{
    "messages": {
        "pass": "Passed with a value of ${data}"
        // => "Passed with a value of 10"
    }
}
```

If `data` is an object, you can access properties of the object using the syntax `${data.propName}`.

```js
// check.js
this.data({
  contrast: '3:1',
  fontSize: '12px'
});

// check.json
{
    "messages": {
        "fail": "Color-contrast failed with a contrast of ${data.contrast} and font size of ${data.fontSize}"
        // => "Color-contrast failed with a contrast of 3:1 and font size of 12px"
    }
}
```

## Singular and Plural Messages

If the message needs to to know how many items are in the `data` property to determine the type of language to use (singular or plural), you can structure the message to use `singular` and `plural` properties. Use the syntax `${data.values}` to have the message output a comma-separated list of the items (`data.values` is provided by the template code for you).

```js
// check.js
this.data(['item1', 'item2']);

// check.json
{
    "messages": {
        "fail": {
            "singular": "Attribute ${data.values} is not allowed",
            "plural": "Attributes: ${data.values} are not allowed"
        }
        // => Attributes: item1, item2 are not allowed
    }
}
```

## Message Determined by Data

Lastly, a message can use the `data` property to determine which message to display. Structure the message to use properties whose keys are the possible values of `data.messageKey`. You should also provide a `default` message that will be displayed if `messageKey` is not set.

```js
// check.js
this.data({
    messageKey: 'imgNode'
});

// check.json
{
    "messages": {
        "incomplete": {
            "default": "Color-contrast could not be determined"
            "bgImage": "Element's background color could not be determined due to a background image",
            "imgNode": "Element's background color could not be determined because element contains an image node"
        }
        // => Element's background color could not be determined because element contains an image node
    }
}
```

The messages can still use the syntax `${data.propName}` to access other properties on the `data` property.

## Migrating From doT.js Template in Translations

Axe-core use to use doT.js for it's temple library. To migrate from doT.js in a translation file, do the following:

- If the message used `{{=it.data}}` or `{{=it.data.propName}}`, change the message to use the syntax `${data}` or `${data.propName}`.

```diff
{
    "messages": {
-       "incomplete": "Check that the <label> does not need be part of the ARIA {{=it.data}} field's name"
+       "incomplete": "Check that the <label> does not need be part of the ARIA ${data} field's name"
    }
}
```

- If the message used `{{=it.data && it.data.length` to determine using singular or plural language, change the message structure of the message to instead use the `singular` and `plural` properties. Replace `{{=it.data.join(', ')}}` with `${data.values}`.

```diff
{
    "messages": {
-       "fail": "Attribute{{=it.data && it.data.length > 1 ? 's' : ''}} {{=it.data.join(', ')}} {{=it.data && it.data.length > 1 ? 'are' : ' is'}} not allowed
+       "fail": {
+           "singular": "Attribute ${data.values} is not allowed",
+           "plural": "Attributes: ${data.values} are not allowed"
+       }
    }
}
```
