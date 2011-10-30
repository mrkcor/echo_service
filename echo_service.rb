require 'bundler'
Bundler.setup
require 'sinatra/base'
require 'nokogiri'
require 'builder'

class EchoService < Sinatra::Base
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
      doc = Nokogiri::XML(request.body.read)
      soap_message = @xslt.transform(doc)
      errors = @xsd.validate(soap_message).map{|e| e.message}.join(", ")
      raise errors unless errors == ""
      self.send(soap_operation_to_method(soap_message), soap_message)
    rescue Exception => e
      halt(500, builder(:fault, :locals => {:fault_string => e.message}))
    end
  end

  get '/echo_service.wsdl' do
    url = ENV['BASE_URL'] || "http://localhost:9292"
    erb(:echo_service_wsdl, :locals => {:url => url}, :content_type => :xml)
  end

  private

  def soap_operation_to_method(soap_message)
    method = soap_message.root.name.sub(/Request$/, '').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase.to_sym
  end

  def echo(soap_message)
    message = soap_message.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo').to_s
    builder(:echo_response, :locals => {:message => message})
  end

  def reverse_echo(soap_message)
    message = soap_message.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo').to_s.reverse!
    builder(:reverse_echo_response, :locals => {:message => message})
  end
end
