# Bitcoin Command Center

Bitcoin Command Center is a web-based application that has two main functions:

* A web based frontend to bitcoin-qt/bitcoind (view transactions, send coins, manage addresses, etc)
* A monitoring dashboard for a Bitcoin mining operation.

Bitcoin Command Center is not a turnkey application intended for end users.  If you would like to use it, you will almost certainly need to have an understanding of the technologies involved and you'll need to be comfortable reading and editing the source code to make things work for your specific setup.

The major technologies involved are:

* [Node.js](http://nodejs.org/) as the web server
* [AngularJS](http://angularjs.org/) as the frontend application framework
* [MongoDB](http://www.mongodb.org/) as the backend database
* [CoffeeScript](http://coffeescript.org/) instead of raw JavaScript
* [Compass](http://compass-style.org/) for CSS

These are all open source technologies that are relatively straightforward to get running on Linux and OS X (using [Homebrew](http://brew.sh/), etc).  It's also possible to get these running on Windows, but it will require a bit more effort.  The details of getting these technologies installed are left as an exercise for the reader :)

At a high level, getting this running requires the following steps:

1. Install Node, Mongo, and Compass
2. Run `npm install -g coffee-script` to install the coffeescript command line tool on your system
3. Run `npm install` from the root directory of this project to install all the require node modules
4. Configure the application by either editing the default.coffee file in the `config` folder, or by creating a [host-specific config file](http://lorenwest.github.io/node-config/latest/)
5. Make sure MongoDB is running
6. Run `coffee app.coffee` to start the web server.
7. Point your web browser at the server you just started.

Now, to be truely useful, you'll also need to configure your bitcoin miners to submit data to the web application ever time they find a share.  If you are using *cgminer*, you can look at my [share monitor](https://github.com/ervwalter/share-monitor/) node.js script as an example of how to do this.