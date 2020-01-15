# frozen_string_literal: true

BlacklightAdvancedSearch::Engine.routes.draw do
  get 'advanced' => 'advanced#index', as: 'advanced_search'
end
