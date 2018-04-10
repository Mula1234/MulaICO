## Hot to run tests

You need to install a couple of packages:

#### npm install --save ganache-cli

#### npm install

Then you can run the actual tests. In one command prompt, run

#### ganache-cli -l 20000000 -e 500 testrpc

And then open another prompt and run

#### truffle compile

#### truffle migrate --reset

#### truffle test

