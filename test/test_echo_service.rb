require_relative 'test_helper'

class TestEchoService < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    EchoService
  end

  def test_echo_service
    post "/echo_service", %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
   <soapenv:Body>
      <echo:EchoRequest>
         <echo:Message>Hello World!</echo:Message>
      </echo:EchoRequest>
   </soapenv:Body>
</soapenv:Envelope>}

  expected = %Q{<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
  <SOAP:Body>
    <echo:EchoResponse>
      <echo:Message>Hello World!</echo:Message>
    </echo:EchoResponse>
  </SOAP:Body>
</SOAP:Envelope>}

    assert_equal expected, last_response.body.strip
    assert_equal 200, last_response.status
  end

  def test_echo_service_gives_soap_error_on_invalid_message
    post "/echo_service", %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
   <soapenv:Body>
      <echo:EchoRequest>
      </echo:EchoRequest>
   </soapenv:Body>
</soapenv:Envelope>}

  expected = %Q{<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP:Body>
    <SOAP:Fault>
      <faultcode>SOAP:Client</faultcode>
      <faultstring>Element '{http://www.without-brains.net/echo}EchoRequest': Missing child element(s). Expected is ( {http://www.without-brains.net/echo}Message ).</faultstring>
    </SOAP:Fault>
  </SOAP:Body>
</SOAP:Envelope>}

    assert_equal expected.strip, last_response.body.strip
    assert_equal 500, last_response.status
  end
end
