
include node_modules/make-lint/index.mk
GREP ?=.

build: components index.js
	@component build --dev

components: component.json
	@component install --dev

test: lint
	@node_modules/.bin/mocha \
		--reporter spec \
		--grep "$(GREP)"

node_modules: package.json
	@npm install

clean:
	rm -fr build components template.js

test-browser: build
	@open test/index.html

.PHONY: clean test test-browser
