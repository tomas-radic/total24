class ServiceResult
  attr_reader :value, :errors

  def initialize(success:, value: nil, errors: [])
    @success = success
    @value = value
    @errors = Array(errors)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
