Rails.autoloaders.each do |autoloader|
  autoloader.collapse("#{Rails.root}/app/services/employee/concerns")
end
