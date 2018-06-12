#encoding: utf-8
require 'savon'
require 'xmlsimple'
require 'net/http'
require 'gyoku'
require 'fileoperation'
require 'utility'

include FileOperation

  def soapreq(wsadd,method,action,req)
    begin
      @client = Savon.client(wsdl:wsadd)
      reqdata = Hash.new
      reqdata = req
      @response = @client.call(:"#{method}",soap_action: "") do
        message Gyoku.xml({:"#{action}Req"=>reqdata}, {:key_converter => :camelcase})
      end
      @response.to_xml
    rescue StandardError => e
      puts "HttpRequest::"+__method__.to_s()+": "+e.to_s
      Clog.to_log("HttpRequest::"+__method__.to_s()+": "+e.to_s)
    end
  end

  def http_request(domain,port,path,params,header,method,isdebug=true)
    begin
      http = Net::HTTP.new(domain,port)
      case port
        when 443
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
      end
      puts "method:"+method if isdebug
      puts "path: "+path if isdebug
      puts "header: "+header.to_s if isdebug
      puts "params:"+params.to_s if isdebug
      case method
        when 'get'
          return http.get(path+'?'+URI.encode_www_form(params),header)
        when 'post'
          return http.post(path,URI.encode_www_form(params),header)
        else
      end
    rescue StandardError => e
      puts "HttpRequest::"+__method__.to_s()+": "+e.to_s
      Clog.to_log("HttpRequest::"+__method__.to_s()+": "+e.to_s)
    end
  end
