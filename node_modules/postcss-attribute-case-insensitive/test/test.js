import postcss from 'postcss';
import { expect } from 'chai';

import plugin from '..';

const test = (input, output, opts, done) => {
	postcss([
		plugin(opts)
	])
		.process(input, { from: '<inline>' })
		.then(result => {
			expect(result.css).to.eql(output);
			expect(result.warnings()).to.be.empty; // eslint-disable-line no-unused-expressions

			done();
		})
		.catch(done);
};

describe('postcss-attribute-case-insensitive', () => {
	it('simple', done => {
		test(
			'[data-foo=test i] { display: block; }',
			'[data-foo=test],[data-foo=Test],[data-foo=tEst],[data-foo=TEst],[data-foo=teSt],[data-foo=TeSt],[data-foo=tESt],[data-foo=TESt],[data-foo=tesT],[data-foo=TesT],[data-foo=tEsT],[data-foo=TEsT],[data-foo=teST],[data-foo=TeST],[data-foo=tEST],[data-foo=TEST] { display: block; }',
			{},
			done
		);
	});

	it('with spaces', done => {
		test(
			'[foo="a b" i]{}',
			'[foo="a b"],[foo="A b"],[foo="a B"],[foo="A B"]{}',
			{},
			done
		);
	});

	it('not insensitive', done => {
		test(
			'[foo=a]{}',
			'[foo=a]{}',
			{},
			done
		);
	});

	it('several attributes', done => {
		test(
			'[foo=a i],[foobar=b],[bar=c i]{}',
			'[foobar=b],[foo=a],[foo=A],[bar=c],[bar=C]{}',
			{},
			done
		);
	});
});
