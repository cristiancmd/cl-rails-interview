Rails.application.routes.draw do
  namespace :api do
    resources :todo_lists, path: :todolists, defaults: { format: :json } do
      resources :items, only: %i[index show create update destroy], defaults: { format: :json }, path: :items
      patch :complete_all, on: :member
    end
  end

  resources :todo_lists, except: %i[new], path: :todolists do
    patch :complete_all, on: :member
    resources :items, only: [:new, :create, :update, :destroy, :show] do
      patch :toggle, on: :member
    end
  end

  root 'todo_lists#index'
end
