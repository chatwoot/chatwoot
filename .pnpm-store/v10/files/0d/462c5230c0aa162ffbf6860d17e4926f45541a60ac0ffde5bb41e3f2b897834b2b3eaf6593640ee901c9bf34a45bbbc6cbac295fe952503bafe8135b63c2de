Object.defineProperty(exports, '__esModule', { value: true });

const core = require('@sentry/core');
const utils = require('@sentry/utils');

// exporting a separate copy of `WINDOW` rather than exporting the one from `@sentry/browser`
// prevents the browser package from being bundled in the CDN bundle, and avoids a
// circular dependency between the browser and feedback packages
const WINDOW = utils.GLOBAL_OBJ ;
const DOCUMENT = WINDOW.document;
const NAVIGATOR = WINDOW.navigator;

const TRIGGER_LABEL = 'Report a Bug';
const CANCEL_BUTTON_LABEL = 'Cancel';
const SUBMIT_BUTTON_LABEL = 'Send Bug Report';
const CONFIRM_BUTTON_LABEL = 'Confirm';
const FORM_TITLE = 'Report a Bug';
const EMAIL_PLACEHOLDER = 'your.email@example.org';
const EMAIL_LABEL = 'Email';
const MESSAGE_PLACEHOLDER = "What's the bug? What did you expect?";
const MESSAGE_LABEL = 'Description';
const NAME_PLACEHOLDER = 'Your Name';
const NAME_LABEL = 'Name';
const SUCCESS_MESSAGE_TEXT = 'Thank you for your report!';
const IS_REQUIRED_LABEL = '(required)';
const ADD_SCREENSHOT_LABEL = 'Add a screenshot';
const REMOVE_SCREENSHOT_LABEL = 'Remove screenshot';

const FEEDBACK_WIDGET_SOURCE = 'widget';
const FEEDBACK_API_SOURCE = 'api';

const SUCCESS_MESSAGE_TIMEOUT = 5000;

/**
 * Public API to send a Feedback item to Sentry
 */
const sendFeedback = (
  params,
  hint = { includeReplay: true },
) => {
  if (!params.message) {
    throw new Error('Unable to submit feedback with empty message');
  }

  // We want to wait for the feedback to be sent (or not)
  const client = core.getClient();

  if (!client) {
    throw new Error('No client setup, cannot send feedback.');
  }

  if (params.tags && Object.keys(params.tags).length) {
    core.getCurrentScope().setTags(params.tags);
  }
  const eventId = core.captureFeedback(
    {
      source: FEEDBACK_API_SOURCE,
      url: utils.getLocationHref(),
      ...params,
    },
    hint,
  );

  // We want to wait for the feedback to be sent (or not)
  return new Promise((resolve, reject) => {
    // After 5s, we want to clear anyhow
    const timeout = setTimeout(() => reject('Unable to determine if Feedback was correctly sent.'), 5000);

    const cleanup = client.on('afterSendEvent', (event, response) => {
      if (event.event_id !== eventId) {
        return;
      }

      clearTimeout(timeout);
      cleanup();

      // Require valid status codes, otherwise can assume feedback was not sent successfully
      if (
        response &&
        typeof response.statusCode === 'number' &&
        response.statusCode >= 200 &&
        response.statusCode < 300
      ) {
        resolve(eventId);
      }

      if (response && typeof response.statusCode === 'number' && response.statusCode === 0) {
        return reject(
          'Unable to send Feedback. This is because of network issues, or because you are using an ad-blocker.',
        );
      }

      if (response && typeof response.statusCode === 'number' && response.statusCode === 403) {
        return reject(
          'Unable to send Feedback. This could be because this domain is not in your list of allowed domains.',
        );
      }

      return reject(
        'Unable to send Feedback. This could be because of network issues, or because you are using an ad-blocker',
      );
    });
  });
};

/*
 * For reference, the fully built event looks something like this:
 * {
 *     "type": "feedback",
 *     "event_id": "d2132d31b39445f1938d7e21b6bf0ec4",
 *     "timestamp": 1597977777.6189718,
 *     "dist": "1.12",
 *     "platform": "javascript",
 *     "environment": "production",
 *     "release": 42,
 *     "tags": {"transaction": "/organizations/:orgId/performance/:eventSlug/"},
 *     "sdk": {"name": "name", "version": "version"},
 *     "user": {
 *         "id": "123",
 *         "username": "user",
 *         "email": "user@site.com",
 *         "ip_address": "192.168.11.12",
 *     },
 *     "request": {
 *         "url": None,
 *         "headers": {
 *             "user-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15"
 *         },
 *     },
 *     "contexts": {
 *         "feedback": {
 *             "message": "test message",
 *             "contact_email": "test@example.com",
 *             "type": "feedback",
 *         },
 *         "trace": {
 *             "trace_id": "4C79F60C11214EB38604F4AE0781BFB2",
 *             "span_id": "FA90FDEAD5F74052",
 *             "type": "trace",
 *         },
 *         "replay": {
 *             "replay_id": "e2d42047b1c5431c8cba85ee2a8ab25d",
 *         },
 *     },
 *   }
 */

/**
 * This serves as a build time flag that will be true by default, but false in non-debug builds or if users replace `__SENTRY_DEBUG__` in their generated code.
 *
 * ATTENTION: This constant must never cross package boundaries (i.e. be exported) to guarantee that it can be used for tree shaking.
 */
const DEBUG_BUILD = (typeof __SENTRY_DEBUG__ === 'undefined' || __SENTRY_DEBUG__);

/**
 * Mobile browsers do not support `mediaDevices.getDisplayMedia` even though they have the api implemented
 * Instead they return things like `NotAllowedError` when called.
 *
 * It's simpler for us to browser sniff first, and avoid loading the integration if we can.
 *
 * https://stackoverflow.com/a/58879212
 * https://stackoverflow.com/a/3540295
 *
 * `mediaDevices.getDisplayMedia` is also only supported in secure contexts, and return a `mediaDevices is not supported` error, so we should also avoid loading the integration if we can.
 *
 * https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getDisplayMedia
 */
function isScreenshotSupported() {
  if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(NAVIGATOR.userAgent)) {
    return false;
  }
  /**
   * User agent on iPads show as Macintosh, so we need extra checks
   *
   * https://forums.developer.apple.com/forums/thread/119186
   * https://stackoverflow.com/questions/60482650/how-to-detect-ipad-useragent-on-safari-browser
   */
  if (/Macintosh/i.test(NAVIGATOR.userAgent) && NAVIGATOR.maxTouchPoints && NAVIGATOR.maxTouchPoints > 1) {
    return false;
  }
  if (!isSecureContext) {
    return false;
  }
  return true;
}

/**
 * Quick and dirty deep merge for the Feedback integration options
 */
function mergeOptions(
  defaultOptions,
  optionOverrides,
) {
  return {
    ...defaultOptions,
    ...optionOverrides,
    tags: {
      ...defaultOptions.tags,
      ...optionOverrides.tags,
    },
    onFormOpen: () => {
      optionOverrides.onFormOpen && optionOverrides.onFormOpen();
      defaultOptions.onFormOpen && defaultOptions.onFormOpen();
    },
    onFormClose: () => {
      optionOverrides.onFormClose && optionOverrides.onFormClose();
      defaultOptions.onFormClose && defaultOptions.onFormClose();
    },
    onSubmitSuccess: (data) => {
      optionOverrides.onSubmitSuccess && optionOverrides.onSubmitSuccess(data);
      defaultOptions.onSubmitSuccess && defaultOptions.onSubmitSuccess(data);
    },
    onSubmitError: (error) => {
      optionOverrides.onSubmitError && optionOverrides.onSubmitError(error);
      defaultOptions.onSubmitError && defaultOptions.onSubmitError(error);
    },
    onFormSubmitted: () => {
      optionOverrides.onFormSubmitted && optionOverrides.onFormSubmitted();
      defaultOptions.onFormSubmitted && defaultOptions.onFormSubmitted();
    },
    themeDark: {
      ...defaultOptions.themeDark,
      ...optionOverrides.themeDark,
    },
    themeLight: {
      ...defaultOptions.themeLight,
      ...optionOverrides.themeLight,
    },
  };
}

/**
 * Creates <style> element for widget actor (button that opens the dialog)
 */
function createActorStyles(styleNonce) {
  const style = DOCUMENT.createElement('style');
  style.textContent = `
.widget__actor {
  position: fixed;
  z-index: var(--z-index);
  margin: var(--page-margin);
  inset: var(--actor-inset);

  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px;

  font-family: inherit;
  font-size: var(--font-size);
  font-weight: 600;
  line-height: 1.14em;
  text-decoration: none;

  background: var(--actor-background, var(--background));
  border-radius: var(--actor-border-radius, 1.7em/50%);
  border: var(--actor-border, var(--border));
  box-shadow: var(--actor-box-shadow, var(--box-shadow));
  color: var(--actor-color, var(--foreground));
  fill: var(--actor-color, var(--foreground));
  cursor: pointer;
  opacity: 1;
  transition: transform 0.2s ease-in-out;
  transform: translate(0, 0) scale(1);
}
.widget__actor[aria-hidden="true"] {
  opacity: 0;
  pointer-events: none;
  visibility: hidden;
  transform: translate(0, 16px) scale(0.98);
}

.widget__actor:hover {
  background: var(--actor-hover-background, var(--background));
  filter: var(--interactive-filter);
}

.widget__actor svg {
  width: 1.14em;
  height: 1.14em;
}

@media (max-width: 600px) {
  .widget__actor span {
    display: none;
  }
}
`;

  if (styleNonce) {
    style.setAttribute('nonce', styleNonce);
  }

  return style;
}

/**
 * Helper function to set a dict of attributes on element (w/ specified namespace)
 */
function setAttributesNS(el, attributes) {
  Object.entries(attributes).forEach(([key, val]) => {
    el.setAttributeNS(null, key, val);
  });
  return el;
}

const SIZE = 20;
const XMLNS$2 = 'http://www.w3.org/2000/svg';

/**
 * Feedback Icon
 */
