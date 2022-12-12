/* eslint-env jest */
/**
 * @fileoverview Ensure autocomplete attribute is correct.
 * @author Wilco Fiers
 */

// -----------------------------------------------------------------------------
// Requirements
// -----------------------------------------------------------------------------

import { RuleTester } from 'eslint';
import parserOptionsMapper from '../../__util__/parserOptionsMapper';
import { axeFailMessage } from '../../__util__/axeMapping';
import rule from '../../../src/rules/autocomplete-valid';

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

const ruleTester = new RuleTester();

const invalidAutocomplete = [{
  message: axeFailMessage('autocomplete-valid'),
  type: 'JSXOpeningElement',
}];

const inappropriateAutocomplete = [{
  message: axeFailMessage('autocomplete-appropriate'),
  type: 'JSXOpeningElement',
}];

ruleTester.run('autocomplete-valid', rule, {
  valid: [
    // INAPPLICABLE
    { code: '<input type="text" />;' },
    // // PASSED AUTOCOMPLETE
    { code: '<input type="text" autocomplete="name" />;' },
    { code: '<input type="text" autocomplete="" />;' },
    { code: '<input type="text" autocomplete="off" />;' },
    { code: '<input type="text" autocomplete="on" />;' },
    { code: '<input type="text" autocomplete="billing family-name" />;' },
    { code: '<input type="text" autocomplete="section-blue shipping street-address" />;' },
    { code: '<input type="text" autocomplete="section-somewhere shipping work email" />;' },
    { code: '<input type="text" autocomplete />;' },
    { code: '<input type="text" autocomplete={autocompl} />;' },
    { code: '<input type="text" autocomplete={autocompl || "name"} />;' },
    { code: '<input type="text" autocomplete={autocompl || "foo"} />;' },
    { code: '<Foo autocomplete="bar"></Foo>;' },
  ].map(parserOptionsMapper),
  invalid: [
    // FAILED "autocomplete-valid"
    { code: '<input type="text" autocomplete="foo" />;', errors: invalidAutocomplete },
    { code: '<input type="text" autocomplete="name invalid" />;', errors: invalidAutocomplete },
    { code: '<input type="text" autocomplete="invalid name" />;', errors: invalidAutocomplete },
    { code: '<input type="text" autocomplete="home url" />;', errors: invalidAutocomplete },
    { code: '<Bar autocomplete="baz"></Bar>;', errors: invalidAutocomplete, options: [{ inputComponents: ['Bar'] }] },
    { code: '<input type={isEmail ? "email" : "text"} autocomplete="none" />;', errors: invalidAutocomplete },

    // FAILED "autocomplete-appropriate"
    { code: '<input type="date" autocomplete="email" />;', errors: inappropriateAutocomplete },
    { code: '<input type="number" autocomplete="url" />;', errors: inappropriateAutocomplete },
    { code: '<input type="month" autocomplete="tel" />;', errors: inappropriateAutocomplete },
    { code: '<Foo type="month" autocomplete="tel"></Foo>;', errors: inappropriateAutocomplete, options: [{ inputComponents: ['Foo'] }] },
  ].map(parserOptionsMapper),
});
