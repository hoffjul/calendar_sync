module RequestHelpers
  def last_response_json
    JSON.parse(last_response.body, symbolize_names: true)
  end
end

RSpec.configure do |c|
  c.include RequestHelpers
end