function FeedbackIcon() {
  const createElementNS = (tagName) =>
    WINDOW.document.createElementNS(XMLNS$2, tagName);
  const svg = setAttributesNS(createElementNS('svg'), {
    width: `${SIZE}`,
    height: `${SIZE}`,
    viewBox: `0 0 ${SIZE} ${SIZE}`,
    fill: 'var(--actor-color, var(--foreground))',
  });

  const g = setAttributesNS(createElementNS('g'), {
    clipPath: 'url(#clip0_57_80)',
  });

  const path = setAttributesNS(createElementNS('path'), {
    ['fill-rule']: 'evenodd',
    ['clip-rule']: 'evenodd',
    d: 'M15.6622 15H12.3997C12.2129 14.9959 12.031 14.9396 11.8747 14.8375L8.04965 12.2H7.49956V19.1C7.4875 19.3348 7.3888 19.5568 7.22256 19.723C7.05632 19.8892 6.83435 19.9879 6.59956 20H2.04956C1.80193 19.9968 1.56535 19.8969 1.39023 19.7218C1.21511 19.5467 1.1153 19.3101 1.11206 19.0625V12.2H0.949652C0.824431 12.2017 0.700142 12.1783 0.584123 12.1311C0.468104 12.084 0.362708 12.014 0.274155 11.9255C0.185602 11.8369 0.115689 11.7315 0.0685419 11.6155C0.0213952 11.4995 -0.00202913 11.3752 -0.00034808 11.25V3.75C-0.00900498 3.62067 0.0092504 3.49095 0.0532651 3.36904C0.0972798 3.24712 0.166097 3.13566 0.255372 3.04168C0.344646 2.94771 0.452437 2.87327 0.571937 2.82307C0.691437 2.77286 0.82005 2.74798 0.949652 2.75H8.04965L11.8747 0.1625C12.031 0.0603649 12.2129 0.00407221 12.3997 0H15.6622C15.9098 0.00323746 16.1464 0.103049 16.3215 0.278167C16.4966 0.453286 16.5964 0.689866 16.5997 0.9375V3.25269C17.3969 3.42959 18.1345 3.83026 18.7211 4.41679C19.5322 5.22788 19.9878 6.32796 19.9878 7.47502C19.9878 8.62209 19.5322 9.72217 18.7211 10.5333C18.1345 11.1198 17.3969 11.5205 16.5997 11.6974V14.0125C16.6047 14.1393 16.5842 14.2659 16.5395 14.3847C16.4948 14.5035 16.4268 14.6121 16.3394 14.7042C16.252 14.7962 16.147 14.8698 16.0307 14.9206C15.9144 14.9714 15.7891 14.9984 15.6622 15ZM1.89695 10.325H1.88715V4.625H8.33715C8.52423 4.62301 8.70666 4.56654 8.86215 4.4625L12.6872 1.875H14.7247V13.125H12.6872L8.86215 10.4875C8.70666 10.3835 8.52423 10.327 8.33715 10.325H2.20217C2.15205 10.3167 2.10102 10.3125 2.04956 10.3125C1.9981 10.3125 1.94708 10.3167 1.89695 10.325ZM2.98706 12.2V18.1625H5.66206V12.2H2.98706ZM16.5997 9.93612V5.01393C16.6536 5.02355 16.7072 5.03495 16.7605 5.04814C17.1202 5.13709 17.4556 5.30487 17.7425 5.53934C18.0293 5.77381 18.2605 6.06912 18.4192 6.40389C18.578 6.73866 18.6603 7.10452 18.6603 7.47502C18.6603 7.84552 18.578 8.21139 18.4192 8.54616C18.2605 8.88093 18.0293 9.17624 17.7425 9.41071C17.4556 9.64518 17.1202 9.81296 16.7605 9.90191C16.7072 9.91509 16.6536 9.9265 16.5997 9.93612Z',
  });
  svg.appendChild(g).appendChild(path);

  const speakerDefs = createElementNS('defs');
  const speakerClipPathDef = setAttributesNS(createElementNS('clipPath'), {
    id: 'clip0_57_80',
  });

  const speakerRect = setAttributesNS(createElementNS('rect'), {
    width: `${SIZE}`,
    height: `${SIZE}`,
    fill: 'white',
  });

  speakerClipPathDef.appendChild(speakerRect);
  speakerDefs.appendChild(speakerClipPathDef);

  svg.appendChild(speakerDefs).appendChild(speakerClipPathDef).appendChild(speakerRect);

  return svg;
}

/**
 * The sentry-provided button to open the feedback modal
 */
function Actor({ triggerLabel, triggerAriaLabel, shadow, styleNonce }) {
  const el = DOCUMENT.createElement('button');
  el.type = 'button';
  el.className = 'widget__actor';
  el.ariaHidden = 'false';
  el.ariaLabel = triggerAriaLabel || triggerLabel || TRIGGER_LABEL;
  el.appendChild(FeedbackIcon());
  if (triggerLabel) {
    const label = DOCUMENT.createElement('span');
    label.appendChild(DOCUMENT.createTextNode(triggerLabel));
    el.appendChild(label);
  }

  const style = createActorStyles(styleNonce);

  return {
    el,
    appendToDom() {
      shadow.appendChild(style);
      shadow.appendChild(el);
    },
    removeFromDom() {
      shadow.removeChild(el);
      shadow.removeChild(style);
    },
    show() {
      el.ariaHidden = 'false';
    },
    hide() {
      el.ariaHidden = 'true';
    },
  };
}

const PURPLE = 'rgba(88, 74, 192, 1)';

const DEFAULT_LIGHT = {
  foreground: '#2b2233',
  background: '#ffffff',
  accentForeground: 'white',
  accentBackground: PURPLE,
  successColor: '#268d75',
  errorColor: '#df3338',
  border: '1.5px solid rgba(41, 35, 47, 0.13)',
  boxShadow: '0px 4px 24px 0px rgba(43, 34, 51, 0.12)',
  outline: '1px auto var(--accent-background)',
  interactiveFilter: 'brightness(95%)',
};
const DEFAULT_DARK = {
  foreground: '#ebe6ef',
  background: '#29232f',
  accentForeground: 'white',
  accentBackground: PURPLE,
  successColor: '#2da98c',
  errorColor: '#f55459',
  border: '1.5px solid rgba(235, 230, 239, 0.15)',
  boxShadow: '0px 4px 24px 0px rgba(43, 34, 51, 0.12)',
  outline: '1px auto var(--accent-background)',
  interactiveFilter: 'brightness(150%)',
};

function getThemedCssVariables(theme) {
  return `
  --foreground: ${theme.foreground};
  --background: ${theme.background};
  --accent-foreground: ${theme.accentForeground};
  --accent-background: ${theme.accentBackground};
  --success-color: ${theme.successColor};
  --error-color: ${theme.errorColor};
  --border: ${theme.border};
  --box-shadow: ${theme.boxShadow};
  --outline: ${theme.outline};
  --interactive-filter: ${theme.interactiveFilter};
  `;
}

/**
 * Creates <style> element for widget actor (button that opens the dialog)
 */
function createMainStyles({
  colorScheme,
  themeDark,
  themeLight,
  styleNonce,
}) {
  const style = DOCUMENT.createElement('style');
  style.textContent = `
:host {
  --font-family: system-ui, 'Helvetica Neue', Arial, sans-serif;
  --font-size: 14px;
  --z-index: 100000;

  --page-margin: 16px;
  --inset: auto 0 0 auto;
  --actor-inset: var(--inset);

  font-family: var(--font-family);
  font-size: var(--font-size);

  ${colorScheme !== 'system' ? 'color-scheme: only light;' : ''}

  ${getThemedCssVariables(
    colorScheme === 'dark' ? { ...DEFAULT_DARK, ...themeDark } : { ...DEFAULT_LIGHT, ...themeLight },
  )}
}

${
  colorScheme === 'system'
    ? `
@media (prefers-color-scheme: dark) {
  :host {
    ${getThemedCssVariables({ ...DEFAULT_DARK, ...themeDark })}
  }
}`
    : ''
}
}
`;

  if (styleNonce) {
    style.setAttribute('nonce', styleNonce);
  }

  return style;
}

const buildFeedbackIntegration = ({
  lazyLoadIntegration,
  getModalIntegration,
  getScreenshotIntegration,
}

) => {
  const feedbackIntegration = (({
    // FeedbackGeneralConfiguration
    id = 'sentry-feedback',
    autoInject = true,
    showBranding = true,
    isEmailRequired = false,
    isNameRequired = false,
    showEmail = true,
    showName = true,
    enableScreenshot = true,
    useSentryUser = {
      email: 'email',
      name: 'username',
    },
    tags,
    styleNonce,
    scriptNonce,

    // FeedbackThemeConfiguration
    colorScheme = 'system',
    themeLight = {},
    themeDark = {},

    // FeedbackTextConfiguration
    addScreenshotButtonLabel = ADD_SCREENSHOT_LABEL,
    cancelButtonLabel = CANCEL_BUTTON_LABEL,
    confirmButtonLabel = CONFIRM_BUTTON_LABEL,
    emailLabel = EMAIL_LABEL,
    emailPlaceholder = EMAIL_PLACEHOLDER,
    formTitle = FORM_TITLE,
    isRequiredLabel = IS_REQUIRED_LABEL,
    messageLabel = MESSAGE_LABEL,
    messagePlaceholder = MESSAGE_PLACEHOLDER,
    nameLabel = NAME_LABEL,
    namePlaceholder = NAME_PLACEHOLDER,
    removeScreenshotButtonLabel = REMOVE_SCREENSHOT_LABEL,
    submitButtonLabel = SUBMIT_BUTTON_LABEL,
    successMessageText = SUCCESS_MESSAGE_TEXT,
    triggerLabel = TRIGGER_LABEL,
    triggerAriaLabel = '',

    // FeedbackCallbacks
    onFormOpen,
    onFormClose,
    onSubmitSuccess,
    onSubmitError,
    onFormSubmitted,
  } = {}) => {
    const _options = {
      id,
      autoInject,
      showBranding,
      isEmailRequired,
      isNameRequired,
      showEmail,
      showName,
      enableScreenshot,
      useSentryUser,
      tags,
      styleNonce,
      scriptNonce,

      colorScheme,
      themeDark,
      themeLight,

      triggerLabel,
      triggerAriaLabel,
      cancelButtonLabel,
      submitButtonLabel,
      confirmButtonLabel,
      formTitle,
      emailLabel,
      emailPlaceholder,
      messageLabel,
      messagePlaceholder,
      nameLabel,
      namePlaceholder,
      successMessageText,
      isRequiredLabel,
      addScreenshotButtonLabel,
      removeScreenshotButtonLabel,

      onFormClose,
      onFormOpen,
      onSubmitError,
      onSubmitSuccess,
      onFormSubmitted,
    };

    let _shadow = null;
    let _subscriptions = [];

    /**
     * Get the shadow root where we will append css
     */
    const _createShadow = (options) => {
      if (!_shadow) {
        const host = DOCUMENT.createElement('div');
        host.id = String(options.id);
        DOCUMENT.body.appendChild(host);

        _shadow = host.attachShadow({ mode: 'open' });
        _shadow.appendChild(createMainStyles(options));
      }
      return _shadow ;
    };

    const _findIntegration = async (
      integrationName,
      getter,
      functionMethodName,
    ) => {
      const client = core.getClient();
      const existing = client && client.getIntegrationByName(integrationName);
      if (existing) {
        return existing ;
      }
      const integrationFn = (getter && getter()) || (await lazyLoadIntegration(functionMethodName, scriptNonce));
      const integration = integrationFn();
      client && client.addIntegration(integration);
      return integration ;
    };

    const _loadAndRenderDialog = async (
      options,
    ) => {
      const screenshotRequired = options.enableScreenshot && isScreenshotSupported();
      const [modalIntegration, screenshotIntegration] = await Promise.all([
        _findIntegration('FeedbackModal', getModalIntegration, 'feedbackModalIntegration'),
        screenshotRequired
          ? _findIntegration(
              'FeedbackScreenshot',
              getScreenshotIntegration,
              'feedbackScreenshotIntegration',
            )
          : undefined,
      ]);
      if (!modalIntegration) {
        // TODO: Let the end-user retry async loading
        DEBUG_BUILD &&
          utils.logger.error(
            '[Feedback] Missing feedback modal integration. Try using `feedbackSyncIntegration` in your `Sentry.init`.',
          );
        throw new Error('[Feedback] Missing feedback modal integration!');
      }
      if (screenshotRequired && !screenshotIntegration) {
        DEBUG_BUILD &&
          utils.logger.error('[Feedback] Missing feedback screenshot integration. Proceeding without screenshots.');
      }

      const dialog = modalIntegration.createDialog({
        options: {
          ...options,
          onFormClose: () => {
            dialog && dialog.close();
            options.onFormClose && options.onFormClose();
          },
          onFormSubmitted: () => {
            dialog && dialog.close();
            options.onFormSubmitted && options.onFormSubmitted();
          },
        },
        screenshotIntegration: screenshotRequired ? screenshotIntegration : undefined,
        sendFeedback,
        shadow: _createShadow(options),
      });

      return dialog;
    };

    const _attachTo = (el, optionOverrides = {}) => {
      const mergedOptions = mergeOptions(_options, optionOverrides);

      const targetEl =
        typeof el === 'string' ? DOCUMENT.querySelector(el) : typeof el.addEventListener === 'function' ? el : null;

      if (!targetEl) {
        DEBUG_BUILD && utils.logger.error('[Feedback] Unable to attach to target element');
        throw new Error('Unable to attach to target element');
      }

      let dialog = null;
      const handleClick = async () => {
        if (!dialog) {
          dialog = await _loadAndRenderDialog({
            ...mergedOptions,
            onFormSubmitted: () => {
              dialog && dialog.removeFromDom();
              mergedOptions.onFormSubmitted && mergedOptions.onFormSubmitted();
            },
          });
        }
        dialog.appendToDom();
        dialog.open();
      };
      targetEl.addEventListener('click', handleClick);
      const unsubscribe = () => {
        _subscriptions = _subscriptions.filter(sub => sub !== unsubscribe);
        dialog && dialog.removeFromDom();
        dialog = null;
        targetEl.removeEventListener('click', handleClick);
      };
      _subscriptions.push(unsubscribe);
      return unsubscribe;
    };

    const _createActor = (optionOverrides = {}) => {
      const mergedOptions = mergeOptions(_options, optionOverrides);
      const shadow = _createShadow(mergedOptions);
      const actor = Actor({
        triggerLabel: mergedOptions.triggerLabel,
        triggerAriaLabel: mergedOptions.triggerAriaLabel,
        shadow,
        styleNonce,
      });
      _attachTo(actor.el, {
        ...mergedOptions,
        onFormOpen() {
          actor.hide();
        },
        onFormClose() {
          actor.show();
        },
        onFormSubmitted() {
          actor.show();
        },
      });
      return actor;
    };

    return {
      name: 'Feedback',
      setupOnce() {
        if (!utils.isBrowser() || !_options.autoInject) {
          return;
        }

        if (DOCUMENT.readyState === 'loading') {
          DOCUMENT.addEventListener('DOMContentLoaded', () => _createActor().appendToDom());
        } else {
          _createActor().appendToDom();
        }
      },

      /**
       * Adds click listener to the element to open a feedback dialog
       *
       * The returned function can be used to remove the click listener
       */
      attachTo: _attachTo,

      /**
       * Creates a new widget which is composed of a Button which triggers a Dialog.
       * Accepts partial options to override any options passed to constructor.
       */
      createWidget(optionOverrides = {}) {
        const actor = _createActor(mergeOptions(_options, optionOverrides));
        actor.appendToDom();
        return actor;
      },

      /**
       * Creates a new Form which you can
       * Accepts partial options to override any options passed to constructor.
       */
      async createForm(
        optionOverrides = {},
      ) {
        return _loadAndRenderDialog(mergeOptions(_options, optionOverrides));
      },

      /**
       * Removes the Feedback integration (including host, shadow DOM, and all widgets)
       */
      remove() {
        if (_shadow) {
          _shadow.parentElement && _shadow.parentElement.remove();
          _shadow = null;
        }
        // Remove any lingering subscriptions
        _subscriptions.forEach(sub => sub());
        _subscriptions = [];
      },
    };
  }) ;

  return feedbackIntegration;
};

