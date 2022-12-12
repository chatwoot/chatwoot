import { SpyInstance } from 'vitest'
import adaptCreateElement, { CreateElementFunction } from './adaptCreateElement'

describe('adaptCreateElement', () => {
	let h: SpyInstance<Parameters<CreateElementFunction>, ReturnType<CreateElementFunction>>
	let pragma: CreateElementFunction
	beforeEach(() => {
		h = vi.fn()
		pragma = adaptCreateElement(h as any)
	})

	describe('group attributes', () => {
		it('should merge all non special attributes in attrs', () => {
			pragma('Component', { hello: 'hello' })
			expect(h).toHaveBeenCalledWith('Component', { attrs: { hello: 'hello' } })
		})

		it('should set all on attributes in an on object', () => {
			const handler = vi.fn()
			pragma('Component', { onClick: handler })
			expect(h).toHaveBeenCalledWith('Component', { on: { click: handler } })
		})

		it('should set all nativeOn attributes in a nativeOn object', () => {
			const handler = vi.fn()
			pragma('Component', { nativeOnClick: handler })
			expect(h).toHaveBeenCalledWith('Component', { nativeOn: { click: handler } })
		})

		it('should transform kebab-case into camel-case', () => {
			const handler = vi.fn()
			pragma('Component', { 'native-on-click': handler, 'hello-world': 'foo' })
			expect(h).toHaveBeenCalledWith('Component', {
				nativeOn: { click: handler },
				attrs: { helloWorld: 'foo' }
			})
		})
	})
})
