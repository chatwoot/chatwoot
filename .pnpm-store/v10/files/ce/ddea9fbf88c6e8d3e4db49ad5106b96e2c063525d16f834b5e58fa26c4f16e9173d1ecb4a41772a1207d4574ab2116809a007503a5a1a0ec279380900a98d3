import { closeNonPairedParens, stripNonPairedParens, repeat } from './AsYouTypeFormatter.util.js'

describe('closeNonPairedParens', () => {
	it('should close non-paired braces', () => {
		closeNonPairedParens('(000) 123-45 (9  )', 15).should.equal('(000) 123-45 (9  )')
	})
})

describe('stripNonPairedParens', () => {
	it('should strip non-paired braces', () => {
		stripNonPairedParens('(000) 123-45 (9').should.equal('(000) 123-45 9')
		stripNonPairedParens('(000) 123-45 (9)').should.equal('(000) 123-45 (9)')
	})
})

describe('repeat', () => {
	it('should repeat string N times', () => {
		repeat('a', 0).should.equal('')
		repeat('a', 3).should.equal('aaa')
		repeat('a', 4).should.equal('aaaa')
	})
})