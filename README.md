EchoService [![Build Status](https://secure.travis-ci.org/mkremer/echo_service.png)](http://travis-ci.org/mkremer/echo_service)
==============
Example of a basic SOAP service written in Ruby (1.9), the code contains explanatory comments.

The EchoService works with Ruby 1.9.2 and 1.9.3. It will not work with JRuby because of [Nokogiri issue #494](https://github.com/tenderlove/nokogiri/issues/494)

If you have any issues, suggestions, improvements, etc. then please log them using GitHub issues.

Usage
-----
To run the EchoService run "rackup" or "ruby echo_service.rb" (on Windows rackup does not work)

The default endpoint URL in the WSDL is http://localhost:9292/echo_service.wsdl, you can set the environmental variable BASE_URL to replace http://localhost:9292 with whatever is appropriate for you (per example http://echo.without-brains.net)

License
-------
EchoService is released under the MIT license.

Author
------
[Mark Kremer](https://github.com/mkremer)

