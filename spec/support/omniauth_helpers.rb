module OmniauthApiHelpers
  def stub_cobot_user(attributes = {credentials: {}, extra: {raw_info: {admin_of: []}}})
    OmniAuth.config.add_mock(:cobot, attributes)
  end
end

RSpec.configure do |c|
  c.include OmniauthApiHelpers
end
