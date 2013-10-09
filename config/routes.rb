Rails.application.routes.draw do
  get 'advanced' => 'advanced#index', :as => 'advanced_search'
end
