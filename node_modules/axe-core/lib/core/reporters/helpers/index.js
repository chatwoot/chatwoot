import failureSummary from './failure-summary';
import getEnvironmentData from './get-environment-data';
import incompleteFallbackMessage from './incomplete-fallback-msg';
import processAggregate from './process-aggregate';

// Setting up this private/temp namespace for the tests (which cannot yet `import/export` things).
// TODO: remove `_thisWillBeDeletedDoNotUse`
axe._thisWillBeDeletedDoNotUse = axe._thisWillBeDeletedDoNotUse || {};
axe._thisWillBeDeletedDoNotUse.helpers = {
  failureSummary,
  getEnvironmentData,
  incompleteFallbackMessage,
  processAggregate
};

export {
  failureSummary,
  getEnvironmentData,
  incompleteFallbackMessage,
  processAggregate
};
