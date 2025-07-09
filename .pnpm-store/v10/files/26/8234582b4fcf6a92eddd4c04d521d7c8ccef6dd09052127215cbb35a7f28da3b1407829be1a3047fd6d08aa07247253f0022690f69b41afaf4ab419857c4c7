import PatternParser from './AsYouTypeFormatter.PatternParser.js'

describe('PatternParser', function() {
	it('should parse single-character patterns', function() {
		new PatternParser().parse('2').should.deep.equal('2')
	})

	it('should parse string patterns', function() {
		new PatternParser().parse('123').should.deep.equal(['1', '2', '3'])
	})

	it('should parse "one of" patterns', function() {
		new PatternParser().parse('[5-9]').should.deep.equal({
			op: '[]',
			args: ['5', '6', '7', '8', '9']
		})
	})

	it('should parse "or" patterns', function() {
		new PatternParser().parse('123|[5-9]').should.deep.equal({
			op: '|',
			args: [
				['1', '2', '3'],
				{
					op: '[]',
					args: ['5', '6', '7', '8', '9']
				}
			]
		})

		new PatternParser().parse('123|[5-9]0').should.deep.equal({
			op: '|',
			args: [
				['1', '2', '3'],
				[
					{
						op: '[]',
						args: ['5', '6', '7', '8', '9']
					},
					'0'
				]
			]
		})
	})

	it('should parse nested "or" patterns', function() {
		new PatternParser().parse('123|(?:2|34)[5-9]').should.deep.equal({
			op: '|',
			args: [
				['1', '2', '3'],
				[
					{
						op: '|',
						args: [
							'2',
							['3', '4']
						]
					},
					{
						op: '[]',
						args: ['5', '6', '7', '8', '9']
					}
				]
			]
		})
	})
})