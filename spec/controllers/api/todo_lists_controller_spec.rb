require 'rails_helper'

RSpec.describe Api::TodoListsController, type: :controller do
  render_views

  let(:todo_list) { FactoryBot.create(:todo_list, name: 'Setup RoR project') }
  let(:item) { FactoryBot.create(:item, todo_list: todo_list, title: 'Prepare questions', description: 'Review possible questions', completed: false) }
  let(:valid_attributes) { { name: 'New list' } }
  let(:invalid_attributes) { { name: '' } }

  describe 'GET #index' do
    context 'when format is HTML' do
      it 'raises a routing error' do
        expect { get :index }.to raise_error(ActionController::RoutingError, 'Not supported format')
      end
    end

    context 'when format is JSON' do
      let!(:todo_list) { FactoryBot.create(:todo_list) }
      let!(:item) { FactoryBot.create(:item) }
      before { FactoryBot.create_list(:todo_list, 2) }

      it 'returns a successful response with all todo lists' do
        get :index, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).count).to eq(TodoList.count)
      end

      it 'includes todo list attributes' do
        get :index, format: :json
        todo_lists_json = JSON.parse(response.body)
        todo_list_json = todo_lists_json.find { |tl| tl['id'] == todo_list.id }

        aggregate_failures 'includes expected attributes' do
          expect(todo_list_json).to be_present
          expect(todo_list_json.keys).to match_array(%w[id name created_at updated_at])
          expect(todo_list_json['id']).to eq(todo_list.id)
          expect(todo_list_json['name']).to eq(todo_list.name)
        end
      end

      it 'does not include nested items' do
        get :index, format: :json
        json = JSON.parse(response.body)
        todo_list_json = json.find { |tl| tl['id'] == todo_list.id }
        expect(todo_list_json).not_to have_key('items')
      end

      it 'shows the lists ordered by created_at descending' do
        get :index, format: :json
        todo_lists_json = JSON.parse(response.body)
        expect(todo_lists_json).to eq(todo_lists_json.sort_by { |tl| tl['created_at'] }.reverse)
      end
    end
  end

  describe 'GET #show' do
    context 'when todo list exists' do
      it 'returns the todo list without items' do
        item
        get :show, params: { id: todo_list.id }, format: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        aggregate_failures 'includes todo list attributes' do
          expect(json['id']).to eq(todo_list.id)
          expect(json['name']).to eq(todo_list.name)
          expect(json).not_to have_key('items')
        end
      end
    end

    context 'when todo list does not exist' do
      it 'returns not found with error message' do
        get :show, params: { id: 9999 }, format: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Todo list not found')
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new todo list' do
        expect {
          post :create, params: { todo_list: valid_attributes }, format: :json
        }.to change(TodoList, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        aggregate_failures 'returns created todo list' do
          expect(json['name']).to eq('New list')
          expect(json['id']).to be_present
          expect(json['created_at']).to be_present
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity with errors' do
        post :create, params: { todo_list: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Name can't be blank")
      end
    end

    context 'with missing todo_list parameter' do
      it 'returns unprocessable entity with error' do
        post :create, params: {}, format: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Required parameter missing: todo_list')
      end
    end
  end

  describe 'POST #complete_all' do
    context 'when todo list exists' do
      it 'returns accepted status' do
        post :complete_all, params: { id: todo_list.id }, format: :json
        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Complete job in process')
      end
    end

    context 'when todo list does not exist' do
      it 'returns not found with error message' do
        post :complete_all, params: { id: 9999 }, format: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Todo list not found')
      end
    end

    context 'when todo list is empty' do
      it 'returns accepted status' do
        todo_list.items.destroy_all
        post :complete_all, params: { id: todo_list.id }, format: :json
        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Complete job in process')
      end
    end
  end

  describe 'PATCH #update' do
    context 'when todo list exists' do
      context 'with valid parameters' do
        it 'updates the todo list name' do
          patch :update, params: { id: todo_list.id, todo_list: { name: 'Updated' } }, format: :json
          expect(response).to have_http_status(:ok)
          expect(todo_list.reload.name).to eq('Updated')
          json = JSON.parse(response.body)
          expect(json['name']).to eq('Updated')
        end
      end

      context 'with invalid parameters' do
        it 'returns unprocessable entity with errors' do
          patch :update, params: { id: todo_list.id, todo_list: invalid_attributes }, format: :json
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include("Name can't be blank")
        end
      end
    end

    context 'when todo list does not exist' do
      it 'returns not found with error message' do
        patch :update, params: { id: 9999, todo_list: valid_attributes }, format: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Todo list not found')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when todo list exists' do
      it 'deletes the todo list and its items' do
        item_id = item.id
        todo_list_id = todo_list.id

        expect {
          delete :destroy, params: { id: todo_list.id }, format: :json
        }.to change(TodoList, :count).by(-1).and change(Item, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(TodoList.find_by(id: todo_list_id)).to be_nil
        expect(Item.find_by(id: item_id)).to be_nil
      end
    end

    context 'when todo list does not exist' do
      it 'returns not found with error message' do
        delete :destroy, params: { id: 9999 }, format: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Todo list not found')
      end
    end
  end
end
