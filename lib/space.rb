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

  def subdomain
    @attributes[:space_subdomain]
  end

  def resources
    @resources ||= CobotClient.new(@attributes[:access_token]).get(subdomain, '/resources').map{|r| Resource.new(r) }
  end
end
