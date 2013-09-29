require 'rest_client'

class CobotClient
  def initialize(access_token)
    @access_token = access_token
  end

  def get(subdomain, path)
    JSON.parse(
      RestClient.get("https://#{subdomain}.cobot.me/api#{path}", auth_headers).body,
      symbolize_names: true
    )
  end

  private

  def auth_headers
    {'Authorization' => "Bearer #{@access_token}"}
  end
end
