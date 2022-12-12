// Type definitions for axe-core
// Project: https://github.com/dequelabs/axe-core
// Definitions by: Marcy Sutton <https://github.com/marcysutton>

declare namespace axe {
  type ImpactValue = 'minor' | 'moderate' | 'serious' | 'critical' | null;

  type TagValue = string;

  type ReporterVersion = 'v1' | 'v2' | 'raw' | 'raw-env' | 'no-passes';

  type RunOnlyType = 'rule' | 'rules' | 'tag' | 'tags';

  type resultGroups = 'inapplicable' | 'passes' | 'incomplete' | 'violations';

  type AriaAttrsType =
    | 'boolean'
    | 'nmtoken'
    | 'mntokens'
    | 'idref'
    | 'idrefs'
    | 'string'
    | 'decimal'
    | 'int';

  type AriaRolesType = 'abstract' | 'widget' | 'structure' | 'landmark';

  type DpubRolesType =
    | 'section'
    | 'landmark'
    | 'link'
    | 'listitem'
    | 'img'
    | 'navigation'
    | 'note'
    | 'separator'
    | 'none'
    | 'sectionhead';

  type HtmlContentTypes =
    | 'flow'
    | 'sectioning'
    | 'heading'
    | 'phrasing'
    | 'embedded'
    | 'interactive';

  type ContextObject = {
    include?: string[] | string[][];
    exclude?: string[] | string[][];
  };

  type RunCallback = (error: Error, results: AxeResults) => void;

  type ElementContext = Node | string | ContextObject;

  interface TestEngine {
    name: string;
    version: string;
  }
  interface TestRunner {
    name: string;
  }
  interface TestEnvironment {
    userAgent: string;
    windowWidth: number;
    windowHeight: number;
    orientationAngle?: number;
    orientationType?: string;
  }
  interface RunOnly {
    type: RunOnlyType;
    values: TagValue[] | string[];
  }
  interface RuleObject {
    [key: string]: {
      enabled: boolean;
    };
  }
  interface RunOptions {
    runOnly?: RunOnly | TagValue[] | string[];
    rules?: RuleObject;
    reporter?: ReporterVersion;
    resultTypes?: resultGroups[];
    selectors?: boolean;
    ancestry?: boolean;
    xpath?: boolean;
    absolutePaths?: boolean;
    iframes?: boolean;
    elementRef?: boolean;
    frameWaitTime?: number;
    preload?: boolean;
    performanceTimer?: boolean;
  }
  interface AxeResults {
    toolOptions: RunOptions;
    testEngine: TestEngine;
    testRunner: TestRunner;
    testEnvironment: TestEnvironment;
    url: string;
    timestamp: string;
    passes: Result[];
    violations: Result[];
    incomplete: Result[];
    inapplicable: Result[];
  }
  interface Result {
    description: string;
    help: string;
    helpUrl: string;
    id: string;
    impact?: ImpactValue;
    tags: TagValue[];
    nodes: NodeResult[];
  }
  interface NodeResult {
    html: string;
    impact?: ImpactValue;
    target: string[];
    xpath?: string[];
    ancestry?: string[];
    any: CheckResult[];
    all: CheckResult[];
    none: CheckResult[];
    failureSummary?: string;
    element?: HTMLElement;
  }
  interface CheckResult {
    id: string;
    impact: string;
    message: string;
    data: any;
    relatedNodes?: RelatedNode[];
  }
  interface RelatedNode {
    target: string[];
    html: string;
  }
  interface RuleLocale {
    [key: string]: {
      description: string;
      help: string;
    };
  }
  interface CheckLocale {
    [key: string]: {
      pass: string | { [key: string]: string };
      fail: string | { [key: string]: string };
      incomplete: string | { [key: string]: string };
    };
  }
  interface Locale {
    lang?: string;
    rules?: RuleLocale;
    checks?: CheckLocale;
  }
  interface AriaAttrs {
    type: AriaAttrsType;
    values?: string[];
    allowEmpty?: boolean;
    global?: boolean;
    unsupported?: boolean;
  }
  interface AriaRoles {
    type: AriaRolesType | DpubRolesType;
    requiredContext?: string[];
    requiredOwned?: string[];
    requiredAttrs?: string[];
    allowedAttrs?: string[];
    nameFromContent?: boolean;
    unsupported?: boolean;
  }
  interface HtmlElmsVariant {
    contentTypes?: HtmlContentTypes[];
    allowedRoles: boolean | string[];
    noAriaAttrs?: boolean;
    shadowRoot?: boolean;
    implicitAttrs?: { [key: string]: string };
    namingMethods?: string[];
  }
  interface HtmlElms extends HtmlElmsVariant {
    variant?: { [key: string]: HtmlElmsVariant };
  }
  interface Standards {
    ariaAttrs?: { [key: string]: AriaAttrs };
    ariaRoles?: { [key: string]: AriaRoles };
    htmlElms?: { [key: string]: HtmlElms };
    cssColors?: { [key: string]: number[] };
  }
  interface Spec {
    branding?: {
      brand?: string;
      application?: string;
    };
    reporter?: ReporterVersion;
    checks?: Check[];
    rules?: Rule[];
    standards?: Standards;
    locale?: Locale;
    disableOtherRules?: boolean;
    axeVersion?: string;
    noHtml?: boolean;
    allowedOrigins?: string[];
    // Deprecated - do not use.
    ver?: string;
  }
  interface Check {
    id: string;
    evaluate: Function | string;
    after?: Function | string;
    options?: any;
    matches?: string;
    enabled?: boolean;
  }
  interface Rule {
    id: string;
    selector?: string;
    impact?: ImpactValue;
    excludeHidden?: boolean;
    enabled?: boolean;
    pageLevel?: boolean;
    any?: string[];
    all?: string[];
    none?: string[];
    tags?: string[];
    matches?: string;
  }
  interface AxePlugin {
    id: string;
    run(...args: any[]): any;
    commands: {
      id: string;
      callback(...args: any[]): void;
    }[];
    cleanup?(callback: Function): void;
  }
  interface RuleMetadata {
    ruleId: string;
    description: string;
    help: string;
    helpUrl: string;
    tags: string[];
  }

