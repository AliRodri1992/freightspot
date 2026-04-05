Rails.application.routes.draw do
  get 'home/index'
  devise_for :users

  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
  end

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  root 'home#index'
end