/**
 * This is a small utility to get a type-safe instance of the Feedback integration.
 */
function getFeedback() {
  const client = core.getClient();
  return client && client.getIntegrationByName('Feedback');
}

var n,l$1,u$1,i$1,o$1,r$1,f$1,c$1={},s$1=[],a$1=/acit|ex(?:s|g|n|p|$)|rph|grid|ows|mnc|ntw|ine[ch]|zoo|^ord|itera/i,h$1=Array.isArray;function v$1(n,l){for(var u in l)n[u]=l[u];return n}function p$1(n){var l=n.parentNode;l&&l.removeChild(n);}function y$1(l,u,t){var i,o,r,f={};for(r in u)"key"==r?i=u[r]:"ref"==r?o=u[r]:f[r]=u[r];if(arguments.length>2&&(f.children=arguments.length>3?n.call(arguments,2):t),"function"==typeof l&&null!=l.defaultProps)for(r in l.defaultProps)void 0===f[r]&&(f[r]=l.defaultProps[r]);return d$1(l,f,i,o,null)}function d$1(n,t,i,o,r){var f={type:n,props:t,key:i,ref:o,__k:null,__:null,__b:0,__e:null,__d:void 0,__c:null,constructor:void 0,__v:null==r?++u$1:r,__i:-1,__u:0};return null==r&&null!=l$1.vnode&&l$1.vnode(f),f}function g$1(n){return n.children}function b$1(n,l){this.props=n,this.context=l;}function m$1(n,l){if(null==l)return n.__?m$1(n.__,n.__i+1):null;for(var u;l<n.__k.length;l++)if(null!=(u=n.__k[l])&&null!=u.__e)return u.__e;return "function"==typeof n.type?m$1(n):null}function w$1(n,u,t){var i,o=n.__v,r=o.__e,f=n.__P;if(f)return (i=v$1({},o)).__v=o.__v+1,l$1.vnode&&l$1.vnode(i),M(f,i,o,n.__n,void 0!==f.ownerSVGElement,32&o.__u?[r]:null,u,null==r?m$1(o):r,!!(32&o.__u),t),i.__.__k[i.__i]=i,i.__d=void 0,i.__e!=r&&k$1(i),i}function k$1(n){var l,u;if(null!=(n=n.__)&&null!=n.__c){for(n.__e=n.__c.base=null,l=0;l<n.__k.length;l++)if(null!=(u=n.__k[l])&&null!=u.__e){n.__e=n.__c.base=u.__e;break}return k$1(n)}}function x$1(n){(!n.__d&&(n.__d=!0)&&i$1.push(n)&&!C$1.__r++||o$1!==l$1.debounceRendering)&&((o$1=l$1.debounceRendering)||r$1)(C$1);}function C$1(){var n,u,t,o=[],r=[];for(i$1.sort(f$1);n=i$1.shift();)n.__d&&(t=i$1.length,u=w$1(n,o,r)||u,0===t||i$1.length>t?(j$1(o,u,r),r.length=o.length=0,u=void 0,i$1.sort(f$1)):u&&l$1.__c&&l$1.__c(u,s$1));u&&j$1(o,u,r),C$1.__r=0;}function P$1(n,l,u,t,i,o,r,f,e,a,h){var v,p,y,d,_,g=t&&t.__k||s$1,b=l.length;for(u.__d=e,S(u,l,g),e=u.__d,v=0;v<b;v++)null!=(y=u.__k[v])&&"boolean"!=typeof y&&"function"!=typeof y&&(p=-1===y.__i?c$1:g[y.__i]||c$1,y.__i=v,M(n,y,p,i,o,r,f,e,a,h),d=y.__e,y.ref&&p.ref!=y.ref&&(p.ref&&N(p.ref,null,y),h.push(y.ref,y.__c||d,y)),null==_&&null!=d&&(_=d),65536&y.__u||p.__k===y.__k?e=$(y,e,n):"function"==typeof y.type&&void 0!==y.__d?e=y.__d:d&&(e=d.nextSibling),y.__d=void 0,y.__u&=-196609);u.__d=e,u.__e=_;}function S(n,l,u){var t,i,o,r,f,e=l.length,c=u.length,s=c,a=0;for(n.__k=[],t=0;t<e;t++)null!=(i=n.__k[t]=null==(i=l[t])||"boolean"==typeof i||"function"==typeof i?null:"string"==typeof i||"number"==typeof i||"bigint"==typeof i||i.constructor==String?d$1(null,i,null,null,i):h$1(i)?d$1(g$1,{children:i},null,null,null):void 0===i.constructor&&i.__b>0?d$1(i.type,i.props,i.key,i.ref?i.ref:null,i.__v):i)?(i.__=n,i.__b=n.__b+1,f=I(i,u,r=t+a,s),i.__i=f,o=null,-1!==f&&(s--,(o=u[f])&&(o.__u|=131072)),null==o||null===o.__v?(-1==f&&a--,"function"!=typeof i.type&&(i.__u|=65536)):f!==r&&(f===r+1?a++:f>r?s>e-r?a+=f-r:a--:a=f<r&&f==r-1?f-r:0,f!==t+a&&(i.__u|=65536))):(o=u[t])&&null==o.key&&o.__e&&(o.__e==n.__d&&(n.__d=m$1(o)),O(o,o,!1),u[t]=null,s--);if(s)for(t=0;t<c;t++)null!=(o=u[t])&&0==(131072&o.__u)&&(o.__e==n.__d&&(n.__d=m$1(o)),O(o,o));}function $(n,l,u){var t,i;if("function"==typeof n.type){for(t=n.__k,i=0;t&&i<t.length;i++)t[i]&&(t[i].__=n,l=$(t[i],l,u));return l}n.__e!=l&&(u.insertBefore(n.__e,l||null),l=n.__e);do{l=l&&l.nextSibling;}while(null!=l&&8===l.nodeType);return l}function I(n,l,u,t){var i=n.key,o=n.type,r=u-1,f=u+1,e=l[u];if(null===e||e&&i==e.key&&o===e.type)return u;if(t>(null!=e&&0==(131072&e.__u)?1:0))for(;r>=0||f<l.length;){if(r>=0){if((e=l[r])&&0==(131072&e.__u)&&i==e.key&&o===e.type)return r;r--;}if(f<l.length){if((e=l[f])&&0==(131072&e.__u)&&i==e.key&&o===e.type)return f;f++;}}return -1}function T$1(n,l,u){"-"===l[0]?n.setProperty(l,null==u?"":u):n[l]=null==u?"":"number"!=typeof u||a$1.test(l)?u:u+"px";}function A$1(n,l,u,t,i){var o;n:if("style"===l)if("string"==typeof u)n.style.cssText=u;else {if("string"==typeof t&&(n.style.cssText=t=""),t)for(l in t)u&&l in u||T$1(n.style,l,"");if(u)for(l in u)t&&u[l]===t[l]||T$1(n.style,l,u[l]);}else if("o"===l[0]&&"n"===l[1])o=l!==(l=l.replace(/(PointerCapture)$|Capture$/i,"$1")),l=l.toLowerCase()in n?l.toLowerCase().slice(2):l.slice(2),n.l||(n.l={}),n.l[l+o]=u,u?t?u.u=t.u:(u.u=Date.now(),n.addEventListener(l,o?L:D$1,o)):n.removeEventListener(l,o?L:D$1,o);else {if(i)l=l.replace(/xlink(H|:h)/,"h").replace(/sName$/,"s");else if("width"!==l&&"height"!==l&&"href"!==l&&"list"!==l&&"form"!==l&&"tabIndex"!==l&&"download"!==l&&"rowSpan"!==l&&"colSpan"!==l&&"role"!==l&&l in n)try{n[l]=null==u?"":u;break n}catch(n){}"function"==typeof u||(null==u||!1===u&&"-"!==l[4]?n.removeAttribute(l):n.setAttribute(l,u));}}function D$1(n){if(this.l){var u=this.l[n.type+!1];if(n.t){if(n.t<=u.u)return}else n.t=Date.now();return u(l$1.event?l$1.event(n):n)}}function L(n){if(this.l)return this.l[n.type+!0](l$1.event?l$1.event(n):n)}function M(n,u,t,i,o,r,f,e,c,s){var a,p,y,d,_,m,w,k,x,C,S,$,H,I,T,A=u.type;if(void 0!==u.constructor)return null;128&t.__u&&(c=!!(32&t.__u),r=[e=u.__e=t.__e]),(a=l$1.__b)&&a(u);n:if("function"==typeof A)try{if(k=u.props,x=(a=A.contextType)&&i[a.__c],C=a?x?x.props.value:a.__:i,t.__c?w=(p=u.__c=t.__c).__=p.__E:("prototype"in A&&A.prototype.render?u.__c=p=new A(k,C):(u.__c=p=new b$1(k,C),p.constructor=A,p.render=q$1),x&&x.sub(p),p.props=k,p.state||(p.state={}),p.context=C,p.__n=i,y=p.__d=!0,p.__h=[],p._sb=[]),null==p.__s&&(p.__s=p.state),null!=A.getDerivedStateFromProps&&(p.__s==p.state&&(p.__s=v$1({},p.__s)),v$1(p.__s,A.getDerivedStateFromProps(k,p.__s))),d=p.props,_=p.state,p.__v=u,y)null==A.getDerivedStateFromProps&&null!=p.componentWillMount&&p.componentWillMount(),null!=p.componentDidMount&&p.__h.push(p.componentDidMount);else {if(null==A.getDerivedStateFromProps&&k!==d&&null!=p.componentWillReceiveProps&&p.componentWillReceiveProps(k,C),!p.__e&&(null!=p.shouldComponentUpdate&&!1===p.shouldComponentUpdate(k,p.__s,C)||u.__v===t.__v)){for(u.__v!==t.__v&&(p.props=k,p.state=p.__s,p.__d=!1),u.__e=t.__e,u.__k=t.__k,u.__k.forEach(function(n){n&&(n.__=u);}),S=0;S<p._sb.length;S++)p.__h.push(p._sb[S]);p._sb=[],p.__h.length&&f.push(p);break n}null!=p.componentWillUpdate&&p.componentWillUpdate(k,p.__s,C),null!=p.componentDidUpdate&&p.__h.push(function(){p.componentDidUpdate(d,_,m);});}if(p.context=C,p.props=k,p.__P=n,p.__e=!1,$=l$1.__r,H=0,"prototype"in A&&A.prototype.render){for(p.state=p.__s,p.__d=!1,$&&$(u),a=p.render(p.props,p.state,p.context),I=0;I<p._sb.length;I++)p.__h.push(p._sb[I]);p._sb=[];}else do{p.__d=!1,$&&$(u),a=p.render(p.props,p.state,p.context),p.state=p.__s;}while(p.__d&&++H<25);p.state=p.__s,null!=p.getChildContext&&(i=v$1(v$1({},i),p.getChildContext())),y||null==p.getSnapshotBeforeUpdate||(m=p.getSnapshotBeforeUpdate(d,_)),P$1(n,h$1(T=null!=a&&a.type===g$1&&null==a.key?a.props.children:a)?T:[T],u,t,i,o,r,f,e,c,s),p.base=u.__e,u.__u&=-161,p.__h.length&&f.push(p),w&&(p.__E=p.__=null);}catch(n){u.__v=null,c||null!=r?(u.__e=e,u.__u|=c?160:32,r[r.indexOf(e)]=null):(u.__e=t.__e,u.__k=t.__k),l$1.__e(n,u,t);}else null==r&&u.__v===t.__v?(u.__k=t.__k,u.__e=t.__e):u.__e=z$1(t.__e,u,t,i,o,r,f,c,s);(a=l$1.diffed)&&a(u);}function j$1(n,u,t){for(var i=0;i<t.length;i++)N(t[i],t[++i],t[++i]);l$1.__c&&l$1.__c(u,n),n.some(function(u){try{n=u.__h,u.__h=[],n.some(function(n){n.call(u);});}catch(n){l$1.__e(n,u.__v);}});}function z$1(l,u,t,i,o,r,f,e,s){var a,v,y,d,_,g,b,w=t.props,k=u.props,x=u.type;if("svg"===x&&(o=!0),null!=r)for(a=0;a<r.length;a++)if((_=r[a])&&"setAttribute"in _==!!x&&(x?_.localName===x:3===_.nodeType)){l=_,r[a]=null;break}if(null==l){if(null===x)return document.createTextNode(k);l=o?document.createElementNS("http://www.w3.org/2000/svg",x):document.createElement(x,k.is&&k),r=null,e=!1;}if(null===x)w===k||e&&l.data===k||(l.data=k);else {if(r=r&&n.call(l.childNodes),w=t.props||c$1,!e&&null!=r)for(w={},a=0;a<l.attributes.length;a++)w[(_=l.attributes[a]).name]=_.value;for(a in w)_=w[a],"children"==a||("dangerouslySetInnerHTML"==a?y=_:"key"===a||a in k||A$1(l,a,null,_,o));for(a in k)_=k[a],"children"==a?d=_:"dangerouslySetInnerHTML"==a?v=_:"value"==a?g=_:"checked"==a?b=_:"key"===a||e&&"function"!=typeof _||w[a]===_||A$1(l,a,_,w[a],o);if(v)e||y&&(v.__html===y.__html||v.__html===l.innerHTML)||(l.innerHTML=v.__html),u.__k=[];else if(y&&(l.innerHTML=""),P$1(l,h$1(d)?d:[d],u,t,i,o&&"foreignObject"!==x,r,f,r?r[0]:t.__k&&m$1(t,0),e,s),null!=r)for(a=r.length;a--;)null!=r[a]&&p$1(r[a]);e||(a="value",void 0!==g&&(g!==l[a]||"progress"===x&&!g||"option"===x&&g!==w[a])&&A$1(l,a,g,w[a],!1),a="checked",void 0!==b&&b!==l[a]&&A$1(l,a,b,w[a],!1));}return l}function N(n,u,t){try{"function"==typeof n?n(u):n.current=u;}catch(n){l$1.__e(n,t);}}function O(n,u,t){var i,o;if(l$1.unmount&&l$1.unmount(n),(i=n.ref)&&(i.current&&i.current!==n.__e||N(i,null,u)),null!=(i=n.__c)){if(i.componentWillUnmount)try{i.componentWillUnmount();}catch(n){l$1.__e(n,u);}i.base=i.__P=null,n.__c=void 0;}if(i=n.__k)for(o=0;o<i.length;o++)i[o]&&O(i[o],u,t||"function"!=typeof n.type);t||null==n.__e||p$1(n.__e),n.__=n.__e=n.__d=void 0;}function q$1(n,l,u){return this.constructor(n,u)}function B$1(u,t,i){var o,r,f,e;l$1.__&&l$1.__(u,t),r=(o="function"==typeof i)?null:i&&i.__k||t.__k,f=[],e=[],M(t,u=(!o&&i||t).__k=y$1(g$1,null,[u]),r||c$1,c$1,void 0!==t.ownerSVGElement,!o&&i?[i]:r?null:t.firstChild?n.call(t.childNodes):null,f,!o&&i?i:r?r.__e:t.firstChild,o,e),u.__d=void 0,j$1(f,u,e);}n=s$1.slice,l$1={__e:function(n,l,u,t){for(var i,o,r;l=l.__;)if((i=l.__c)&&!i.__)try{if((o=i.constructor)&&null!=o.getDerivedStateFromError&&(i.setState(o.getDerivedStateFromError(n)),r=i.__d),null!=i.componentDidCatch&&(i.componentDidCatch(n,t||{}),r=i.__d),r)return i.__E=i}catch(l){n=l;}throw n}},u$1=0,b$1.prototype.setState=function(n,l){var u;u=null!=this.__s&&this.__s!==this.state?this.__s:this.__s=v$1({},this.state),"function"==typeof n&&(n=n(v$1({},u),this.props)),n&&v$1(u,n),null!=n&&this.__v&&(l&&this._sb.push(l),x$1(this));},b$1.prototype.forceUpdate=function(n){this.__v&&(this.__e=!0,n&&this.__h.push(n),x$1(this));},b$1.prototype.render=g$1,i$1=[],r$1="function"==typeof Promise?Promise.prototype.then.bind(Promise.resolve()):setTimeout,f$1=function(n,l){return n.__v.__b-l.__v.__b},C$1.__r=0;

