Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');

/** Keys are source filename/url, values are metadata objects. */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const filenameMetadataMap = new Map();
/** Set of stack strings that have already been parsed. */
const parsedStacks = new Set();

function ensureMetadataStacksAreParsed(parser) {
  if (!utils.GLOBAL_OBJ._sentryModuleMetadata) {
    return;
  }

  for (const stack of Object.keys(utils.GLOBAL_OBJ._sentryModuleMetadata)) {
    const metadata = utils.GLOBAL_OBJ._sentryModuleMetadata[stack];

    if (parsedStacks.has(stack)) {
      continue;
    }

    // Ensure this stack doesn't get parsed again
    parsedStacks.add(stack);

    const frames = parser(stack);

    // Go through the frames starting from the top of the stack and find the first one with a filename
    for (const frame of frames.reverse()) {
      if (frame.filename) {
        // Save the metadata for this filename
        filenameMetadataMap.set(frame.filename, metadata);
        break;
      }
    }
  }
}

/**
 * Retrieve metadata for a specific JavaScript file URL.
 *
 * Metadata is injected by the Sentry bundler plugins using the `_experiments.moduleMetadata` config option.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function getMetadataForUrl(parser, filename) {
  ensureMetadataStacksAreParsed(parser);
  return filenameMetadataMap.get(filename);
}

/**
 * Adds metadata to stack frames.
 *
 * Metadata is injected by the Sentry bundler plugins using the `_experiments.moduleMetadata` config option.
 */
function addMetadataToStackFrames(parser, event) {
  try {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    event.exception.values.forEach(exception => {
      if (!exception.stacktrace) {
        return;
      }

      for (const frame of exception.stacktrace.frames || []) {
        if (!frame.filename || frame.module_metadata) {
          continue;
        }

        const metadata = getMetadataForUrl(parser, frame.filename);

        if (metadata) {
          frame.module_metadata = metadata;
        }
      }
    });
  } catch (_) {
    // To save bundle size we're just try catching here instead of checking for the existence of all the different objects.
  }
}

/**
 * Strips metadata from stack frames.
 */
function stripMetadataFromStackFrames(event) {
  try {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    event.exception.values.forEach(exception => {
      if (!exception.stacktrace) {
        return;
      }

      for (const frame of exception.stacktrace.frames || []) {
        delete frame.module_metadata;
      }
    });
  } catch (_) {
    // To save bundle size we're just try catching here instead of checking for the existence of all the different objects.
  }
}

exports.addMetadataToStackFrames = addMetadataToStackFrames;
exports.getMetadataForUrl = getMetadataForUrl;
exports.stripMetadataFromStackFrames = stripMetadataFromStackFrames;
//# sourceMappingURL=metadata.js.map
