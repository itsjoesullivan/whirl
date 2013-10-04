coffee -cj test.js lib/index.coffee test/index.coffee
mocha test.js -r should
rm test.js