var t,r,u,i,o=0,f=[],c=[],e=l$1,a=e.__b,v=e.__r,l=e.diffed,m=e.__c,s=e.unmount,d=e.__;function h(n,t){e.__h&&e.__h(r,n,o||t),o=0;var u=r.__H||(r.__H={__:[],__h:[]});return n>=u.__.length&&u.__.push({__V:c}),u.__[n]}function p(n){return o=1,y(D,n)}function y(n,u,i){var o=h(t++,2);if(o.t=n,!o.__c&&(o.__=[i?i(u):D(void 0,u),function(n){var t=o.__N?o.__N[0]:o.__[0],r=o.t(t,n);t!==r&&(o.__N=[r,o.__[1]],o.__c.setState({}));}],o.__c=r,!r.u)){var f=function(n,t,r){if(!o.__c.__H)return !0;var u=o.__c.__H.__.filter(function(n){return !!n.__c});if(u.every(function(n){return !n.__N}))return !c||c.call(this,n,t,r);var i=!1;return u.forEach(function(n){if(n.__N){var t=n.__[0];n.__=n.__N,n.__N=void 0,t!==n.__[0]&&(i=!0);}}),!(!i&&o.__c.props===n)&&(!c||c.call(this,n,t,r))};r.u=!0;var c=r.shouldComponentUpdate,e=r.componentWillUpdate;r.componentWillUpdate=function(n,t,r){if(this.__e){var u=c;c=void 0,f(n,t,r),c=u;}e&&e.call(this,n,t,r);},r.shouldComponentUpdate=f;}return o.__N||o.__}function _(n,u){var i=h(t++,3);!e.__s&&C(i.__H,u)&&(i.__=n,i.i=u,r.__H.__h.push(i));}function A(n,u){var i=h(t++,4);!e.__s&&C(i.__H,u)&&(i.__=n,i.i=u,r.__h.push(i));}function F(n){return o=5,q(function(){return {current:n}},[])}function T(n,t,r){o=6,A(function(){return "function"==typeof n?(n(t()),function(){return n(null)}):n?(n.current=t(),function(){return n.current=null}):void 0},null==r?r:r.concat(n));}function q(n,r){var u=h(t++,7);return C(u.__H,r)?(u.__V=n(),u.i=r,u.__h=n,u.__V):u.__}function x(n,t){return o=8,q(function(){return n},t)}function P(n){var u=r.context[n.__c],i=h(t++,9);return i.c=n,u?(null==i.__&&(i.__=!0,u.sub(r)),u.props.value):n.__}function V(n,t){e.useDebugValue&&e.useDebugValue(t?t(n):n);}function b(n){var u=h(t++,10),i=p();return u.__=n,r.componentDidCatch||(r.componentDidCatch=function(n,t){u.__&&u.__(n,t),i[1](n);}),[i[0],function(){i[1](void 0);}]}function g(){var n=h(t++,11);if(!n.__){for(var u=r.__v;null!==u&&!u.__m&&null!==u.__;)u=u.__;var i=u.__m||(u.__m=[0,0]);n.__="P"+i[0]+"-"+i[1]++;}return n.__}function j(){for(var n;n=f.shift();)if(n.__P&&n.__H)try{n.__H.__h.forEach(z),n.__H.__h.forEach(B),n.__H.__h=[];}catch(t){n.__H.__h=[],e.__e(t,n.__v);}}e.__b=function(n){r=null,a&&a(n);},e.__=function(n,t){t.__k&&t.__k.__m&&(n.__m=t.__k.__m),d&&d(n,t);},e.__r=function(n){v&&v(n),t=0;var i=(r=n.__c).__H;i&&(u===r?(i.__h=[],r.__h=[],i.__.forEach(function(n){n.__N&&(n.__=n.__N),n.__V=c,n.__N=n.i=void 0;})):(i.__h.forEach(z),i.__h.forEach(B),i.__h=[],t=0)),u=r;},e.diffed=function(n){l&&l(n);var t=n.__c;t&&t.__H&&(t.__H.__h.length&&(1!==f.push(t)&&i===e.requestAnimationFrame||((i=e.requestAnimationFrame)||w)(j)),t.__H.__.forEach(function(n){n.i&&(n.__H=n.i),n.__V!==c&&(n.__=n.__V),n.i=void 0,n.__V=c;})),u=r=null;},e.__c=function(n,t){t.some(function(n){try{n.__h.forEach(z),n.__h=n.__h.filter(function(n){return !n.__||B(n)});}catch(r){t.some(function(n){n.__h&&(n.__h=[]);}),t=[],e.__e(r,n.__v);}}),m&&m(n,t);},e.unmount=function(n){s&&s(n);var t,r=n.__c;r&&r.__H&&(r.__H.__.forEach(function(n){try{z(n);}catch(n){t=n;}}),r.__H=void 0,t&&e.__e(t,r.__v));};var k="function"==typeof requestAnimationFrame;function w(n){var t,r=function(){clearTimeout(u),k&&cancelAnimationFrame(t),setTimeout(n);},u=setTimeout(r,100);k&&(t=requestAnimationFrame(r));}function z(n){var t=r,u=n.__c;"function"==typeof u&&(n.__c=void 0,u()),r=t;}function B(n){var t=r;n.__c=n.__(),r=t;}function C(n,t){return !n||n.length!==t.length||t.some(function(t,r){return t!==n[r]})}function D(n,t){return "function"==typeof t?t(n):t}

