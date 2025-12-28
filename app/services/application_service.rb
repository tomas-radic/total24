class ApplicationService
  def self.call(...)
    new(...).call
  end

  protected

  def success(value = nil)
    ServiceResult.new(success: true, value: value)
  end

  def failure(errors = [], value: nil)
    ServiceResult.new(success: false, errors: Array(errors), value: value)
  end
end
