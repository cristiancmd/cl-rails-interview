require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe Api::ItemsController, type: :controller do
  let!(:todo_list) { FactoryBot.create(:todo_list) }
  let(:valid_attributes) { { title: 'Test Item', description: 'Test Description', completed: false } }
  let(:invalid_attributes) { { title: '' } } # Empty title to trigger validation error
  let(:item) { FactoryBot.create(:item, todo_list: todo_list) }

  describe 'GET #index' do
    context 'when todo list has items' do
      let!(:items) { FactoryBot.create_list(:item, 3, todo_list: todo_list) }

      it 'returns a list of items' do
        get :index, params: { todo_list_id: todo_list.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(3)
        expect(JSON.parse(response.body).map { |i| i['id'] }).to match_array(items.map(&:id))
      end

      it 'returns only items belonging to the specified todo list' do
        other_todo_list = FactoryBot.create(:todo_list)
        FactoryBot.create_list(:item, 2, todo_list: other_todo_list)

        get :index, params: { todo_list_id: todo_list.id }, format: :json
        expect(JSON.parse(response.body).size).to eq(3)
        expect(JSON.parse(response.body).map { |i| i['todo_list_id'] }).to all(eq(todo_list.id))
      end
    end

    context 'when todo list has no items' do
      it 'returns an empty array' do
        get :index, params: { todo_list_id: todo_list.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'when todo list does not exist' do
      it 'returns not found' do
        get :index, params: { todo_list_id: 9999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    context 'when item exists' do
      it 'returns the item' do
        get :show, params: { todo_list_id: todo_list.id, id: item.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq(item.id)
        expect(JSON.parse(response.body)['title']).to eq(item.title)
      end

      it 'returns item with all expected attributes' do
        get :show, params: { todo_list_id: todo_list.id, id: item.id }, format: :json
        body = JSON.parse(response.body)
        expect(body).to include('id', 'title', 'description', 'completed', 'todo_list_id')
      end
    end

    context 'when item does not exist' do
      it 'returns not found' do
        get :show, params: { todo_list_id: todo_list.id, id: 9999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when item belongs to a different todo list' do
      it 'returns not found' do
        other_todo_list = FactoryBot.create(:todo_list)
        other_item = FactoryBot.create(:item, todo_list: other_todo_list)

        get :show, params: { todo_list_id: todo_list.id, id: other_item.id }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new item' do
        expect {
          post :create, params: { todo_list_id: todo_list.id, item: valid_attributes }, format: :json
        }.to change(todo_list.items, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['title']).to eq('Test Item')
      end

      it 'creates an item with correct attributes' do
        post :create, params: { todo_list_id: todo_list.id, item: valid_attributes.merge(completed: true) }, format: :json
        expect(JSON.parse(response.body)['completed']).to eq(true)
        expect(JSON.parse(response.body)['description']).to eq('Test Description')
        expect(JSON.parse(response.body)['todo_list_id']).to eq(todo_list.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity with errors' do
        post :create, params: { todo_list_id: todo_list.id, item: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Title can't be blank")
      end

      it 'does not create an item with extremely long title' do
        long_title = 'a' * 500
        post :create, params: { todo_list_id: todo_list.id, item: valid_attributes.merge(title: long_title) }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when todo list does not exist' do
      it 'returns not found' do
        post :create, params: { todo_list_id: 9999, item: valid_attributes }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when parameters are malformed' do
      it 'returns bad request when item params are missing' do
        post :create, params: { todo_list_id: todo_list.id }, format: :json
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { title: 'Updated Title', completed: true } }

      it 'updates the item' do
        patch :update, params: { todo_list_id: todo_list.id, id: item.id, item: new_attributes }, format: :json
        expect(response).to have_http_status(:ok)
        item.reload
        expect(item.title).to eq('Updated Title')
        expect(item.completed).to be true
        expect(JSON.parse(response.body)['title']).to eq('Updated Title')
      end

      it 'updates only specified attributes' do
        original_description = item.description
        patch :update, params: { todo_list_id: todo_list.id, id: item.id, item: { completed: true } }, format: :json
        item.reload
        expect(item.description).to eq(original_description)
        expect(item.completed).to be true
      end

      it 'handles partial updates correctly' do
        patch :update, params: { todo_list_id: todo_list.id, id: item.id, item: { description: 'New description' } }, format: :json
        expect(response).to have_http_status(:ok)
        item.reload
        expect(item.description).to eq('New description')
        expect(JSON.parse(response.body)['description']).to eq('New description')
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity with errors' do
        patch :update, params: { todo_list_id: todo_list.id, id: item.id, item: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Title can't be blank")
      end
    end

    context 'when item does not exist' do
      it 'returns not found' do
        patch :update, params: { todo_list_id: todo_list.id, id: 9999, item: valid_attributes }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when parameters are malformed' do
      it 'returns bad request when item params are missing' do
        patch :update, params: { todo_list_id: todo_list.id, id: item.id }, format: :json
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when item exists' do
      it 'deletes the item' do
        item
        expect {
          delete :destroy, params: { todo_list_id: todo_list.id, id: item.id }, format: :json
        }.to change(todo_list.items, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'verifies item is not retrievable after deletion' do
        item_id = item.id
        delete :destroy, params: { todo_list_id: todo_list.id, id: item_id }, format: :json
        get :show, params: { todo_list_id: todo_list.id, id: item_id }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when item does not exist' do
      it 'returns not found' do
        delete :destroy, params: { todo_list_id: todo_list.id, id: 9999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when item belongs to a different todo list' do
      it 'returns not found and does not delete the item' do
        other_todo_list = FactoryBot.create(:todo_list)
        other_item = FactoryBot.create(:item, todo_list: other_todo_list)

        expect {
          delete :destroy, params: { todo_list_id: todo_list.id, id: other_item.id }, format: :json
        }.not_to change(Item, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