const hooks = {
  __proto__: null,
  useCallback: x,
  useContext: P,
  useDebugValue: V,
  useEffect: _,
  useErrorBoundary: b,
  useId: g,
  useImperativeHandle: T,
  useLayoutEffect: A,
  useMemo: q,
  useReducer: y,
  useRef: F,
  useState: p
};

const XMLNS$1 = 'http://www.w3.org/2000/svg';

/**
 * Sentry Logo
 */
function SentryLogo() {
  const createElementNS = (tagName) =>
    DOCUMENT.createElementNS(XMLNS$1, tagName);
  const svg = setAttributesNS(createElementNS('svg'), {
    width: '32',
    height: '30',
    viewBox: '0 0 72 66',
    fill: 'inherit',
  });

  const path = setAttributesNS(createElementNS('path'), {
    transform: 'translate(11, 11)',
    d: 'M29,2.26a4.67,4.67,0,0,0-8,0L14.42,13.53A32.21,32.21,0,0,1,32.17,40.19H27.55A27.68,27.68,0,0,0,12.09,17.47L6,28a15.92,15.92,0,0,1,9.23,12.17H4.62A.76.76,0,0,1,4,39.06l2.94-5a10.74,10.74,0,0,0-3.36-1.9l-2.91,5a4.54,4.54,0,0,0,1.69,6.24A4.66,4.66,0,0,0,4.62,44H19.15a19.4,19.4,0,0,0-8-17.31l2.31-4A23.87,23.87,0,0,1,23.76,44H36.07a35.88,35.88,0,0,0-16.41-31.8l4.67-8a.77.77,0,0,1,1.05-.27c.53.29,20.29,34.77,20.66,35.17a.76.76,0,0,1-.68,1.13H40.6q.09,1.91,0,3.81h4.78A4.59,4.59,0,0,0,50,39.43a4.49,4.49,0,0,0-.62-2.28Z',
  });
  svg.appendChild(path);

  return svg;
}

const _jsxFileName$5 = "/home/runner/work/sentry-javascript/sentry-javascript/packages/feedback/src/modal/components/DialogHeader.tsx";

function DialogHeader({ options }) {
  const logoHtml = q(() => ({ __html: SentryLogo().outerHTML }), []);

  return (
    y$1('h2', { class: "dialog__header", __self: this, __source: {fileName: _jsxFileName$5, lineNumber: 16}}
      , options.formTitle
      , options.showBranding ? (
        y$1('a', {
          class: "brand-link",
          target: "_blank",
          href: "https://sentry.io/welcome/",
          title: "Powered by Sentry"  ,
          rel: "noopener noreferrer" ,
          dangerouslySetInnerHTML: logoHtml, __self: this, __source: {fileName: _jsxFileName$5, lineNumber: 19}}
        )
      ) : null
    )
  );
}

/**
 * Validate that a given feedback submission has the required fields
 */
function getMissingFields(feedback, props) {
  const emptyFields = [];
  if (props.isNameRequired && !feedback.name) {
    emptyFields.push(props.nameLabel);
  }
  if (props.isEmailRequired && !feedback.email) {
    emptyFields.push(props.emailLabel);
  }
  if (!feedback.message) {
    emptyFields.push(props.messageLabel);
  }

  return emptyFields;
}

const _jsxFileName$4 = "/home/runner/work/sentry-javascript/sentry-javascript/packages/feedback/src/modal/components/Form.tsx";

function retrieveStringValue(formData, key) {
  const value = formData.get(key);
  if (typeof value === 'string') {
    return value.trim();
  }
  return '';
}

function Form({
  options,
  defaultEmail,
  defaultName,

  onFormClose,
  onSubmit,
  onSubmitSuccess,
  onSubmitError,
  showEmail,
  showName,
  screenshotInput,
}) {
  const {
    tags,
    addScreenshotButtonLabel,
    removeScreenshotButtonLabel,
    cancelButtonLabel,
    emailLabel,
    emailPlaceholder,
    isEmailRequired,
    isNameRequired,
    messageLabel,
    messagePlaceholder,
    nameLabel,
    namePlaceholder,
    submitButtonLabel,
    isRequiredLabel,
  } = options;
  // TODO: set a ref on the form, and whenever an input changes call proceessForm() and setError()
  const [error, setError] = p(null);

  const [showScreenshotInput, setShowScreenshotInput] = p(false);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const ScreenshotInputComponent = screenshotInput && screenshotInput.input;

  const [screenshotError, setScreenshotError] = p(null);
  const onScreenshotError = x((error) => {
    setScreenshotError(error);
    setShowScreenshotInput(false);
  }, []);

  const hasAllRequiredFields = x(
    (data) => {
      const missingFields = getMissingFields(data, {
        emailLabel,
        isEmailRequired,
        isNameRequired,
        messageLabel,
        nameLabel,
      });

      if (missingFields.length > 0) {
        setError(`Please enter in the following required fields: ${missingFields.join(', ')}`);
      } else {
        setError(null);
      }

      return missingFields.length === 0;
    },
    [emailLabel, isEmailRequired, isNameRequired, messageLabel, nameLabel],
  );

  const handleSubmit = x(
    async (e) => {
      try {
        e.preventDefault();
        if (!(e.target instanceof HTMLFormElement)) {
          return;
        }
        const formData = new FormData(e.target);
        const attachment = await (screenshotInput && showScreenshotInput ? screenshotInput.value() : undefined);

        const data = {
          name: retrieveStringValue(formData, 'name'),
          email: retrieveStringValue(formData, 'email'),
          message: retrieveStringValue(formData, 'message'),
          attachments: attachment ? [attachment] : undefined,
        };

        if (!hasAllRequiredFields(data)) {
          return;
        }

        try {
          await onSubmit(
            {
              name: data.name,
              email: data.email,
              message: data.message,
              source: FEEDBACK_WIDGET_SOURCE,
              tags,
            },
            { attachments: data.attachments },
          );
          onSubmitSuccess(data);
        } catch (error) {
          DEBUG_BUILD && utils.logger.error(error);
          setError(error );
          onSubmitError(error );
        }
      } catch (e2) {
        // pass
      }
    },
    [screenshotInput && showScreenshotInput, onSubmitSuccess, onSubmitError],
  );

  return (
    y$1('form', { class: "form", onSubmit: handleSubmit, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 144}}
      , ScreenshotInputComponent && showScreenshotInput ? (
        y$1(ScreenshotInputComponent, { onError: onScreenshotError, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 146}} )
      ) : null

      , y$1('div', { class: "form__right", 'data-sentry-feedback': true, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 149}}
        , y$1('div', { class: "form__top", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 150}}
          , error ? y$1('div', { class: "form__error-container", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 151}}, error) : null

          , showName ? (
            y$1('label', { for: "name", class: "form__label", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 154}}
              , y$1(LabelText, { label: nameLabel, isRequiredLabel: isRequiredLabel, isRequired: isNameRequired, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 155}} )
              , y$1('input', {
                class: "form__input",
                defaultValue: defaultName,
                id: "name",
                name: "name",
                placeholder: namePlaceholder,
                required: isNameRequired,
                type: "text", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 156}}
              )
            )
          ) : (
            y$1('input', { 'aria-hidden': true, value: defaultName, name: "name", type: "hidden", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 167}} )
          )

          , showEmail ? (
            y$1('label', { for: "email", class: "form__label", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 171}}
              , y$1(LabelText, { label: emailLabel, isRequiredLabel: isRequiredLabel, isRequired: isEmailRequired, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 172}} )
              , y$1('input', {
                class: "form__input",
                defaultValue: defaultEmail,
                id: "email",
                name: "email",
                placeholder: emailPlaceholder,
                required: isEmailRequired,
                type: "email", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 173}}
)
            )
          ) : (
            y$1('input', { 'aria-hidden': true, value: defaultEmail, name: "email", type: "hidden", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 184}} )
          )

          , y$1('label', { for: "message", class: "form__label", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 187}}
            , y$1(LabelText, { label: messageLabel, isRequiredLabel: isRequiredLabel, isRequired: true, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 188}} )
            , y$1('textarea', {
              autoFocus: true,
              class: "form__input form__input--textarea" ,
              id: "message",
              name: "message",
              placeholder: messagePlaceholder,
              required: true,
              rows: 5, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 189}}
            )
          )

          , ScreenshotInputComponent ? (
            y$1('label', { for: "screenshot", class: "form__label", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 201}}
              , y$1('button', {
                class: "btn btn--default" ,
                type: "button",
                onClick: () => {
                  setScreenshotError(null);
                  setShowScreenshotInput(prev => !prev);
                }, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 202}}

                , showScreenshotInput ? removeScreenshotButtonLabel : addScreenshotButtonLabel
              )
              , screenshotError ? y$1('div', { class: "form__error-container", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 212}}, screenshotError.message) : null
            )
          ) : null
        )
        , y$1('div', { class: "btn-group", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 216}}
          , y$1('button', { class: "btn btn--primary" , type: "submit", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 217}}
            , submitButtonLabel
          )
          , y$1('button', { class: "btn btn--default" , type: "button", onClick: onFormClose, __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 220}}
            , cancelButtonLabel
          )
        )
      )
    )
  );
}

function LabelText({
  label,
  isRequired,
  isRequiredLabel,
}

) {
  return (
    y$1('span', { class: "form__label__text", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 239}}
      , label
      , isRequired && y$1('span', { class: "form__label__text--required", __self: this, __source: {fileName: _jsxFileName$4, lineNumber: 241}}, isRequiredLabel)
    )
  );
}

