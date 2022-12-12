# Plugins

Axe implements a general purpose plugin system that takes advantage of the cross-domain iframe capabilities of axe and allows for adding functionality that extends the axe library outside of its core automated accessibility auditing realm.

The plugin system was initially designed to support functionality like highlighting of elements but has also been utilized for a variety of tasks including implementing functionality that aids with manual accessibility auditing.

## What is a plugin?

Plugins can be viewed as a registry of tools. The plugins themselves are registered with axe and then allow themselves for the registration of plugin instances.

Lets walk through a plugin implementation as an example to illustrate how plugins and plugin instances work.

### A simple "act" plugin

The act plugin will simply perform an action of some sort inside every iframe on the page. An example of how such a plugin might be used is to implement an instance of this plugin that performs highlighting of all of the elements of a particular type on the page.

Plugins currently support two functions, a "run" function and a "collect" function. Together these functions can be combined to implement complex behaviors on top of the axe system.

In order to create such a plugin, we need to implement the "run" function for the plugin, and the command that registers and executes the "run" function within each iframe on the page that contains axe. Lets look at what a noop implementation of this run function would look like:

#### Basic plugin

```js
axe.registerPlugin({
  id: 'doStuff',
  run: function(id, action, options, callback) {
    var frames;
    var q = axe.utils.queue();
    var that = this;
    frames = axe.utils.toArray(document.querySelectorAll('iframe, frame'));

    frames.forEach(function(frame) {
      q.defer(function(done) {
        axe.utils.sendCommandToFrame(
          frame,
          {
            options: options,
            command: 'run-doStuff',
            parameter: id,
            action: action
          },
          function() {
            done();
          }
        );
      });
    });

    if (!options.context.length) {
      q.defer(function(done) {
        that._registry[id][action].call(
          that._registry[id],
          document,
          options,
          done
        );
      });
    }
    q.then(callback);
  },
  commands: [
    {
      id: 'run-doStuff',
      callback: function(data, callback) {
        return axe.plugins.doStuff.run(
          data.parameter,
          data.action,
          data.options,
          callback
        );
      }
    }
  ]
});
```

Looking at the code, you will see the following things:

1. The plugin contains an id. This id is then used to access the plugin and its implementations.
2. The plugin is registered with axe (in each iframe) using the `axe.registerPlugin()` function.
3. The plugin registers the "run" function and the "commands" with the axe system. This allows plugin implementations to be registered with the plugin, and to be executed. It also registers handlers for each of the commands within each of the iframes, so that the plugin can coordinate with itself across the iframe boundaries.

When the caller wants to call a plugin instance, it does so by calling the plugin's "run" function in the top level document and passing the id of the plugin instance it would like to call, which plugin instance action it would like to call, the options and a callback function.

The plugin takes this information and sends the same instructions to its implementation in each iframe by communicating to its own command(s) using the axe utility function `axe.utils.sendCommandToFrame()`.

The plugin waits for the commands in the iframes to complete and then executes its instances' action function within the current document.

In the above implementation, the axe promise utility `axe.utils.queue()` is used to coordinate the asynchronous handling of communication across iframes.

The command handler callback runs the plugin's run function within each iframe. This essentially operates like a recursive call to the run function for the plugin within each iframe.

Once all the iframes' run functions have been executed, the callback is called. This essentially operates as a recursive "return" up the iframe hierarchy until at the top document, the actual callback function is executed. This can be leveraged to pass data back up the iframe hierarchy back to the caller (but this is a more advanced topic).

#### Basic plugin instance

Lets implement a basic plugin instance to see how this works. This instance will implement a "highlight" function (to place a basic frame around the bounding box of an element on each iframe on a page)

```js
var highlight = {
  id: 'highlight',
  highlighter: new Highlighter(),
  run: function(contextNode, options, done) {
    var that = this;
    Array.prototype.slice
      .call(contextNode.querySelectorAll(options.selector))
      .forEach(function(node) {
        that.highlighter.highlight(node, options);
      });
    done();
  },
  cleanup: function(done) {
    this.highlighter.clear();
    done();
  }
};

axe.plugins.doStuff.add(highlight);
```

Above you can see the implementation of a `doStuff` "highlight" instance (the actual highlighting code is not included so as to simplify the example and is left as an exercise for the reader). Plugin instances have an id (which is used to address them), a cleanup function and any number of private or action members. The doStuff `add()` function is called to register this instance with the plugin (notice that we did not have to implement this add function, axe did that for us). In this case, the action is called "run", so after registration, this instance can be called by calling `axe.plugins.doStuff.run('highlight', 'run', options, callback);` in the top-level iframe on the page.

The cleanup functions for all plugin instances are called when the `axe.cleanup()` function is called. Note that this cleanup function will automatically call all the cleanup functions for all the plugin instances in all iframes on the page.
