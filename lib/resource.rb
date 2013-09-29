class Resource
  def initialize(attributes)
    @attributes = attributes
  end

  def name
    @attributes[:name]
  end

  def id
    @attributes[:id]
  end
end