const WIDTH = 16;
const HEIGHT = 17;
const XMLNS = 'http://www.w3.org/2000/svg';

/**
 * Success Icon (checkmark)
 */
function SuccessIcon() {
  const createElementNS = (tagName) =>
    WINDOW.document.createElementNS(XMLNS, tagName);
  const svg = setAttributesNS(createElementNS('svg'), {
    width: `${WIDTH}`,
    height: `${HEIGHT}`,
    viewBox: `0 0 ${WIDTH} ${HEIGHT}`,
    fill: 'inherit',
  });

  const g = setAttributesNS(createElementNS('g'), {
    clipPath: 'url(#clip0_57_156)',
  });

  const path2 = setAttributesNS(createElementNS('path'), {
    ['fill-rule']: 'evenodd',
    ['clip-rule']: 'evenodd',
    d: 'M3.55544 15.1518C4.87103 16.0308 6.41775 16.5 8 16.5C10.1217 16.5 12.1566 15.6571 13.6569 14.1569C15.1571 12.6566 16 10.6217 16 8.5C16 6.91775 15.5308 5.37103 14.6518 4.05544C13.7727 2.73985 12.5233 1.71447 11.0615 1.10897C9.59966 0.503466 7.99113 0.34504 6.43928 0.653721C4.88743 0.962403 3.46197 1.72433 2.34315 2.84315C1.22433 3.96197 0.462403 5.38743 0.153721 6.93928C-0.15496 8.49113 0.00346625 10.0997 0.608967 11.5615C1.21447 13.0233 2.23985 14.2727 3.55544 15.1518ZM4.40546 3.1204C5.46945 2.40946 6.72036 2.03 8 2.03C9.71595 2.03 11.3616 2.71166 12.575 3.92502C13.7883 5.13838 14.47 6.78405 14.47 8.5C14.47 9.77965 14.0905 11.0306 13.3796 12.0945C12.6687 13.1585 11.6582 13.9878 10.476 14.4775C9.29373 14.9672 7.99283 15.0953 6.73777 14.8457C5.48271 14.596 4.32987 13.9798 3.42502 13.075C2.52018 12.1701 1.90397 11.0173 1.65432 9.76224C1.40468 8.50718 1.5328 7.20628 2.0225 6.02404C2.5122 4.8418 3.34148 3.83133 4.40546 3.1204Z',
  });
  const path = setAttributesNS(createElementNS('path'), {
    d: 'M6.68775 12.4297C6.78586 12.4745 6.89218 12.4984 7 12.5C7.11275 12.4955 7.22315 12.4664 7.32337 12.4145C7.4236 12.3627 7.51121 12.2894 7.58 12.2L12 5.63999C12.0848 5.47724 12.1071 5.28902 12.0625 5.11098C12.0178 4.93294 11.9095 4.77744 11.7579 4.67392C11.6064 4.57041 11.4221 4.52608 11.24 4.54931C11.0579 4.57254 10.8907 4.66173 10.77 4.79999L6.88 10.57L5.13 8.56999C5.06508 8.49566 4.98613 8.43488 4.89768 8.39111C4.80922 8.34735 4.713 8.32148 4.61453 8.31498C4.51605 8.30847 4.41727 8.32147 4.32382 8.35322C4.23038 8.38497 4.14413 8.43484 4.07 8.49999C3.92511 8.63217 3.83692 8.81523 3.82387 9.01092C3.81083 9.2066 3.87393 9.39976 4 9.54999L6.43 12.24C6.50187 12.3204 6.58964 12.385 6.68775 12.4297Z',
  });

  svg.appendChild(g).append(path, path2);

  const speakerDefs = createElementNS('defs');
  const speakerClipPathDef = setAttributesNS(createElementNS('clipPath'), {
    id: 'clip0_57_156',
  });

  const speakerRect = setAttributesNS(createElementNS('rect'), {
    width: `${WIDTH}`,
    height: `${WIDTH}`,
    fill: 'white',
    transform: 'translate(0 0.5)',
  });

  speakerClipPathDef.appendChild(speakerRect);
  speakerDefs.appendChild(speakerClipPathDef);

  svg.appendChild(speakerDefs).appendChild(speakerClipPathDef).appendChild(speakerRect);

  return svg;
}

const _jsxFileName$3 = "/home/runner/work/sentry-javascript/sentry-javascript/packages/feedback/src/modal/components/Dialog.tsx";

function Dialog({ open, onFormSubmitted, ...props }) {
  const options = props.options;
  const successIconHtml = q(() => ({ __html: SuccessIcon().outerHTML }), []);

  const [timeoutId, setTimeoutId] = p(null);

  const handleOnSuccessClick = x(() => {
    if (timeoutId) {
      clearTimeout(timeoutId);
      setTimeoutId(null);
    }
    onFormSubmitted();
  }, [timeoutId]);

  const onSubmitSuccess = x(
    (data) => {
      props.onSubmitSuccess(data);
      setTimeoutId(
        setTimeout(() => {
          onFormSubmitted();
          setTimeoutId(null);
        }, SUCCESS_MESSAGE_TIMEOUT),
      );
    },
    [onFormSubmitted],
  );

  return (
    y$1(g$1, {__self: this, __source: {fileName: _jsxFileName$3, lineNumber: 48}}
      , timeoutId ? (
        y$1('div', { class: "success__position", onClick: handleOnSuccessClick, __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 50}}
          , y$1('div', { class: "success__content", __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 51}}
            , options.successMessageText
            , y$1('span', { class: "success__icon", dangerouslySetInnerHTML: successIconHtml, __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 53}} )
          )
        )
      ) : (
        y$1('dialog', { class: "dialog", onClick: options.onFormClose, open: open, __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 57}}
          , y$1('div', { class: "dialog__position", __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 58}}
            , y$1('div', {
              class: "dialog__content",
              onClick: e => {
                // Stop event propagation so clicks on content modal do not propagate to dialog (which will close dialog)
                e.stopPropagation();
              }, __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 59}}

              , y$1(DialogHeader, { options: options, __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 66}} )
              , y$1(Form, { ...props, onSubmitSuccess: onSubmitSuccess, __self: this, __source: {fileName: _jsxFileName$3, lineNumber: 67}} )
            )
          )
        )
      )
    )
  );
}

const DIALOG = `
.dialog {
  position: fixed;
  z-index: var(--z-index);
  margin: 0;
  inset: 0;

  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  height: 100vh;
  width: 100vw;

  color: var(--dialog-color, var(--foreground));
  fill: var(--dialog-color, var(--foreground));
  line-height: 1.75em;

  background-color: rgba(0, 0, 0, 0.05);
  border: none;
  inset: 0;
  opacity: 1;
  transition: opacity 0.2s ease-in-out;
}

.dialog__position {
  position: fixed;
  z-index: var(--z-index);
  inset: var(--dialog-inset);
  padding: var(--page-margin);
  display: flex;
  max-height: calc(100vh - (2 * var(--page-margin)));
}
@media (max-width: 600px) {
  .dialog__position {
    inset: var(--page-margin);
    padding: 0;
  }
}

.dialog__position:has(.editor) {
  inset: var(--page-margin);
  padding: 0;
}

.dialog:not([open]) {
  opacity: 0;
  pointer-events: none;
  visibility: hidden;
}
.dialog:not([open]) .dialog__content {
  transform: translate(0, -16px) scale(0.98);
}

.dialog__content {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: var(--dialog-padding, 24px);
  max-width: 100%;
  width: 100%;
  max-height: 100%;
  overflow: auto;

  background: var(--dialog-background, var(--background));
  border-radius: var(--dialog-border-radius, 20px);
  border: var(--dialog-border, var(--border));
  box-shadow: var(--dialog-box-shadow, var(--box-shadow));
  transform: translate(0, 0) scale(1);
  transition: transform 0.2s ease-in-out;
}
`;

const DIALOG_HEADER = `
.dialog__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: var(--dialog-header-weight, 600);
  margin: 0;
}

.brand-link {
  display: inline-flex;
}
.brand-link:focus-visible {
  outline: var(--outline);
}
`;

const FORM = `
.form {
  display: flex;
  overflow: auto;
  flex-direction: row;
  gap: 16px;
  flex: 1 0;
}

.form__right {
  flex: 0 0 auto;
  width: var(--form-width, 272px);
  display: flex;
  overflow: auto;
  flex-direction: column;
  justify-content: space-between;
  gap: 20px;
}

@media (max-width: 600px) {
  .form__right {
    width: var(--form-width, 100%);
  }
}

.form__top {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form__error-container {
  color: var(--error-color);
  fill: var(--error-color);
}

.form__label {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin: 0px;
}

.form__label__text {
  display: flex;
  gap: 4px;
  align-items: center;
}

.form__label__text--required {
  font-size: 0.85em;
}

.form__input {
  font-family: inherit;
  line-height: inherit;
  background: transparent;
  box-sizing: border-box;
  border: var(--input-border, var(--border));
  border-radius: var(--input-border-radius, 6px);
  color: var(--input-color, inherit);
  fill: var(--input-color, inherit);
  font-size: var(--input-font-size, inherit);
  font-weight: var(--input-font-weight, 500);
  padding: 6px 12px;
}

.form__input::placeholder {
  opacity: 0.65;
  color: var(--input-placeholder-color, inherit);
  filter: var(--interactive-filter);
}

.form__input:focus-visible {
  outline: var(--input-focus-outline, var(--outline));
}

.form__input--textarea {
  font-family: inherit;
  resize: vertical;
}

.error {
  color: var(--error-color);
  fill: var(--error-color);
}
`;

const BUTTON = `
.btn-group {
  display: grid;
  gap: 8px;
}

.btn {
  line-height: inherit;
  border: var(--button-border, var(--border));
  border-radius: var(--button-border-radius, 6px);
  cursor: pointer;
  font-family: inherit;
  font-size: var(--button-font-size, inherit);
  font-weight: var(--button-font-weight, 600);
  padding: var(--button-padding, 6px 16px);
}
.btn[disabled] {
  opacity: 0.6;
  pointer-events: none;
}

.btn--primary {
  color: var(--button-primary-color, var(--accent-foreground));
  fill: var(--button-primary-color, var(--accent-foreground));
  background: var(--button-primary-background, var(--accent-background));
  border: var(--button-primary-border, var(--border));
  border-radius: var(--button-primary-border-radius, 6px);
  font-weight: var(--button-primary-font-weight, 500);
}
.btn--primary:hover {
  color: var(--button-primary-hover-color, var(--accent-foreground));
  fill: var(--button-primary-hover-color, var(--accent-foreground));
  background: var(--button-primary-hover-background, var(--accent-background));
  filter: var(--interactive-filter);
}
.btn--primary:focus-visible {
  background: var(--button-primary-hover-background, var(--accent-background));
  filter: var(--interactive-filter);
  outline: var(--button-primary-focus-outline, var(--outline));
}

.btn--default {
  color: var(--button-color, var(--foreground));
  fill: var(--button-color, var(--foreground));
  background: var(--button-background, var(--background));
  border: var(--button-border, var(--border));
  border-radius: var(--button-border-radius, 6px);
  font-weight: var(--button-font-weight, 500);
}
.btn--default:hover {
  color: var(--button-color, var(--foreground));
  fill: var(--button-color, var(--foreground));
  background: var(--button-hover-background, var(--background));
  filter: var(--interactive-filter);
}
.btn--default:focus-visible {
  background: var(--button-hover-background, var(--background));
  filter: var(--interactive-filter);
  outline: var(--button-focus-outline, var(--outline));
}
`;

