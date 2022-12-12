import { hasReporter } from './reporter';
import { configureStandards } from '../../standards';
import constants from '../constants';

function configure(spec) {
  var audit;

  audit = axe._audit;
  if (!audit) {
    throw new Error('No audit configured');
  }

  if (spec.axeVersion || spec.ver) {
    const specVersion = spec.axeVersion || spec.ver;
    if (!/^\d+\.\d+\.\d+(-canary)?/.test(specVersion)) {
      throw new Error(`Invalid configured version ${specVersion}`);
    }

    const [version, canary] = specVersion.split('-');
    const [major, minor, patch] = version.split('.').map(Number);

    const [axeVersion, axeCanary] = axe.version.split('-');
    const [axeMajor, axeMinor, axePatch] = axeVersion.split('.').map(Number);

    if (
      major !== axeMajor ||
      axeMinor < minor ||
      (axeMinor === minor && axePatch < patch) ||
      (major === axeMajor &&
        minor === axeMinor &&
        patch === axePatch &&
        canary &&
        canary !== axeCanary)
    ) {
      throw new Error(
        `Configured version ${specVersion} is not compatible with current axe version ${axe.version}`
      );
    }
  }

  if (
    spec.reporter &&
    (typeof spec.reporter === 'function' || hasReporter(spec.reporter))
  ) {
    audit.reporter = spec.reporter;
  }

  if (spec.checks) {
    if (!Array.isArray(spec.checks)) {
      throw new TypeError('Checks property must be an array');
    }

    spec.checks.forEach(check => {
      if (!check.id) {
        throw new TypeError(
          // eslint-disable-next-line max-len
          `Configured check ${JSON.stringify(
            check
          )} is invalid. Checks must be an object with at least an id property`
        );
      }

      audit.addCheck(check);
    });
  }

  const modifiedRules = [];
  if (spec.rules) {
    if (!Array.isArray(spec.rules)) {
      throw new TypeError('Rules property must be an array');
    }

    spec.rules.forEach(rule => {
      if (!rule.id) {
        throw new TypeError(
          // eslint-disable-next-line max-len
          `Configured rule ${JSON.stringify(
            rule
          )} is invalid. Rules must be an object with at least an id property`
        );
      }

      modifiedRules.push(rule.id);
      audit.addRule(rule);
    });
  }

  if (spec.disableOtherRules) {
    audit.rules.forEach(rule => {
      if (modifiedRules.includes(rule.id) === false) {
        rule.enabled = false;
      }
    });
  }

  if (typeof spec.branding !== 'undefined') {
    audit.setBranding(spec.branding);
  } else {
    audit._constructHelpUrls();
  }

  if (spec.tagExclude) {
    audit.tagExclude = spec.tagExclude;
  }

  // Support runtime localization
  if (spec.locale) {
    audit.applyLocale(spec.locale);
  }

  if (spec.standards) {
    configureStandards(spec.standards);
  }

  if (spec.noHtml) {
    audit.noHtml = true;
  }

  if (spec.allowedOrigins) {
    if (!Array.isArray(spec.allowedOrigins)) {
      throw new TypeError('Allowed origins property must be an array');
    }

    if (spec.allowedOrigins.includes('*')) {
      throw new Error(
        `"*" is not allowed. Use "${constants.allOrigins}" instead`
      );
    }

    audit.setAllowedOrigins(spec.allowedOrigins);
  }
}

export default configure;
