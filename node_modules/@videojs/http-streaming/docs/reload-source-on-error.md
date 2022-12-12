# Using the reloadSourceOnError Plugin
Call the plugin to activate it:

```js
player.reloadSourceOnError()
```
Now if the player encounters a fatal error during playback, it will automatically
attempt to reload the current source. If the error was caused by a transient
browser or networking problem, this can allow playback to continue with a minimum
of disruption to your viewers.

The plugin will only restart your player once in a 30 second time span so that your
player doesn't get into a reload loop if it encounters non-transient errors. You
can tweak the amount of time required between restarts by adjusting the
`errorInterval` option.

If your video URLs are time-sensitive, the original source could be invalid by the
time an error occurs. If that's the case, you can provide a `getSource` callback
to regenerate a valid source object. In your callback, the `this` keyword is a
reference to the player that errored. The first argument to `getSource` is a
function. Invoke that function and pass in your new source object when you're ready.

```js
player.reloadSourceOnError({

  // getSource allows you to override the source object used when an error occurs
  getSource: function(reload) {
    console.log('Reloading because of an error');

    // call reload() with a fresh source object
    // you can do this step asynchronously if you want (but the error dialog will
    // show up while you're waiting)
    reload({
      src: 'https://example.com/index.m3u8?token=abc123ef789',
      type: 'application/x-mpegURL'
    });
  },

  // errorInterval specifies the minimum amount of seconds that must pass before
  // another reload will be attempted
  errorInterval: 5
});
```