const SUCCESS = `
.success__position {
  position: fixed;
  inset: var(--dialog-inset);
  padding: var(--page-margin);
  z-index: var(--z-index);
}
.success__content {
  background: var(--success-background, var(--background));
  border: var(--success-border, var(--border));
  border-radius: var(--success-border-radius, 1.7em/50%);
  box-shadow: var(--success-box-shadow, var(--box-shadow));
  font-weight: var(--success-font-weight, 600);
  color: var(--success-color);
  fill: var(--success-color);
  padding: 12px 24px;
  line-height: 1.75em;

  display: grid;
  align-items: center;
  grid-auto-flow: column;
  gap: 6px;
  cursor: default;
}

.success__icon {
  display: flex;
}
`;

/**
 * Creates <style> element for widget dialog
 */
function createDialogStyles(styleNonce) {
  const style = DOCUMENT.createElement('style');

  style.textContent = `
:host {
  --dialog-inset: var(--inset);
}

${DIALOG}
${DIALOG_HEADER}
${FORM}
${BUTTON}
${SUCCESS}
`;

  if (styleNonce) {
    style.setAttribute('nonce', styleNonce);
  }

  return style;
}

const _jsxFileName$2 = "/home/runner/work/sentry-javascript/sentry-javascript/packages/feedback/src/modal/integration.tsx";
function getUser() {
  const currentUser = core.getCurrentScope().getUser();
  const isolationUser = core.getIsolationScope().getUser();
  const globalUser = core.getGlobalScope().getUser();
  if (currentUser && Object.keys(currentUser).length) {
    return currentUser;
  }
  if (isolationUser && Object.keys(isolationUser).length) {
    return isolationUser;
  }
  return globalUser;
}

const feedbackModalIntegration = (() => {
  return {
    name: 'FeedbackModal',
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    setupOnce() {},
    createDialog: ({ options, screenshotIntegration, sendFeedback, shadow }) => {
      const shadowRoot = shadow ;
      const userKey = options.useSentryUser;
      const user = getUser();

      const el = DOCUMENT.createElement('div');
      const style = createDialogStyles(options.styleNonce);

      let originalOverflow = '';
      const dialog = {
        get el() {
          return el;
        },
        appendToDom() {
          if (!shadowRoot.contains(style) && !shadowRoot.contains(el)) {
            shadowRoot.appendChild(style);
            shadowRoot.appendChild(el);
          }
        },
        removeFromDom() {
          shadowRoot.removeChild(el);
          shadowRoot.removeChild(style);
          DOCUMENT.body.style.overflow = originalOverflow;
        },
        open() {
          renderContent(true);
          options.onFormOpen && options.onFormOpen();
          originalOverflow = DOCUMENT.body.style.overflow;
          DOCUMENT.body.style.overflow = 'hidden';
        },
        close() {
          renderContent(false);
          DOCUMENT.body.style.overflow = originalOverflow;
        },
      };

      const screenshotInput = screenshotIntegration && screenshotIntegration.createInput({ h: y$1, hooks, dialog, options });

      const renderContent = (open) => {
        B$1(
          y$1(Dialog, {
            options: options,
            screenshotInput: screenshotInput,
            showName: options.showName || options.isNameRequired,
            showEmail: options.showEmail || options.isEmailRequired,
            defaultName: (userKey && user && user[userKey.name]) || '',
            defaultEmail: (userKey && user && user[userKey.email]) || '',
            onFormClose: () => {
              renderContent(false);
              options.onFormClose && options.onFormClose();
            },
            onSubmit: sendFeedback,
            onSubmitSuccess: (data) => {
              renderContent(false);
              options.onSubmitSuccess && options.onSubmitSuccess(data);
            },
            onSubmitError: (error) => {
              options.onSubmitError && options.onSubmitError(error);
            },
            onFormSubmitted: () => {
              options.onFormSubmitted && options.onFormSubmitted();
            },
            open: open, __self: undefined, __source: {fileName: _jsxFileName$2, lineNumber: 67}}
          ),
          el,
        );
      };

      return dialog;
    },
  };
}) ;

const _jsxFileName$1 = "/home/runner/work/sentry-javascript/sentry-javascript/packages/feedback/src/screenshot/components/CropCorner.tsx";

function CropCornerFactory({
  h, // eslint-disable-line @typescript-eslint/no-unused-vars
}) {
  return function CropCorner({
    top,
    left,
    corner,
    onGrabButton,
  }

) {
    return (
      h('button', {
        class: `editor__crop-corner editor__crop-corner--${corner} `,
        style: {
          top: top,
          left: left,
        },
        onMouseDown: e => {
          e.preventDefault();
          onGrabButton(e, corner);
        },
        onClick: e => {
          e.preventDefault();
        }, __self: this, __source: {fileName: _jsxFileName$1, lineNumber: 22}}
)
    );
  };
}

/**
 * Creates <style> element for widget dialog
 */
function createScreenshotInputStyles(styleNonce) {
  const style = DOCUMENT.createElement('style');

  const surface200 = '#1A141F';
  const gray100 = '#302735';

  style.textContent = `
.editor {
  padding: 10px;
  padding-top: 65px;
  padding-bottom: 65px;
  flex-grow: 1;

  background-color: ${surface200};
  background-image: repeating-linear-gradient(
      -145deg,
      transparent,
      transparent 8px,
      ${surface200} 8px,
      ${surface200} 11px
    ),
    repeating-linear-gradient(
      -45deg,
      transparent,
      transparent 15px,
      ${gray100} 15px,
      ${gray100} 16px
    );
}

.editor__canvas-container {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.editor__canvas-container canvas {
  object-fit: contain;
  position: relative;
}

.editor__crop-btn-group {
  padding: 8px;
  gap: 8px;
  border-radius: var(--menu-border-radius, 6px);
  background: var(--button-primary-background, var(--background));
  width: 175px;
  position: absolute;
}

.editor__crop-corner {
  width: 30px;
  height: 30px;
  position: absolute;
  background: none;
  border: 3px solid #ffffff;
}

.editor__crop-corner--top-left {
  cursor: nwse-resize;
  border-right: none;
  border-bottom: none;
}
.editor__crop-corner--top-right {
  cursor: nesw-resize;
  border-left: none;
  border-bottom: none;
}
.editor__crop-corner--bottom-left {
  cursor: nesw-resize;
  border-right: none;
  border-top: none;
}
.editor__crop-corner--bottom-right {
  cursor: nwse-resize;
  border-left: none;
  border-top: none;
}
`;

  if (styleNonce) {
    style.setAttribute('nonce', styleNonce);
  }

  return style;
}

function useTakeScreenshotFactory({ hooks }) {
  return function useTakeScreenshot({ onBeforeScreenshot, onScreenshot, onAfterScreenshot, onError }) {
    hooks.useEffect(() => {
      const takeScreenshot = async () => {
        onBeforeScreenshot();
        const stream = await NAVIGATOR.mediaDevices.getDisplayMedia({
          video: {
            width: WINDOW.innerWidth * WINDOW.devicePixelRatio,
            height: WINDOW.innerHeight * WINDOW.devicePixelRatio,
          },
          audio: false,
          // @ts-expect-error experimental flags: https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getDisplayMedia#prefercurrenttab
          monitorTypeSurfaces: 'exclude',
          preferCurrentTab: true,
          selfBrowserSurface: 'include',
          surfaceSwitching: 'exclude',
        });

        const video = DOCUMENT.createElement('video');
        await new Promise((resolve, reject) => {
          video.srcObject = stream;
          video.onloadedmetadata = () => {
            onScreenshot(video);
            stream.getTracks().forEach(track => track.stop());
            resolve();
          };
          video.play().catch(reject);
        });
        onAfterScreenshot();
      };

      takeScreenshot().catch(onError);
    }, []);
  };
}

const _jsxFileName = "/home/runner/work/sentry-javascript/sentry-javascript/packages/feedback/src/screenshot/components/ScreenshotEditor.tsx";

const CROP_BUTTON_SIZE = 30;
const CROP_BUTTON_BORDER = 3;
const CROP_BUTTON_OFFSET = CROP_BUTTON_SIZE + CROP_BUTTON_BORDER;
const DPI = WINDOW.devicePixelRatio;

const constructRect = (box) => {
  return {
    x: Math.min(box.startX, box.endX),
    y: Math.min(box.startY, box.endY),
    width: Math.abs(box.startX - box.endX),
    height: Math.abs(box.startY - box.endY),
  };
};

const getContainedSize = (img) => {
  const imgClientHeight = img.clientHeight;
  const imgClientWidth = img.clientWidth;
  const ratio = img.width / img.height;
  let width = imgClientHeight * ratio;
  let height = imgClientHeight;
  if (width > imgClientWidth) {
    width = imgClientWidth;
    height = imgClientWidth / ratio;
  }
  const x = (imgClientWidth - width) / 2;
  const y = (imgClientHeight - height) / 2;
  return { startX: x, startY: y, endX: width + x, endY: height + y };
};

