require 'bundler'
Bundler.setup
require 'sinatra/base'
require 'nokogiri'
require 'builder'

class EchoService < Sinatra::Base
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
    mime_type :xml, "text/xml"
  end

  def initialize(*args)
    @xsd = Nokogiri::XML::Schema(File.read("#{File.dirname(__FILE__)}/public/echo_service.xsd"))
    @xslt = Nokogiri::XSLT(File.read("#{File.dirname(__FILE__)}/lib/soap_body.xslt"))
    super
  end

  post '/echo_service' do
    begin
      soap_message = Nokogiri::XML(request.body.read)
      raise(SoapFault::MustUnderstandError, "SOAP Must Understand Error", "MustUnderstand") if soap_message.root.at_xpath('//soap:Header/*[@soap:mustUnderstand="1" and not(@soap:actor)]', 'soap' => 'http://schemas.xmlsoap.org/soap/envelope/')
      soap_body = @xslt.transform(soap_message)
      errors = @xsd.validate(soap_body).map{|e| e.message}.join(", ")
      raise(SoapFault::ClientError, errors) unless errors == ""
      self.send(soap_operation_to_method(soap_body), soap_body)
    rescue StandardError => e
      fault_code = e.respond_to?(:fault_code) ? e.fault_code : "Server"
      halt(500, builder(:fault, :locals => {:fault_string => e.message, :fault_code => fault_code}))
    end
  end

  get '/echo_service.wsdl' do
    url = ENV['BASE_URL'] || "http://localhost:9292"
    erb(:echo_service_wsdl, :locals => {:url => url}, :content_type => :xml)
  end

  private

  def soap_operation_to_method(soap_body)
    method = soap_body.root.name.sub(/Request$/, '').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase.to_sym
  end

  def echo(soap_body)
    message = soap_body.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo').to_s
    builder(:echo_response, :locals => {:message => message})
  end

  def reverse_echo(soap_body)
    message = soap_body.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo').to_s.reverse!
    builder(:reverse_echo_response, :locals => {:message => message})
  end
end

if __FILE__ == $0
  EchoService.run!(port: 9292)
end
