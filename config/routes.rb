BlacklightAdvancedSearch::Engine.routes.draw do
  get 'advanced' => 'catalog#advanced_search', as: 'advanced_search'
end
