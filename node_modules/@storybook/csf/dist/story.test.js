"use strict";

// NOTE Example of internal type definition for @storybook/<X> (where X is a framework)
// NOTE Examples of using types from @storybook/<X> in real project
var Button = function Button() {
  return 'Button';
};

// NOTE Various kind usages
var simple = {
  title: 'simple',
  component: Button,
  decorators: [function (storyFn, context) {
    return "withDecorator(".concat(storyFn(context), ")");
  }],
  parameters: {
    a: function a() {
      return null;
    },
    b: NaN,
    c: Symbol('symbol')
  },
  loaders: [function () {
    return Promise.resolve({
      d: '3'
    });
  }],
  args: {
    a: 1
  },
  argTypes: {
    a: {
      type: {
        name: 'string'
      }
    }
  }
};
var strict = {
  title: 'simple',
  component: Button,
  decorators: [function (storyFn, context) {
    return "withDecorator(".concat(storyFn(context), ")");
  }],
  parameters: {
    a: function a() {
      return null;
    },
    b: NaN,
    c: Symbol('symbol')
  },
  loaders: [function () {
    return Promise.resolve({
      d: '3'
    });
  }],
  args: {
    x: '1'
  },
  argTypes: {
    x: {
      type: {
        name: 'string'
      }
    }
  }
}; // NOTE Various story usages

var Simple = function Simple() {
  return 'Simple';
};

var CSF1Story = function CSF1Story() {
  return 'Named Story';
};

CSF1Story.story = {
  name: 'Another name for story',
  decorators: [function (storyFn) {
    return "Wrapped(".concat(storyFn());
  }],
  parameters: {
    a: [1, '2', {}],
    b: undefined,
    c: Button
  },
  loaders: [function () {
    return Promise.resolve({
      d: '3'
    });
  }],
  args: {
    a: 1
  }
};

var CSF2Story = function CSF2Story() {
  return 'Named Story';
};

CSF2Story.storyName = 'Another name for story';
CSF2Story.decorators = [function (storyFn) {
  return "Wrapped(".concat(storyFn());
}];
CSF2Story.parameters = {
  a: [1, '2', {}],
  b: undefined,
  c: Button
};
CSF2Story.loaders = [function () {
  return Promise.resolve({
    d: '3'
  });
}];
CSF2Story.args = {
  a: 1
};
var CSF3Story = {
  render: function render(args) {
    return 'Named Story';
  },
  name: 'Another name for story',
  decorators: [function (storyFn) {
    return "Wrapped(".concat(storyFn());
  }],
  parameters: {
    a: [1, '2', {}],
    b: undefined,
    c: Button
  },
  loaders: [function () {
    return Promise.resolve({
      d: '3'
    });
  }],
  args: {
    a: 1
  }
};
var CSF3StoryStrict = {
  render: function render(args) {
    return 'Named Story';
  },
  name: 'Another name for story',
  decorators: [function (storyFn) {
    return "Wrapped(".concat(storyFn());
  }],
  parameters: {
    a: [1, '2', {}],
    b: undefined,
    c: Button
  },
  loaders: [function () {
    return Promise.resolve({
      d: '3'
    });
  }],
  args: {
    x: '1'
  }
}; // NOTE Jest forced to define at least one test in file

describe('story', function () {
  test('true', function () {
    return expect(true).toBe(true);
  });
});