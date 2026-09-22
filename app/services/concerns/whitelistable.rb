module Whitelistable
  private

  def whitelisted(value, allowed, fallback)
    value = value.to_s
    allowed.include?(value) ? value : fallback
  end
end
