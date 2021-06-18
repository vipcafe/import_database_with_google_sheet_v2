Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "/add_database", to: "students#add_data_to_database"
    end
  end
end
