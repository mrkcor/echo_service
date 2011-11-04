require 'bundler'
Bundler.setup
require 'sinatra/base'
require 'nokogiri'
require 'builder'

class EchoService < Sinatra::Base
  # Exception classes that are translated into SOAP faults
  module SoapFault
    class MustUnderstandError < StandardError
      def fault_code
        "MustUnderstand"
      end
    end

    class ClientError < StandardError
      def fault_code
        "Client"
      end
    end
  end

  set :root, File.dirname(__FILE__)

  configure do
    # SOAP requires SOAP messages to have Content-Type text/xml (the
    # Sinatra default is application/xml)
    mime_type :xml, "text/xml"
  end

  def initialize(*args)
    @xsd = Nokogiri::XML::Schema(File.read("#{File.dirname(__FILE__)}/public/echo_service.xsd"))
    @xslt = Nokogiri::XSLT(File.read("#{File.dirname(__FILE__)}/lib/soap_body.xslt"))
    super
  end

  # SOAP endpoint
  post '/echo_service' do
    begin
      soap_message = Nokogiri::XML(request.body.read)
      # The EchoService isn't programmed to handle particular SOAP headers,
      # any SOAP headers with mustUnderstand="1" will result in a SOAP fault
      # with fault_code MustUnderstand (indicating that the EchoService
      # couldn't process a mandatory SOAP header)
      raise(SoapFault::MustUnderstandError, "SOAP Must Understand Error", "MustUnderstand") if soap_message.root.at_xpath('//soap:Header/*[@soap:mustUnderstand="1" and not(@soap:actor)]', 'soap' => 'http://schemas.xmlsoap.org/soap/envelope/')
      # Extract the SOAP body from SOAP envelope using XSLT
      soap_body = @xslt.transform(soap_message)
      # Validate the content of the SOAP body using the XML schema that is used
      # within the WSDL
      errors = @xsd.validate(soap_body).map{|e| e.message}.join(", ")
      # If the content of the SOAP body does not validate generate a SOAP fault
      # with fault_code Client (indicating the message failed due to a client
      # error)
      raise(SoapFault::ClientError, errors) unless errors == ""
      # Attempt to determine the SOAP operation and process it
      self.send(soap_operation_to_method(soap_body), soap_body)
    rescue StandardError => e
      # If any exception was raised generate a SOAP fault, if there is no
      # fault_code present then default to fault_code Server (indicating the
      # message failed due to an error on the server)
      fault_code = e.respond_to?(:fault_code) ? e.fault_code : "Server"
      halt(500, builder(:fault, :locals => {:fault_string => e.message, :fault_code => fault_code}))
    end
  end

  # Serve the WSDL. If the BASE_URL environmental variable is set then use
  # that to form the endpoint URL, otherwise default to localhost with
  # request port number
  get '/echo_service.wsdl' do
    url = ENV['BASE_URL'] || "http://localhost:#{request.port}"
    erb(:echo_service_wsdl, :locals => {:url => url}, :content_type => :xml)
  end

  private

  # Detect the SOAP operation based on the root element in the SOAP body
  def soap_operation_to_method(soap_body)
    method = soap_body.root.name.sub(/Request$/, '').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase.to_sym
  end

  # Echo operation, send back the message given
  def echo(soap_body)
    message = soap_body.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo').to_s
    builder(:echo_response, :locals => {:message => message})
  end

  # ReverseEcho operation, send back the message given in reverse
  def reverse_echo(soap_body)
    message = soap_body.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo').to_s.reverse!
    builder(:reverse_echo_response, :locals => {:message => message})
  end
end

if __FILE__ == $0
  # Run the EchoService on port 9292 if this file is executed directly
  EchoService.run!(port: 9292)
end
