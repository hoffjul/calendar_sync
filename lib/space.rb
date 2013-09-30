class Space
  def initialize(attributes)
    @attributes = attributes
  end

  def name
    @attributes[:space_name]
  end

  def synchronizations
    Synchronization.where(subdomain: subdomain).tap do |syncs|
      syncs.each do |synchronization|
        synchronization.resource_name = resources.find{|r| r.id == synchronization.resource_id}.try(:name)
      end
    end
  end

  def access_token
    @attributes[:access_token]
  end

  def subdomain
    @attributes[:space_subdomain]
  end

  def resources
    @resources ||= CobotClient::ApiClient.new(access_token).get_resources(subdomain).map{|r| Resource.new(r) }
  end
end
