class User
  def initialize(attributes)
    @attributes = attributes
  end

  def admin_of
    @attributes[:extra][:raw_info][:admin_of].map{|a| Space.new(a.merge(access_token: access_token))}
  end

  def admin_of?(subdomain)
    admin_of.map(&:subdomain).include?(subdomain)
  end

  def access_token
    @attributes[:credentials][:token]
  end

  def space(subdomain)
    admin_of.find{|s| s.subdomain == subdomain}
  end
end
