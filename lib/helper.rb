require 'rubygems'
require 'digest/md5'
require 'cgi'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'active_support/core_ext'
require 'nethttp.rb'
include NetHttp
$access = {}

def api_call(http_method, url, params={})
  # url = $base_url + url
  #if url.include? 'tf1' then
  #  p "WARNING!!! WARNING!!! WARNING!!! This operation is on TF1 service"
  #  gets
  #end

  url,params = url.split("?") if url.include?"?"
  if not url =~ /client_authorize/
    if cookies['access_id'].nil? or cookies['access_secret'].nil?
      @errors = "Please do 'client_authorize' before doing any other call"
    end

    p @errors
    $access = {"access_id" => cookies['access_id'].to_s, "access_secret" => cookies['access_secret'].to_s}
    params = params.empty? ? add_access_signature :  add_access_signature(params)
  end
  
  if params.is_a? String
    url = url + '?' + params
    params = {}
    puts url
  else
    puts "\n" + url + '?' + params.map { |k, v| "#{k.to_s}=#{v.to_s}" }.join('&')
  end

  #make http call
  response = send(http_method,url,params)

  #p response.code
  #pp response.body
  # raise "unexpected response: code => #{response.code} body=>#{response.body} class=>#{response.class}" unless response.is_a? Net::HTTPSuccess
  # JSON.parse(response.body)['response'] unless response.body.strip.empty?
  response
end

params_hash = {access_id:'xyz',platform_ids:[1,2,3],subtitle_languages:['eng'],start_point:'230',end_point:'230',interlaced:true}
def pkg_params(params_hash)
  param_str = ''
  params_hash.each do |key,val|
    if val.is_a? Array
      val.each do |v|
        param_str += "#{key.to_s}[]=#{v.to_s}"
      end
    else
      param_str += "#{key.to_s}=#{val.to_s}"
    end
  end
end

def add_access_signature(params={})
  if params.is_a? String
    #sample param1=val1&param2=val2&param3=val3
    params += "&" unless params.empty?
    params = params + "access_id=#{$access["access_id"]}"
    params + "&signature=#{signature_text(params)}"
  else
    params = params.merge('access_id' => $access["access_id"])
    params.merge({'signature' => signature(params)})
  end
end

#params is hash
def signature(params)
  a_params = params.map { |k, v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }
  Digest::MD5.hexdigest(a_params.sort.join("&")+$access["access_secret"])
end

#params as string param1=val1&param2=val2&param3=val3
def signature_text(param_str)
  params = param_str.split('&').map { |cell| CGI.escape(cell.split('=')[0])+'='+CGI.escape(cell.split('=')[1]) }
  Digest::MD5.hexdigest(params.sort.join('&')+$access['access_secret'])
end


# Using custom set_form_data and urlencode
# Ruby NET/HTTP does not support duplicate parameter names
# File net/http.rb, line 1426
def set_form_data(request, params, sep = '&')
  request.body = params.map { |k, v|
    if v.instance_of?(Array)
      v.map { |e| "#{urlencode(k.to_s)}=#{urlencode(e.to_s)}" }.join(sep)
    else
      "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}"
    end
  }.join(sep)
  request.content_type = 'application/x-www-form-urlencoded'
end

def urlencode(str)
  str.gsub(/[^a-zA-Z0-9_\.\-]/n) { |s| sprintf('%%%02x', s[0]) }
end

def pt(val)
  puts "\t#{val}"
end
