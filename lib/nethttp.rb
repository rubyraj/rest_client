require 'rubygems'
require 'digest/md5'
require 'cgi'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'active_support/core_ext'
AUTH_ENABLED = false
AUTH_HEADER = {}
module NetHttp

  def new_net_http(host, port, http_scheme)
    new_http = Net::HTTP.new(host, port)
    new_http.use_ssl = (http_scheme == 'https')
    new_http.verify_mode = OpenSSL::SSL::VERIFY_NONE if new_http.use_ssl?
    new_http
  end

  def get(uri, params, header={})
    header = AUTH_HEADER if AUTH_ENABLED
    url = URI.parse(uri)
    url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    request = Net::HTTP::Get.new(url_path)
    request.set_form_data(params)
    header.each{|k,v| request.add_field(k,v)}
    new_net_http(url.host, url.port, url.scheme).request(request)
  end

  def get_head(uri)
    url = URI.parse(uri)
    #url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    Net::HTTP::start(url.host, url.port) do |http|
      http.head(url.path)
    end
  end

  def get_url_params(uri, header={})
    header = AUTH_HEADER if AUTH_ENABLED
    url = URI.parse(uri)
    url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    request = Net::HTTP::Get.new(url_path)
    #request.set_form_data(params)
    #header.each{|k,v| request.add_field(k,v)}
    new_net_http(url.host, url.port, url.scheme).request(request)
  end

  #Send PUT request on given entity
  def put(uri, params, body='', header={})
    header = AUTH_HEADER if AUTH_ENABLED
    url = URI.parse(uri)
    url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    request = Net::HTTP::Put.new(url_path)
    header.each { |k,v| request.add_field(k,v)}
    request.body = body
    request.set_form_data(params)
    new_net_http(url.host, url.port, url.scheme).request(request)
  end

  #Send POST request on given entity
  def post(uri, params, body='', header={})
    header = AUTH_HEADER if AUTH_ENABLED
    url = URI.parse(uri)
    url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    request = Net::HTTP::Post.new(url_path)
    header.each { |k,v| request.add_field(k,v)}
    request.body = body
    request.set_form_data(params)
    new_net_http(url.host, url.port, url.scheme).request(request)
  end

  #Send POST request on given entity
  def post_url(uri, body='', header={})
    header = AUTH_HEADER if AUTH_ENABLED
    url = URI.parse(uri)
    url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    request = Net::HTTP::Post.new(url_path)
    #header.each { |k,v| request.add_field(k,v)}
    request.body = body
    #request.set_form_data(params)
    new_net_http(url.host, url.port, url.scheme).request(request)
  end

  def delete(uri, params, header={})
    url = URI.parse(uri)
    url_path = url.query.nil? ? url.path : url.path + "?" + url.query
    request = Net::HTTP::Delete.new(url_path)
    header.each { |k,v| request.add_field(k,v)}
    request.body = nil
    request.set_form_data(params)
    new_net_http(url.host, url.port, url.scheme).request(request)
  end

  #search given xml for the given element and parse out the xml body of each instance of given xml element
  #this returns xml of given instance.
  def xml_search_element(xml, path_str)
    #Search given xml using given string and return matching.
    element_xml = Nokogiri::XML.parse(xml).search(path_str)

    #retrieve given instance of search element body, if more than one found.
    $xmlelementbody = element_xml.to_a[0].to_xml
  end

  def get_element_attributes(xml, element)
    REXML::Document.new(xml).elements(element).attributes
  end

  def get_element_text(xml, element)
    REXML::XPath.first(REXML::Document.new(xml), "//"+element).text
    #REXML::Document.new(xml).elements(element).text
  end

  def verify_res_xml_has_given_data(res_xml, element2search, data)
    #strip off response and entities elements from response
    response_xml_array = Nokogiri::XML.parse(res_xml.body).search("//#{element2search}").to_a
    #convert rest of response xml into hash
    response_hash_array = Array.new
    for instance in 0..response_xml_array.length-1
      #response_hash_array[instance] = XmlSimple.xml_in(response_xml_array[instance].to_s ,{"ForceArray" => ['link']}) #"KeepRoot" => true
      response_hash_array[instance] = xml_to_hash(response_xml_array[instance].to_s, false)
    end

    #Verify expected # of elements.
    response_hash_array.length.should == data.hashes.size

    #processes given api data
    expected_hash = process_input_api_data(data)

    #Verify response XML elements has expected elements and values.
    for index in 0..expected_hash.length-1
      expected_hash[index].keys.each do |key|
        actual, expected = response_hash_array[index][key], expected_hash[index][key]
        #output = "Verify #{key} value (expected = actual) => (#{actual} = #{expected}) "
        expected.empty? ? (actual.empty?.should == expected.empty?) : (actual.should == expected)
      end
    end
  end

  def verify_xml_has_given_data(xml, element2search, data)
    #strip off response and entities elements from response
    response_xml_array = Nokogiri::XML.parse(xml).search("//#{element2search}").to_a
    #convert rest of response xml into hash
    response_hash_array = Array.new
    for instance in 0..response_xml_array.length-1
      #response_hash_array[instance] = XmlSimple.xml_in(response_xml_array[instance].to_s ,{"ForceArray" => false}) #"KeepRoot" => true
      response_hash_array[instance] = xml_to_hash(response_xml_array[instance], false)
    end

    #Verify expected # of elements.
    response_hash_array.length.should == data.hashes.size

    #processes given api data
    expected_hash = process_input_api_data(data)

    #Verify response XML elements has expected elements and values.
    for index in 0..expected_hash.length-1
      expected_hash[index].keys.each do |key|
        actual, expected = response_hash_array[index][key], expected_hash[index][key]
        #expected.empty? ? (actual.empty?.should == expected.empty?) : (actual.should == expected)
        #TODO Debug code to be deleted
        if expected.empty?
          (actual.empty?.should == expected.empty?)
        elsif actual != expected
          p "Actual Hash =>"
          p response_hash_array
          p "Expected Hash =>"
          p expected_hash
          raise "unexpected VALUE for hash key : #{key }\n expected: #{expected} \n actual: #{actual}"
        end
      end
    end
  end

  def xml_to_hash(xml, keep_root=true)
    XmlSimple.xml_in(xml.to_s, {'KeepRoot'=>keep_root, 'NoAttr'=>false, 'ForceArray'=>false})
  end

  def hash_to_xml(hash, root)
    XmlSimple.xml_out(hash,{"RootName"=>root,"NoAttr"=>true})
  end

  #href="/erb/api/v1/data/Restaurant/9197/Shift/1" "1" is the id returned"
  def href_id(href_txt)
    array = href_txt.split("/")
    array[array.size-1]
  end

  #returns and array of attribute hashes for all link elements under given element.
  def get_link_attributes(element)
    entities_ele = element.elements["entities"]
    element = entities_ele if not entities_ele.nil?
    link_attributes = []
    element.elements().to_a("link").each do |link|
      link_attributes << link.attributes
    end
    link_attributes
  end


  #element should be of type REXML:Element
  def verify_element_has(element, expected_val, links=nil, has_entities=false)
    element.class.should == REXML::Element
    if has_entities
      if links.nil?
        XPath.first(element, "entities/link").should == nil
        XPath.first(element, "entities").attributes["count"].should be_zero
      else
        element.elements["entities"].attributes["count"].should == links
      end
    end
    raise "unexpected value for element '#{element.name}' : expected = #{expected_val}\ngot = #{element.text}" if element.text != expected_val
  end
end

