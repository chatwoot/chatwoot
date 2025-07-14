import {
	limit,
	trimAfterFirstMatch,
	startsWith,
	endsWith
} from './util.js'

describe('findNumbers/util', () =>
{
	it('should generate regexp limit', () =>
	{
		let thrower = () => limit(1, 0)
		thrower.should.throw()

		thrower = () => limit(-1, 1)
		thrower.should.throw()

		thrower = () => limit(0, 0)
		thrower.should.throw()
	})

	it('should trimAfterFirstMatch', () =>
	{
		trimAfterFirstMatch(/\d/, 'abc123').should.equal('abc')
		trimAfterFirstMatch(/\d/, 'abc').should.equal('abc')
	})

	it('should determine if a string starts with a substring', () =>
	{
		startsWith('𐍈123', '𐍈').should.equal(true)
		startsWith('1𐍈', '𐍈').should.equal(false)
	})

	it('should determine if a string ends with a substring', () =>
	{
		endsWith('123𐍈', '𐍈').should.equal(true)
		endsWith('𐍈1', '𐍈').should.equal(false)
	})
})