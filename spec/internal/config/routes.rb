Rails.application.routes.draw do
  Blacklight.add_routes(self)

  root :to => "catalog#index"
  #
end
