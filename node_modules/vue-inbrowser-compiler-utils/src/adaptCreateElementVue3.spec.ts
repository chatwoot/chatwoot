import { SpyInstance } from 'vitest'
import adaptCreateElement, { CreateElementFunction } from './adaptCreateElement'

vi.mock('vue-inbrowser-compiler-demi', () => {
	return {
		resolveComponent: (comp: string) => comp,
		isVue3: true
	}
})

describe('adaptCreateElement', () => {
	let h: SpyInstance<Parameters<CreateElementFunction>, ReturnType<CreateElementFunction>>
	let pragma: CreateElementFunction
	beforeEach(() => {
		h = vi.fn()
		pragma = adaptCreateElement(h as any)
	})

	describe('group attributes', () => {
		it('deals with naked v-model properly', () => {
			pragma('Component', { vModel: 'hello' })
			expect(h).toHaveBeenCalledWith('Component', expect.objectContaining({ modelValue: 'hello' }))
		})

		it('deals with custom v-model properly', () => {
			pragma('Component', { 'vModel:custom': 'bonjour' })
			expect(h).toHaveBeenCalledWith('Component', expect.objectContaining({ custom: 'bonjour' }))
		})
	})
})