  let version: string;
  let plugins: any;

  /**
   * Source string to use as an injected script in Selenium
   */
  let source: string;

  /**
   * Object for axe Results
   */
  var AxeResults: AxeResults;

  /**
   * Runs a number of rules against the provided HTML page and returns the resulting issue list
   *
   * @param   {ElementContext} context  Optional The `Context` specification object @see Context
   * @param   {RunOptions}     options  Optional Options passed into rules or checks, temporarily modifying them.
   * @param   {RunCallback}    callback Optional The function to invoke when analysis is complete.
   * @returns {Promise<AxeResults>|void} If the callback was not defined, axe will return a Promise.
   */
  function run(context?: ElementContext): Promise<AxeResults>;
  function run(options: RunOptions): Promise<AxeResults>;
  function run(callback: (error: Error, results: AxeResults) => void): void;
  function run(context: ElementContext, callback: RunCallback): void;
  function run(options: RunOptions, callback: RunCallback): void;
  function run(
    context: ElementContext,
    options: RunOptions
  ): Promise<AxeResults>;
  function run(
    context: ElementContext,
    options: RunOptions,
    callback: RunCallback
  ): void;

  /**
   * Method for configuring the data format used by axe. Helpful for adding new
   * rules, which must be registered with the library to execute.
   * @param  {Spec}       Spec Object with valid `branding`, `reporter`, `checks` and `rules` data
   */
  function configure(spec: Spec): void;

  /**
   * Searches and returns rules that contain a tag in the list of tags.
   * @param  {Array}  tags  Optional array of tags
   * @return {Array}  Array of rules
   */
  function getRules(tags?: string[]): RuleMetadata[];

  /**
   * Restores the default axe configuration
   */
  function reset(): void;

  /**
   * Function to register a plugin configuration in document and its subframes
   * @param  {Object}    plugin    A plugin configuration object
   */
  function registerPlugin(plugin: AxePlugin): void;

  /**
   * Function to clean up plugin configuration in document and its subframes
   */
  function cleanup(): void;

  /**
   * Set up alternative frame communication
   */
  function frameMessenger(frameMessenger: FrameMessenger): void;

  // axe.frameMessenger
  type FrameMessenger = {
    open: (topicHandler: TopicHandler) => Close | void;
    post: (
      frameWindow: Window,
      data: TopicData | ReplyData,
      replyHandler: ReplyHandler
    ) => void;
  };
  type Close = Function;
  type TopicHandler = (data: TopicData, responder?: Responder) => void;
  type ReplyHandler = (data: ReplyData, responder?: Responder) => void;
  type Responder = (
    message: any,
    keepalive: boolean,
    replyHandler: ReplyHandler
  ) => void;
  type TopicData = { topic: String } & ReplyData;
  type ReplyData = { channelId: String; message: any; keepAlive: Boolean };
}

export = axe;
