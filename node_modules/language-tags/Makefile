test: lib test/lib node_modules
	TEST_LIB_PATH="../../lib" ./node_modules/.bin/_mocha \
		--timeout 3000 \
		--reporter spec \
		--check-leaks \
		--ui tdd \
		--recursive

test-coverage: lib test/lib node_modules
	TEST_LIB_PATH="../../lib" ./node_modules/.bin/istanbul \
		cover ./node_modules/.bin/_mocha \
			-- \
			--timeout 3000 \
			--reporter spec \
			--check-leaks \
			--ui tdd \
			--recursive

view-coverage: test-coverage
	open coverage/lcov-report/index.html

test-coveralls: test-coverage
	cat coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js

node_modules: package.json
	npm install
	touch $@

clean:
	rm -rf coverage

.PHONY: test test-coverage test-coveralls view-coverage clean
