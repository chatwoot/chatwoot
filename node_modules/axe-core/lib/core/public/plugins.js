/*eslint no-use-before-define:0 */

function Plugin(spec) {
  this._run = spec.run;
  this._collect = spec.collect;
  this._registry = {};
  spec.commands.forEach(command => {
    axe._audit.registerCommand(command);
  });
}

Plugin.prototype.run = function run() {
  return this._run.apply(this, arguments);
};

Plugin.prototype.collect = function collect() {
  return this._collect.apply(this, arguments);
};

Plugin.prototype.cleanup = function cleanup(done) {
  var q = axe.utils.queue();
  var that = this;
  Object.keys(this._registry).forEach(key => {
    q.defer(_done => {
      that._registry[key].cleanup(_done);
    });
  });
  q.then(done);
};

Plugin.prototype.add = function add(impl) {
  this._registry[impl.id] = impl;
};

function registerPlugin(plugin) {
  axe.plugins[plugin.id] = new Plugin(plugin);
}

export default registerPlugin;