function ScreenshotEditorFactory({
  h,
  hooks,
  imageBuffer,
  dialog,
  options,
}) {
  const useTakeScreenshot = useTakeScreenshotFactory({ hooks });

  return function ScreenshotEditor({ onError }) {
    const styles = hooks.useMemo(() => ({ __html: createScreenshotInputStyles(options.styleNonce).innerText }), []);
    const CropCorner = CropCornerFactory({ h });

    const canvasContainerRef = hooks.useRef(null);
    const cropContainerRef = hooks.useRef(null);
    const croppingRef = hooks.useRef(null);
    const [croppingRect, setCroppingRect] = hooks.useState({ startX: 0, startY: 0, endX: 0, endY: 0 });
    const [confirmCrop, setConfirmCrop] = hooks.useState(false);
    const [isResizing, setIsResizing] = hooks.useState(false);

    hooks.useEffect(() => {
      WINDOW.addEventListener('resize', resizeCropper, false);
    }, []);

    function resizeCropper() {
      const cropper = croppingRef.current;
      const imageDimensions = constructRect(getContainedSize(imageBuffer));
      if (cropper) {
        cropper.width = imageDimensions.width * DPI;
        cropper.height = imageDimensions.height * DPI;
        cropper.style.width = `${imageDimensions.width}px`;
        cropper.style.height = `${imageDimensions.height}px`;
        const ctx = cropper.getContext('2d');
        if (ctx) {
          ctx.scale(DPI, DPI);
        }
      }

      const cropButton = cropContainerRef.current;
      if (cropButton) {
        cropButton.style.width = `${imageDimensions.width}px`;
        cropButton.style.height = `${imageDimensions.height}px`;
      }

      setCroppingRect({ startX: 0, startY: 0, endX: imageDimensions.width, endY: imageDimensions.height });
    }

    hooks.useEffect(() => {
      const cropper = croppingRef.current;
      if (!cropper) {
        return;
      }

      const ctx = cropper.getContext('2d');
      if (!ctx) {
        return;
      }

      const imageDimensions = constructRect(getContainedSize(imageBuffer));
      const croppingBox = constructRect(croppingRect);
      ctx.clearRect(0, 0, imageDimensions.width, imageDimensions.height);

      // draw gray overlay around the selection
      ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
      ctx.fillRect(0, 0, imageDimensions.width, imageDimensions.height);
      ctx.clearRect(croppingBox.x, croppingBox.y, croppingBox.width, croppingBox.height);

      // draw selection border
      ctx.strokeStyle = '#ffffff';
      ctx.lineWidth = 3;
      ctx.strokeRect(croppingBox.x + 1, croppingBox.y + 1, croppingBox.width - 2, croppingBox.height - 2);
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 1;
      ctx.strokeRect(croppingBox.x + 3, croppingBox.y + 3, croppingBox.width - 6, croppingBox.height - 6);
    }, [croppingRect]);

    function onGrabButton(e, corner) {
      setConfirmCrop(false);
      setIsResizing(true);
      const handleMouseMove = makeHandleMouseMove(corner);
      const handleMouseUp = () => {
        DOCUMENT.removeEventListener('mousemove', handleMouseMove);
        DOCUMENT.removeEventListener('mouseup', handleMouseUp);
        setConfirmCrop(true);
        setIsResizing(false);
      };

      DOCUMENT.addEventListener('mouseup', handleMouseUp);
      DOCUMENT.addEventListener('mousemove', handleMouseMove);
    }

    const makeHandleMouseMove = hooks.useCallback((corner) => {
      return function (e) {
        if (!croppingRef.current) {
          return;
        }
        const cropCanvas = croppingRef.current;
        const cropBoundingRect = cropCanvas.getBoundingClientRect();
        const mouseX = e.clientX - cropBoundingRect.x;
        const mouseY = e.clientY - cropBoundingRect.y;
        switch (corner) {
          case 'top-left':
            setCroppingRect(prev => ({
              ...prev,
              startX: Math.min(Math.max(0, mouseX), prev.endX - CROP_BUTTON_OFFSET),
              startY: Math.min(Math.max(0, mouseY), prev.endY - CROP_BUTTON_OFFSET),
            }));
            break;
          case 'top-right':
            setCroppingRect(prev => ({
              ...prev,
              endX: Math.max(Math.min(mouseX, cropCanvas.width / DPI), prev.startX + CROP_BUTTON_OFFSET),
              startY: Math.min(Math.max(0, mouseY), prev.endY - CROP_BUTTON_OFFSET),
            }));
            break;
          case 'bottom-left':
            setCroppingRect(prev => ({
              ...prev,
              startX: Math.min(Math.max(0, mouseX), prev.endX - CROP_BUTTON_OFFSET),
              endY: Math.max(Math.min(mouseY, cropCanvas.height / DPI), prev.startY + CROP_BUTTON_OFFSET),
            }));
            break;
          case 'bottom-right':
            setCroppingRect(prev => ({
              ...prev,
              endX: Math.max(Math.min(mouseX, cropCanvas.width / DPI), prev.startX + CROP_BUTTON_OFFSET),
              endY: Math.max(Math.min(mouseY, cropCanvas.height / DPI), prev.startY + CROP_BUTTON_OFFSET),
            }));
            break;
        }
      };
    }, []);

    // DRAGGING FUNCTIONALITY.
    const initialPositionRef = hooks.useRef({ initialX: 0, initialY: 0 });

    function onDragStart(e) {
      if (isResizing) return;

      initialPositionRef.current = { initialX: e.clientX, initialY: e.clientY };

      const handleMouseMove = (moveEvent) => {
        const cropCanvas = croppingRef.current;
        if (!cropCanvas) return;

        const deltaX = moveEvent.clientX - initialPositionRef.current.initialX;
        const deltaY = moveEvent.clientY - initialPositionRef.current.initialY;

        setCroppingRect(prev => {
          // Math.max stops it from going outside of the borders
          const newStartX = Math.max(
            0,
            Math.min(prev.startX + deltaX, cropCanvas.width / DPI - (prev.endX - prev.startX)),
          );
          const newStartY = Math.max(
            0,
            Math.min(prev.startY + deltaY, cropCanvas.height / DPI - (prev.endY - prev.startY)),
          );
          // Don't want to change size, just position
          const newEndX = newStartX + (prev.endX - prev.startX);
          const newEndY = newStartY + (prev.endY - prev.startY);

          initialPositionRef.current.initialX = moveEvent.clientX;
          initialPositionRef.current.initialY = moveEvent.clientY;

          return {
            startX: newStartX,
            startY: newStartY,
            endX: newEndX,
            endY: newEndY,
          };
        });
      };

      const handleMouseUp = () => {
        DOCUMENT.removeEventListener('mousemove', handleMouseMove);
        DOCUMENT.removeEventListener('mouseup', handleMouseUp);
      };

      DOCUMENT.addEventListener('mousemove', handleMouseMove);
      DOCUMENT.addEventListener('mouseup', handleMouseUp);
    }

    function submit() {
      const cutoutCanvas = DOCUMENT.createElement('canvas');
      const imageBox = constructRect(getContainedSize(imageBuffer));
      const croppingBox = constructRect(croppingRect);
      cutoutCanvas.width = croppingBox.width * DPI;
      cutoutCanvas.height = croppingBox.height * DPI;

      const cutoutCtx = cutoutCanvas.getContext('2d');
      if (cutoutCtx && imageBuffer) {
        cutoutCtx.drawImage(
          imageBuffer,
          (croppingBox.x / imageBox.width) * imageBuffer.width,
          (croppingBox.y / imageBox.height) * imageBuffer.height,
          (croppingBox.width / imageBox.width) * imageBuffer.width,
          (croppingBox.height / imageBox.height) * imageBuffer.height,
          0,
          0,
          cutoutCanvas.width,
          cutoutCanvas.height,
        );
      }

      const ctx = imageBuffer.getContext('2d');
      if (ctx) {
        ctx.clearRect(0, 0, imageBuffer.width, imageBuffer.height);
        imageBuffer.width = cutoutCanvas.width;
        imageBuffer.height = cutoutCanvas.height;
        imageBuffer.style.width = `${croppingBox.width}px`;
        imageBuffer.style.height = `${croppingBox.height}px`;
        ctx.drawImage(cutoutCanvas, 0, 0);
        resizeCropper();
      }
    }

    useTakeScreenshot({
      onBeforeScreenshot: hooks.useCallback(() => {
        (dialog.el ).style.display = 'none';
      }, []),
      onScreenshot: hooks.useCallback(
        (imageSource) => {
          const context = imageBuffer.getContext('2d');
          if (!context) {
            throw new Error('Could not get canvas context');
          }
          imageBuffer.width = imageSource.videoWidth;
          imageBuffer.height = imageSource.videoHeight;
          imageBuffer.style.width = '100%';
          imageBuffer.style.height = '100%';
          context.drawImage(imageSource, 0, 0);
        },
        [imageBuffer],
      ),
      onAfterScreenshot: hooks.useCallback(() => {
        (dialog.el ).style.display = 'block';
        const container = canvasContainerRef.current;
        container && container.appendChild(imageBuffer);
        resizeCropper();
      }, []),
      onError: hooks.useCallback(error => {
        (dialog.el ).style.display = 'block';
        onError(error);
      }, []),
    });

    return (
      h('div', { class: "editor", __self: this, __source: {fileName: _jsxFileName, lineNumber: 315}}
        , h('style', { nonce: options.styleNonce, dangerouslySetInnerHTML: styles, __self: this, __source: {fileName: _jsxFileName, lineNumber: 316}} )
        , h('div', { class: "editor__canvas-container", ref: canvasContainerRef, __self: this, __source: {fileName: _jsxFileName, lineNumber: 317}}
          , h('div', { class: "editor__crop-container", style: { position: 'absolute', zIndex: 1 }, ref: cropContainerRef, __self: this, __source: {fileName: _jsxFileName, lineNumber: 318}}
            , h('canvas', {
              onMouseDown: onDragStart,
              style: { position: 'absolute', cursor: confirmCrop ? 'move' : 'auto' },
              ref: croppingRef, __self: this, __source: {fileName: _jsxFileName, lineNumber: 319}}
)
            , h(CropCorner, {
              left: croppingRect.startX - CROP_BUTTON_BORDER,
              top: croppingRect.startY - CROP_BUTTON_BORDER,
              onGrabButton: onGrabButton,
              corner: "top-left", __self: this, __source: {fileName: _jsxFileName, lineNumber: 324}}
)
            , h(CropCorner, {
              left: croppingRect.endX - CROP_BUTTON_SIZE + CROP_BUTTON_BORDER,
              top: croppingRect.startY - CROP_BUTTON_BORDER,
              onGrabButton: onGrabButton,
              corner: "top-right", __self: this, __source: {fileName: _jsxFileName, lineNumber: 330}}
)
            , h(CropCorner, {
              left: croppingRect.startX - CROP_BUTTON_BORDER,
              top: croppingRect.endY - CROP_BUTTON_SIZE + CROP_BUTTON_BORDER,
              onGrabButton: onGrabButton,
              corner: "bottom-left", __self: this, __source: {fileName: _jsxFileName, lineNumber: 336}}
)
            , h(CropCorner, {
              left: croppingRect.endX - CROP_BUTTON_SIZE + CROP_BUTTON_BORDER,
              top: croppingRect.endY - CROP_BUTTON_SIZE + CROP_BUTTON_BORDER,
              onGrabButton: onGrabButton,
              corner: "bottom-right", __self: this, __source: {fileName: _jsxFileName, lineNumber: 342}}
)
            , h('div', {
              style: {
                left: Math.max(0, croppingRect.endX - 191),
                top: Math.max(0, croppingRect.endY + 8),
                display: confirmCrop ? 'flex' : 'none',
              },
              class: "editor__crop-btn-group", __self: this, __source: {fileName: _jsxFileName, lineNumber: 348}}

              , h('button', {
                onClick: e => {
                  e.preventDefault();
                  if (croppingRef.current) {
                    setCroppingRect({
                      startX: 0,
                      startY: 0,
                      endX: croppingRef.current.width / DPI,
                      endY: croppingRef.current.height / DPI,
                    });
                  }
                  setConfirmCrop(false);
                },
                class: "btn btn--default" , __self: this, __source: {fileName: _jsxFileName, lineNumber: 356}}

                , options.cancelButtonLabel
              )
              , h('button', {
                onClick: e => {
                  e.preventDefault();
                  submit();
                  setConfirmCrop(false);
                },
                class: "btn btn--primary" , __self: this, __source: {fileName: _jsxFileName, lineNumber: 373}}

                , options.confirmButtonLabel
              )
            )
          )
        )
      )
    );
  };
}

const feedbackScreenshotIntegration = (() => {
  return {
    name: 'FeedbackScreenshot',
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    setupOnce() {},
    createInput: ({ h, hooks, dialog, options }) => {
      const imageBuffer = DOCUMENT.createElement('canvas');

      return {
        input: ScreenshotEditorFactory({
          h: h ,
          hooks: hooks ,
          imageBuffer,
          dialog,
          options,
        }) , // eslint-disable-line @typescript-eslint/no-explicit-any

        value: async () => {
          const blob = await new Promise(resolve => {
            imageBuffer.toBlob(resolve, 'image/png');
          });
          if (blob) {
            const data = new Uint8Array(await blob.arrayBuffer());
            const attachment = {
              data,
              filename: 'screenshot.png',
              contentType: 'application/png',
              // attachmentType?: string;
            };
            return attachment;
          }
          return undefined;
        },
      };
    },
  };
}) ;

exports.buildFeedbackIntegration = buildFeedbackIntegration;
exports.feedbackModalIntegration = feedbackModalIntegration;
exports.feedbackScreenshotIntegration = feedbackScreenshotIntegration;
exports.getFeedback = getFeedback;
exports.sendFeedback = sendFeedback;
//# sourceMappingURL=index.js.map
