import applyInternationalSeparatorStyle from './applyInternationalSeparatorStyle.js'

describe('applyInternationalSeparatorStyle', () => {
	it('should change Google\'s international format style', () => {
		applyInternationalSeparatorStyle('(xxx) xxx-xx-xx').should.equal('xxx xxx xx xx')
		applyInternationalSeparatorStyle('(xxx)xxx').should.equal('xxx xxx')
	})
})