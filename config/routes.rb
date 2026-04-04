Rails.application.routes.draw do
  get 'dashboard/index'
  devise_for :users

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  root 'dashboard#index'
end
