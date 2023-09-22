require "net/http"
require 'json'
require "uri"
require "date"

$metadata_url="http://169.254.169.254"
$oci_metadata_endpoint="/opc/v2/instance/"
$blocked_gcd_keys=["ssh-keys","startup-script","user-data","windows-keys"]

def debug_msg(txt)
  printf "#{txt}\n"
end

def determine_platform()
  aws_fact=Facter.fact("ec2_metadata")
  az_fact=Facter.fact("az_metadata")
  gce_fact=Facter.fact("gce")
  asset_fact=Facter.fact("chassisassettag")

  if !aws_fact.nil? then
    return {"name" => "Amazon EC2", "tags" => proc_aws_tags}
  elsif !az_fact.nil? then
    return {"name" => "Microsoft Azure", "tags" => proc_az_tags}
  elsif !gce_fact.nil? then
    return {"name" => "Google Cloud", "tags" => proc_gce_tags}
  else
    # Return the chassis asset tag
    return proc_unknown(asset_fact.value)
  end
end

def proc_unknown(tag)
  if tag.include? "OracleCloud.com"
    return {"name" => tag, "tags" => proc_oci_tags}
  else
    return nil
  end
end

def proc_oci_tags()
  uri = URI.parse($metadata_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 4
  http.read_timeout = 4
  request = Net::HTTP::Get.new($oci_metadata_endpoint, {"Authorization" => "Bearer Oracle"})
  response = http.request(request)
  response_code = response.code
  response_body = response.body
  if response_code == "200"
    response_json = JSON.parse(response_body)
    if response_json.has_key?("freeformTags") then
        return response_json["freeformTags"]
    end
  end
  return nil
end

def proc_az_tags()
  az_fact=Facter.fact("az_metadata").value
  az_tag_list=az_fact["compute"]["tagsList"]
  result={}
  az_tag_list.each do |tag|
    key=tag["name"]
    value=tag["value"]
    result[key]=value
  end
  return result
end

def proc_aws_tags()
  aws_fact=Facter.fact("ec2_metadata").value
  aws_tag_list=aws_fact["tags"]["instance"]
  return aws_tag_list
end

def proc_gce_tags()
  gce_fact=Facter.fact("gce").value
  gce_tag_list=gce_fact["instance"]["attributes"]
  gce_tag_list.each do |key,value|
    if $blocked_gcd_keys.include? key then
      gce_tag_list.delete(key)
    elsif key.include? "-script-" then
      gce_tag_list.delete(key)
    end
  end
  return gce_tag_list
end

def set_fact(name,value)
  Facter.add(name) do
    setcode do
      value
    end
  end
end

platform=determine_platform
if !platform.nil? then
  platform_name=platform["name"]
  platform_tags=platform["tags"]
  debug_msg "Detected #{platform_name}"
  set_fact("cloud_platform", platform_name)

  tags_dict = {}
  platform_tags.each do |key,value|
    name = key.to_s.dup
    name.downcase!
    name.gsub!(/\W+/, "_")
    fact_name = "tag_#{name}"
    set_fact(fact_name, value)
    tags_dict[name] = value
    debug_msg "Parsed tag #{name} as fact #{fact_name} with value #{value}"
  end
  set_fact("tags",tags_dict)
else
  debug_msg "Unsupported platform #{platform}"
end