require 'rest_client'

class CobotClient
  def initialize(access_token)
    @access_token = access_token
  end

  def get_resources(subdomain)
    get subdomain, '/resources'
  end

  def create_booking(subdomain, resource_id, attributes)
    post subdomain, "/resources/#{resource_id}/bookings", attributes
  end

  private

  def post(subdomain, path, params)
    RestClient.post "https://#{subdomain}.cobot.me/api#{path}", params, auth_headers
  end

  def get(subdomain, path)
    JSON.parse(
      RestClient.get("https://#{subdomain}.cobot.me/api#{path}", auth_headers).body,
      symbolize_names: true
    )
  end

  def auth_headers
    {'Authorization' => "Bearer #{@access_token}"}
  end
end
