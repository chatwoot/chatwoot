# dom-event-types

An object of DOM event types and their interfaces.

Data scraped from MDN.

## Usage

```shell
npm install --save-dev dom-event-types
```

```js
const eventInterfaces = require("dom-event-interfaces");

console.log(eventInterfaces);
//=> { "abort": { "eventInterface": "Event", "bubbles": false, "cancelable": false }, ... }
```

## Shape

```ts
{
  [eventType]: {
    eventInterface: string
    cancelable?: Boolean
    bubbles?: Boolean
  }
}
```

If `cancelable` or `bubbles` are undefined, it's because there is no entry for them on MDN.

## Duplicates

Some events have duplicate interfaces. To make this package easier to use, duplicates have been removed. You can see a list of events with duplicate interfaces, and the interface that's exported in this project.

| name    | event interfaces                                         | interface in `dom-event-types` |
| ------- | -------------------------------------------------------- | ------------------------------ |
| abort   | Event, ProgressEvent, UIEvent                            | Event                          |
| end     | Event, SpeechSynthesisEvent                              | Event                          |
| error   | ProgressEvent, Event, SpeechSynthesisErrorEvent, UIEvent | Event                          |
| load    | UIEvent, ProgressEvent                                   | UIEvent                        |
| message | ServiceWorkerMessageEvent, MessageEvent                  | MessageEvent                   |
| error   | ProgressEvent, Event, SpeechSynthesisErrorEvent, UIEvent | Event                          |
