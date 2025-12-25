class Matches::UpdateService < ApplicationService
  def call(match, params)
    if match.update(params)
      success(match)
    else
      failure(match.errors.full_messages, value: match)
    end
  end
end
