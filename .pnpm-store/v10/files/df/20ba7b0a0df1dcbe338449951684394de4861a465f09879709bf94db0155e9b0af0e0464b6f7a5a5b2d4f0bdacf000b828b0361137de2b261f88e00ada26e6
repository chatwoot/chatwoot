import searchNumbers from './searchNumbers.js'
import metadata from '../../metadata.min.json' assert { type: 'json' }

describe('searchNumbers', () => {
	it('should iterate', () => {
		const expectedNumbers =[{
			country : 'RU',
			phone   : '8005553535',
			// number   : '+7 (800) 555-35-35',
			startsAt : 14,
			endsAt   : 32
		}, {
			country : 'US',
			phone   : '2133734253',
			// number   : '(213) 373-4253',
			startsAt : 41,
			endsAt   : 55
		}]

		for (const number of searchNumbers('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', 'US', metadata)) {
			number.should.deep.equal(expectedNumbers.shift())
		}

		expectedNumbers.length.should.equal(0)
	})
})