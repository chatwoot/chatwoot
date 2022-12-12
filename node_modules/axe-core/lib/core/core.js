import constants from './constants';
import log from './log';

import AbstractVirtualNode from './base/virtual-node/abstract-virtual-node';
import SerialVirtualNode from './base/virtual-node/serial-virtual-node';
import VirtualNode from './base/virtual-node/virtual-node';
import cache from './base/cache';

import Audit from './base/audit';
import CheckResult from './base/check-result';
import Check from './base/check';
import Context from './base/context';
import metadataFunctionMap from './base/metadata-function-map';
import RuleResult from './base/rule-result';
import Rule from './base/rule';

import * as imports from './imports';

import cleanup from './public/cleanup';
import configure from './public/configure';
import frameMessenger from './public/frame-messenger';
import getRules from './public/get-rules';
import load from './public/load';
import registerPlugin from './public/plugins';
import { hasReporter, getReporter, addReporter } from './public/reporter';
import reset from './public/reset';
import runRules from './public/run-rules';
import runVirtualRule from './public/run-virtual-rule';
import run from './public/run';
import setup from './public/setup';
import teardown from './public/teardown';

import naReporter from './reporters/na';
import noPassesReporter from './reporters/no-passes';
import rawEnvReporter from './reporters/raw-env';
import rawReporter from './reporters/raw';
import v1Reporter from './reporters/v1';
import v2Reporter from './reporters/v2';

import * as commons from '../commons';
import * as utils from './utils';

axe.constants = constants;
axe.log = log;

axe.AbstractVirtualNode = AbstractVirtualNode;
axe.SerialVirtualNode = SerialVirtualNode;
axe.VirtualNode = VirtualNode;
axe._cache = cache;

// Setting up this private/temp namespace for the tests (which cannot yet `import/export` things).
// TODO: remove `_thisWillBeDeletedDoNotUse`
axe._thisWillBeDeletedDoNotUse = axe._thisWillBeDeletedDoNotUse || {};
axe._thisWillBeDeletedDoNotUse.base = {
  Audit,
  CheckResult,
  Check,
  Context,
  RuleResult,
  Rule,
  metadataFunctionMap
};

axe.imports = imports;

axe.cleanup = cleanup;
axe.configure = configure;
axe.frameMessenger = frameMessenger;
axe.getRules = getRules;
axe._load = load;
axe.plugins = {};
axe.registerPlugin = registerPlugin;
axe.hasReporter = hasReporter;
axe.getReporter = getReporter;
axe.addReporter = addReporter;
axe.reset = reset;
axe._runRules = runRules;
axe.runVirtualRule = runVirtualRule;
axe.run = run;
axe.setup = setup;
axe.teardown = teardown;

axe.commons = commons;
axe.utils = utils;

axe.addReporter('na', naReporter);
axe.addReporter('no-passes', noPassesReporter);
axe.addReporter('rawEnv', rawEnvReporter);
axe.addReporter('raw', rawReporter);
axe.addReporter('v1', v1Reporter);
axe.addReporter('v2', v2Reporter, true);
