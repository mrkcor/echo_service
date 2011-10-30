xml.SOAP(:Envelope, "xmlns:SOAP" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:echo" => "http://www.without-brains.net/echo") do
  xml.SOAP :Body do
    xml.echo :ReverseEchoResponse do
      xml.echo(:Message, message)
    end
  end
end
