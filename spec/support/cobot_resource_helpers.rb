module CobotResourceHelpers
  def stub_cobot_resources(subdomain, resources)
    stub_request(:get, "https://#{subdomain}.cobot.me/api/resources")
      .with(headers: {'Authorization' => 'Bearer token-123'})
      .to_return(body: resources.to_json)
  end
end

RSpec.configure do |c|
  c.include CobotResourceHelpers
end
