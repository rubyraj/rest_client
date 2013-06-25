class ApiClient < ActiveRecord::Base
  attr_accessible :method, :url
end
