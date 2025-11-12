import { createMessage } from '@formkit/core';
import { removeListeners, isKilled, createObserver, diffDeps, applyListeners } from '@formkit/observer';
import { cloneAny, token, eq, empty, has, clone } from '@formkit/utils';

// packages/validation/src/validation.ts
var validatingMessage = /* @__PURE__ */ createMessage({
  type: "state",
  blocking: true,
  visible: false,
  value: true,
  key: "validating"
});
function createValidationPlugin(baseRules = {}) {
  return function validationPlugin(node) {
    let propRules = cloneAny(node.props.validationRules || {});
    let availableRules = { ...baseRules, ...propRules };
    const state = { input: token(), rerun: null, isPassing: true };
    let validation = cloneAny(node.props.validation);
    node.on("prop:validation", ({ payload }) => reboot(payload, propRules));
    node.on(
      "prop:validationRules",
      ({ payload }) => reboot(validation, payload)
    );
    function reboot(newValidation, newRules) {
      if (eq(Object.keys(propRules || {}), Object.keys(newRules || {})) && eq(validation, newValidation))
        return;
      propRules = cloneAny(newRules);
      validation = cloneAny(newValidation);
      availableRules = { ...baseRules, ...propRules };
      node.props.parsedRules?.forEach((validation2) => {
        removeMessage(validation2);
        removeListeners(validation2.observer.receipts);
        validation2.observer.kill();
      });
      node.store.filter(() => false, "validation");
      node.props.parsedRules = parseRules(newValidation, availableRules, node);
      state.isPassing = true;
      validate(node, node.props.parsedRules, state);
    }
    node.props.parsedRules = parseRules(validation, availableRules, node);
    validate(node, node.props.parsedRules, state);
  };
}
function validate(node, validations, state) {
  if (isKilled(node))
    return;
  state.input = token();
  node.store.set(
    /* @__PURE__ */ createMessage({
      key: "failing",
      value: !state.isPassing,
      visible: false
    })
  );
  state.isPassing = true;
  node.store.filter((message) => !message.meta.removeImmediately, "validation");
  validations.forEach(
    (validation) => validation.debounce && clearTimeout(validation.timer)
  );
  if (validations.length) {
    node.store.set(validatingMessage);
    run(0, validations, state, false, () => {
      node.store.remove(validatingMessage.key);
      node.store.set(
        /* @__PURE__ */ createMessage({
          key: "failing",
          value: !state.isPassing,
          visible: false
        })
      );
    });
  }
}
function run(current, validations, state, removeImmediately, complete) {
  const validation = validations[current];
  if (!validation)
    return complete();
  const node = validation.observer;
  if (isKilled(node))
    return;
  const currentRun = state.input;
  validation.state = null;
  function next(async, result) {
    if (state.input !== currentRun)
      return;
    state.isPassing = state.isPassing && !!result;
    validation.queued = false;
    const newDeps = node.stopObserve();
    const diff = diffDeps(validation.deps, newDeps);
    applyListeners(
      node,
      diff,
      function revalidate() {
        try {
          node.store.set(validatingMessage);
        } catch (e) {
        }
        validation.queued = true;
        if (state.rerun)
          clearTimeout(state.rerun);
        state.rerun = setTimeout(
          validate,
          0,
          node,
          validations,
          state
        );
      },
      "unshift"
      // We want these listeners to run before other events are emitted so the 'state.validating' will be reliable.
    );
    validation.deps = newDeps;
    validation.state = result;
    if (result === false) {
      createFailedMessage(validation, removeImmediately || async);
    } else {
      removeMessage(validation);
    }
    if (validations.length > current + 1) {
      const nextValidation = validations[current + 1];
      if ((result || nextValidation.force || !nextValidation.skipEmpty) && nextValidation.state === null) {
        nextValidation.queued = true;
      }
      run(current + 1, validations, state, removeImmediately || async, complete);
    } else {
      complete();
    }
  }
  if ((!empty(node.value) || !validation.skipEmpty) && (state.isPassing || validation.force)) {
    if (validation.queued) {
      runRule(validation, node, (result) => {
        result instanceof Promise ? result.then((r) => next(true, r)) : next(false, result);
      });
    } else {
      run(current + 1, validations, state, removeImmediately, complete);
    }
  } else if (empty(node.value) && validation.skipEmpty && state.isPassing) {
    node.observe();
    node.value;
    next(false, state.isPassing);
  } else {
    next(false, null);
  }
}
function runRule(validation, node, after) {
  if (validation.debounce) {
    validation.timer = setTimeout(() => {
      node.observe();
      after(validation.rule(node, ...validation.args));
    }, validation.debounce);
  } else {
    node.observe();
    after(validation.rule(node, ...validation.args));
  }
}
function removeMessage(validation) {
  const key = `rule_${validation.name}`;
  if (validation.messageObserver) {
    validation.messageObserver = validation.messageObserver.kill();
  }
  if (has(validation.observer.store, key)) {
    validation.observer.store.remove(key);
  }
}
function createFailedMessage(validation, removeImmediately) {
  const node = validation.observer;
  if (isKilled(node))
    return;
  if (!validation.messageObserver) {
    validation.messageObserver = createObserver(node._node);
  }
  validation.messageObserver.watch(
    (node2) => {
      const i18nArgs = createI18nArgs(
        node2,
        validation
      );
      return i18nArgs;
    },
    (i18nArgs) => {
      const customMessage = createCustomMessage(node, validation, i18nArgs);
      const message = /* @__PURE__ */ createMessage({
        blocking: validation.blocking,
        key: `rule_${validation.name}`,
        meta: {
          /**
           * Use this key instead of the message root key to produce i18n validation
           * messages.
           */
          messageKey: validation.name,
          /**
           * For messages that were created *by or after* a debounced or async
           * validation rule — we make note of it so we can immediately remove them
           * as soon as the next commit happens.
           */
          removeImmediately,
          /**
           * Determines if this message should be passed to localization.
           */
          localize: !customMessage,
          /**
           * The arguments that will be passed to the validation rules
           */
          i18nArgs
        },
        type: "validation",
        value: customMessage || "This field is not valid."
      });
      node.store.set(message);
    }
  );
}
function createCustomMessage(node, validation, i18nArgs) {
  const customMessage = node.props.validationMessages && has(node.props.validationMessages, validation.name) ? node.props.validationMessages[validation.name] : void 0;
  if (typeof customMessage === "function") {
    return customMessage(...i18nArgs);
  }
  return customMessage;
}
function createI18nArgs(node, validation) {
  return [
    {
      node,
      name: createMessageName(node),
      args: validation.args
    }
  ];
}
function createMessageName(node) {
  if (typeof node.props.validationLabel === "function") {
    return node.props.validationLabel(node);
  }
  return node.props.validationLabel || node.props.label || node.props.name || String(node.name);
}
var hintPattern = "(?:[\\*+?()0-9]+)";
var rulePattern = "[a-zA-Z][a-zA-Z0-9_]+";
var ruleExtractor = new RegExp(
  `^(${hintPattern}?${rulePattern})(?:\\:(.*)+)?$`,
  "i"
);
var hintExtractor = new RegExp(`^(${hintPattern})(${rulePattern})$`, "i");
var debounceExtractor = /([\*+?]+)?(\(\d+\))([\*+?]+)?/;
var hasDebounce = /\(\d+\)/;
var defaultHints = {
  blocking: true,
  debounce: 0,
  force: false,
  skipEmpty: true,
  name: ""
};
function parseRules(validation, rules, node) {
  if (!validation)
    return [];
  const intents = typeof validation === "string" ? extractRules(validation) : clone(validation);
  return intents.reduce((validations, args) => {
    let rule = args.shift();
    const hints = {};
    if (typeof rule === "string") {
      const [ruleName, parsedHints] = parseHints(rule);
      if (has(rules, ruleName)) {
        rule = rules[ruleName];
        Object.assign(hints, parsedHints);
      }
    }
    if (typeof rule === "function") {
      validations.push({
        observer: createObserver(node),
        rule,
        args,
        timer: 0,
        state: null,
        queued: true,
        deps: /* @__PURE__ */ new Map(),
        ...defaultHints,
        ...fnHints(hints, rule)
      });
    }
    return validations;
  }, []);
}
function extractRules(validation) {
  return validation.split("|").reduce((rules, rule) => {
    const parsedRule = parseRule(rule);
    if (parsedRule) {
      rules.push(parsedRule);
    }
    return rules;
  }, []);
}
function parseRule(rule) {
  const trimmed = rule.trim();
  if (trimmed) {
    const matches = trimmed.match(ruleExtractor);
    if (matches && typeof matches[1] === "string") {
      const ruleName = matches[1].trim();
      const args = matches[2] && typeof matches[2] === "string" ? matches[2].split(",").map((s) => s.trim()) : [];
      return [ruleName, ...args];
    }
  }
  return false;
}
function parseHints(ruleName) {
  const matches = ruleName.match(hintExtractor);
  if (!matches) {
    return [ruleName, { name: ruleName }];
  }
  const map = {
    "*": { force: true },
    "+": { skipEmpty: false },
    "?": { blocking: false }
  };
  const [, hints, rule] = matches;
  const hintGroups = hasDebounce.test(hints) ? hints.match(debounceExtractor) || [] : [, hints];
  return [
    rule,
    [hintGroups[1], hintGroups[2], hintGroups[3]].reduce(
      (hints2, group) => {
        if (!group)
          return hints2;
        if (hasDebounce.test(group)) {
          hints2.debounce = parseInt(group.substr(1, group.length - 1));
        } else {
          group.split("").forEach(
            (hint) => has(map, hint) && Object.assign(hints2, map[hint])
          );
        }
        return hints2;
      },
      { name: rule }
    )
  ];
}
function fnHints(existingHints, rule) {
  if (!existingHints.name) {
    existingHints.name = rule.ruleName || rule.name;
  }
  return ["skipEmpty", "force", "debounce", "blocking"].reduce(
    (hints, hint) => {
      if (has(rule, hint) && !has(hints, hint)) {
        Object.assign(hints, {
          [hint]: rule[hint]
        });
      }
      return hints;
    },
    existingHints
  );
}
function getValidationMessages(node) {
  const messages = /* @__PURE__ */ new Map();
  const extract = (n) => {
    const nodeMessages = [];
    for (const key in n.store) {
      const message = n.store[key];
      if (message.type === "validation" && message.visible && typeof message.value === "string") {
        nodeMessages.push(message);
      }
    }
    if (nodeMessages.length) {
      messages.set(n, nodeMessages);
    }
    return n;
  };
  extract(node).walk(extract);
  return messages;
}

export { createMessageName, createValidationPlugin, getValidationMessages };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.dev.mjs.map