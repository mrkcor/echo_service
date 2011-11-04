require_relative 'test_helper'

class TestEchoService < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    EchoService
  end

  def teardown
    ENV['BASE_URL'] = nil
  end

  def test_echo_service_echo
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

  def test_echo_service_reverse
    post "/echo_service", %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
   <soapenv:Body>
      <echo:ReverseEchoRequest>
         <echo:Message>Hello World!</echo:Message>
      </echo:ReverseEchoRequest>
   </soapenv:Body>
</soapenv:Envelope>}

  expected = %Q{<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
  <SOAP:Body>
    <echo:ReverseEchoResponse>
      <echo:Message>!dlroW olleH</echo:Message>
    </echo:ReverseEchoResponse>
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

  def test_echo_service_gives_error_for_must_understand_soap_headers
    post "/echo_service", %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
   <soapenv:Header>
     <echo:RandomHeader soapenv:mustUnderstand="1">
       Yes
     </echo:RandomHeader/>
   </soapenv:Header>
   <soapenv:Body>
      <echo:EchoRequest>
         <echo:Message>Hello World!</echo:Message>
      </echo:EchoRequest>
   </soapenv:Body>
</soapenv:Envelope>}

  expected = %Q{<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP:Body>
    <SOAP:Fault>
      <faultcode>SOAP:MustUnderstand</faultcode>
      <faultstring>SOAP Must Understand Error</faultstring>
    </SOAP:Fault>
  </SOAP:Body>
</SOAP:Envelope>}

    assert_equal expected.strip, last_response.body.strip
    assert_equal 500, last_response.status
  end

  def test_echo_service_ignores_soap_headers_with_actor_attribute_set
    post "/echo_service", %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
   <soapenv:Header>
     <echo:RandomHeader soapenv:mustUnderstand="1" soapenv:actor="http://www.without-brains.net/another_service">
       Yes
     </echo:RandomHeader/>
   </soapenv:Header>
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

    assert_equal expected.strip, last_response.body.strip
    assert_equal 200, last_response.status
  end

  def test_echo_service_checks_all_soap_headers
    post "/echo_service", %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:echo="http://www.without-brains.net/echo">
   <soapenv:Header>
     <echo:FirstRandomHeader soapenv:mustUnderstand="1" soapenv:actor="http://www.without-brains.net/another_service">
       Yes
     </echo:FirstRandomHeader/>
     <echo:SecondRandomHeader soapenv:mustUnderstand="1">
       Yes
     </echo:SecondRandomHeader/>
   </soapenv:Header>
   <soapenv:Body>
      <echo:EchoRequest>
         <echo:Message>Hello World!</echo:Message>
      </echo:EchoRequest>
   </soapenv:Body>
</soapenv:Envelope>}

  expected = %Q{<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP:Body>
    <SOAP:Fault>
      <faultcode>SOAP:MustUnderstand</faultcode>
      <faultstring>SOAP Must Understand Error</faultstring>
    </SOAP:Fault>
  </SOAP:Body>
</SOAP:Envelope>}

    assert_equal expected.strip, last_response.body.strip
    assert_equal 500, last_response.status
  end

  def test_wsdl_has_endpoint_url_based_on_env
    ENV['BASE_URL'] = 'http://echo.without-brains.net'
    get '/echo_service.wsdl'
    assert_equal 200, last_response.status
    wsdl_doc = Nokogiri::XML(last_response.body)
    endpoint_url =  wsdl_doc.root.at_xpath('//wsdl:service/wsdl:port/soap:address/@location', 'wsdl' => 'http://schemas.xmlsoap.org/wsdl/', 'soap' => 'http://schemas.xmlsoap.org/wsdl/soap/').value
    assert_equal "http://echo.without-brains.net/echo_service", endpoint_url
  end

  def test_wsdl_has_localhost_endpoint_url_when_none_is_set_in_env
    get '/echo_service.wsdl'
    assert_equal 200, last_response.status
    wsdl_doc = Nokogiri::XML(last_response.body)
    endpoint_url =  wsdl_doc.root.at_xpath('//wsdl:service/wsdl:port/soap:address/@location', 'wsdl' => 'http://schemas.xmlsoap.org/wsdl/', 'soap' => 'http://schemas.xmlsoap.org/wsdl/soap/').value
    assert_equal "http://localhost:#{last_request.port}/echo_service", endpoint_url
  end
end
