import parseComponent from './parseComponent'

describe('parseComponent', () => {
	it('should detect templates', () => {
		const comp = parseComponent(`
        <template>
            <template>
                <div>hello</div>
            </template>
            hello world
        </template>`)
		expect(comp.template).toMatchInlineSnapshot(`
		"

		            <template>
		                <div>hello</div>
		            </template>
		            hello world
		        "
	`)
	})

	it('should detect scripts', () => {
		const comp = parseComponent(`
        <script>
        export default {}
        </script>`)
		expect(comp.script).toMatchInlineSnapshot(`
		"

		        export default {}
		        "
	`)
	})

	it('should detect one style', () => {
		const comp = parseComponent(`
        <style>
        .class3{
            color: red;
        }
		</style>`)
		expect(comp.styles).not.toBeUndefined()
		expect(comp.styles).toMatchInlineSnapshot(`
			[
			  "

			        .class3{
			            color: red;
			        }
					",
			]
		`)
	})

	it('should detect styles', () => {
		const comp = parseComponent(`
<style>
.class2{
	color: blue;
}
@media screen and (width < 900px) {
	.class2{
		color: green;
	}
}
</style>
<style>
.class3{
	color: red;
}
</style>`)
		expect(comp.styles).not.toBeUndefined()
		expect(comp.styles).toMatchInlineSnapshot(`
			[
			  "

			.class2{
				color: blue;
			}
			@media screen and (width < 900px) {
				.class2{
					color: green;
				}
			}
			",
			  "











			.class2{
				color: blue;
			}
			@media screen and (width < 900px) {
				.class2{
					color: green;
				}
			}

			.class3{
				color: red;
			}
			",
			]
		`)
	})

	it('should not see internal templates', () => {
		const comp = parseComponent(`
    <div>
        <template lang="pug">
            <template>
                <div>hello</div>
            </template>
            sad
        </template>
	</div>`)
		expect(comp.template).toBeUndefined()
	})

	it('should allow for templates inside of script strings', () => {
		const comp = parseComponent(`
<template>
	<MyComponent/>
</template>

<script>
const MyComponent = \`
	<div>
		<template v-if="true">
		FOO
		</template>
	</div>
	\`

export default {};
</script>`)
		expect(comp.template).toMatch(/<MyComponent/)
		expect(comp.script).toMatchInlineSnapshot(`
		"





		const MyComponent = \`
			<div>
				<template v-if=\\"true\\">
				FOO
				</template>
			</div>
			\`

		export default {};
		"
	`)
	})
})
