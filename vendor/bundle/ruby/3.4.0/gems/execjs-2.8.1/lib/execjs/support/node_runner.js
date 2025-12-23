(function(program, execJS) { execJS(program) })(function(global, process, module, exports, require, console, setTimeout, setInterval, clearTimeout, clearInterval, setImmediate, clearImmediate) { #{source}
}, function(program) {
  var __process__ = process;

  var printFinal = function(string) {
    process.stdout.write('' + string, function() {
      __process__.exit(0);
    });
  };
  try {
    delete this.process;
    delete this.console;
    delete this.setTimeout;
    delete this.setInterval;
    delete this.clearTimeout;
    delete this.clearInterval;
    delete this.setImmediate;
    delete this.clearImmediate;
    result = program();
    this.process = __process__;
    if (typeof result == 'undefined' && result !== null) {
      printFinal('["ok"]');
    } else {
      try {
        printFinal(JSON.stringify(['ok', result]));
      } catch (err) {
        printFinal(JSON.stringify(['err', '' + err, err.stack]));
      }
    }
  } catch (err) {
    this.process = __process__;
    printFinal(JSON.stringify(['err', '' + err, err.stack]));
  }
});
