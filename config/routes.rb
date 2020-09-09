Rails.application.routes.draw do
  
  mount DelayedJobWeb, at: "/delayed_job"

  get '/admin', to: 'admin#index', as: 'admin'

  post 'admin/run_import', to: 'admin#run_import', as: 'run_import'

  mount Blacklight::Engine => '/'
  Blacklight::Marc.add_routes(self)
  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  get 'pages/about', to: 'pages#about', as: 'about'
  get 'pages/policy', to: 'pages#policy', as: 'policy'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Route to the IIIF manifest.json for a particular image.
  get "iiif/2/:id/manifest.json" => "images#manifest",
    defaults: { format: 'json' },
    as: 'riiif_manifest'
end
