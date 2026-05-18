ChatwootKanban::Engine.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :accounts do
          resources :kanban_labels, path: 'kanban/labels', only: [:index, :create, :update, :destroy]

          resources :kanban_boards, path: 'kanban/boards' do
            member { post :duplicate }
            resources :kanban_columns, path: 'columns' do
              collection { patch :reorder }
            end
            resources :kanban_cards, path: 'cards' do
              collection { patch :move }
              member     { post  :unarchive }

              resources :kanban_card_activities, path: 'activities', only: [:index]
              resources :kanban_comments,        path: 'comments',   only: [:index, :create, :destroy]
              resources :kanban_checklist_items, path: 'checklist' do
                member { patch :toggle }
              end
              post   'labels/:label_id', to: 'labels#assign',   as: :assign_label
              delete 'labels/:label_id', to: 'labels#unassign', as: :unassign_label
            end
          end
        end
      end
    end
  end
end
