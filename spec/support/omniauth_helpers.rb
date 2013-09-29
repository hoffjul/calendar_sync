module OmniauthApiHelpers
  def stub_cobot_user(attributes)
    OmniAuth.config.add_mock(:cobot, attributes)
  end
end

RSpec.configure do |c|
  c.include OmniauthApiHelpers
end
