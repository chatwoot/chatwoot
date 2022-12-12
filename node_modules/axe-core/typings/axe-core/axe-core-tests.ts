import * as axe from '../../axe';

var context: any = document;
var $fixture: any = {};
var options = { iframes: false, selectors: false, elementRef: false };

axe.run(context, {}, (error: Error, results: axe.AxeResults) => {
  if (error) {
    console.log(error);
  }
  console.log(results.passes.length);
  console.log(results.incomplete.length);
  console.log(results.inapplicable.length);
  console.log(results.violations.length);
  console.log(results.violations[0].nodes[0].failureSummary);
});
axe.run().then(function(done: any) {
  done();
});
// additional configuration options
axe.run(context, options, (error: Error, results: axe.AxeResults) => {
  console.log(error || results.passes.length);
});
// axe.run include/exclude
axe.run(
  { include: [['#id1'], ['#id2']] },
  {},
  (error: Error, results: axe.AxeResults) => {
    console.log(error || results);
  }
);
axe.run(
  { exclude: [$fixture[0]] },
  {},
  (error: Error, results: axe.AxeResults) => {
    console.log(error || results);
  }
);
// additional configuration options
axe.run(context, options, (error: Error, results: axe.AxeResults) => {
  console.log(error || results.passes.length);
});
var tagConfigRunOnly: axe.RunOnly = {
  type: 'tag',
  values: ['wcag2a']
};
var tagConfig = {
  runOnly: tagConfigRunOnly
};
axe.run(context, tagConfig, (error: Error, results: axe.AxeResults) => {
  console.log(error || results);
});
axe.run(
  context,
  {
    runOnly: {
      type: 'tags',
      values: ['wcag2a', 'wcag2aa']
    } as axe.RunOnly
  },
  (error: Error, results: axe.AxeResults) => {
    console.log(error || results);
  }
);
axe.run(
  context,
  {
    runOnly: ['wcag2a', 'wcag2aa']
  },
  (error: Error, results: axe.AxeResults) => {
    console.log(error || results);
  }
);
axe.run(
  context,
  {
    runOnly: ['color-contrast', 'heading-order']
  },
  (error: Error, results: axe.AxeResults) => {
    console.log(error || results);
  }
);

var someRulesConfig = {
  rules: {
    'color-contrast': { enabled: false },
    'heading-order': { enabled: true }
  }
};
axe.run(context, someRulesConfig, (error: Error, results: axe.AxeResults) => {
  console.log(error || results);
});

// just context
axe.run(context).then(function(done: any) {
  done();
});
// just options
axe.run(options).then(function(done: any) {
  done();
});
// just callback
axe.run((error: Error, results: axe.AxeResults) => {
  console.log(error || results);
});
// context and callback
axe.run(context, (error: Error, results: axe.AxeResults) => {
  console.log(error || results);
});
// options and callback
axe.run(options, (error: Error, results: axe.AxeResults) => {
  console.log(error || results);
});
// context and options
axe.run(context, options).then(function(done: any) {
  done();
});
// context, options, and callback
axe.run(context, options, (error: Error, results: axe.AxeResults) => {
  console.log(error || results);
});

// axe.configure
var spec: axe.Spec = {
  branding: {
    brand: 'foo',
    application: 'bar'
  },
  reporter: 'v1',
  checks: [
    {
      id: 'custom-check',
      evaluate: function() {
        return true;
      }
    }
  ],
  standards: {
    ariaRoles: {
      'custom-role': {
        type: 'widget',
        requiredAttrs: ['aria-label']
      }
    },
    ariaAttrs: {
      'custom-attr': {
        type: 'boolean'
      }
    },
    htmlElms: {
      'custom-elm': {
        contentTypes: ['flow'],
        allowedRoles: false
      }
    },
    cssColors: {
      customColor: [0, 1, 2, 3]
    }
  },
  rules: [
    {
      id: 'custom-rule',
      any: ['custom-check']
    }
  ]
};
axe.configure(spec);

var source = axe.source;
var version = axe.version;

axe.reset();

axe.getRules(['wcag2aa']);
typeof axe.getRules() === 'object';

const rules = axe.getRules();
rules.forEach(rule => {
  rule.ruleId.substr(1234);
});

// Plugins
var pluginSrc: axe.AxePlugin = {
  id: 'doStuff',
  run: (data: any, callback: Function) => {
    callback();
  },
  commands: [
    {
      id: 'run-doStuff',
      callback: (data: any, callback: Function) => {
        axe.plugins['doStuff'].run(data, callback);
      }
    }
  ]
};
axe.registerPlugin(pluginSrc);
axe.cleanup();

axe.configure({
  locale: {
    checks: {
      foo: {
        fail: 'failure',
        pass: 'success',
        incomplete: {
          foo: 'nar'
        }
      }
    }
  }
});

axe.configure({
  locale: {
    lang: 'foo',
    rules: {
      foo: {
        description: 'desc',
        help: 'help'
      }
    },
    checks: {
      foo: {
        pass: 'pass',
        fail: 'fail',
        incomplete: {
          foo: 'bar'
        }
      }
    }
  }
});
