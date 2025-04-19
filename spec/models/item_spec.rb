require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:todo_list) { FactoryBot.create(:todo_list) }

  describe 'validations' do
    it 'validates presence of title' do
      item = FactoryBot.build(:item, title: nil, todo_list: todo_list)
      expect(item).not_to be_valid
      expect(item.errors[:title]).to include("can't be blank")
    end

    it 'validates title length is at most 250 characters' do
      item = FactoryBot.build(:item, title: 'a' * 251, todo_list: todo_list)
      expect(item).not_to be_valid
      expect(item.errors[:title]).to include('is too long (maximum is 250 characters)')

      item.title = 'a' * 250
      expect(item).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to todo_list' do
      assoc = described_class.reflect_on_association(:todo_list)
      expect(assoc.macro).to eq :belongs_to
      expect(assoc.options[:optional]).to be_nil # Required by default
    end

    it 'requires a valid todo_list_id' do
      item = FactoryBot.build(:item, todo_list_id: 9999)
      expect(item).not_to be_valid
      expect(item.errors[:todo_list]).to include('must exist')
    end
  end

  describe 'scopes' do
    let!(:completed_item) { FactoryBot.create(:item, todo_list: todo_list, completed: true) }
    let!(:pending_item) { FactoryBot.create(:item, todo_list: todo_list, completed: false) }

    describe '.completed' do
      it 'returns only completed items' do
        expect(Item.completed).to include(completed_item)
        expect(Item.completed).not_to include(pending_item)
      end
    end

    describe '.pending' do
      it 'returns only pending items' do
        expect(Item.pending).to include(pending_item)
        expect(Item.pending).not_to include(completed_item)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_update_commit' do
      let(:item) { FactoryBot.create(:item, todo_list: todo_list) }

      it 'broadcasts replace to the item' do
        expect(item).to receive(:broadcast_replace_to).with(item)
        item.update(title: 'Updated Title')
      end
    end
  end

  describe 'database constraints' do
    it 'enforces todo_list_id not null' do
      expect {
        Item.create!(title: 'Test', todo_list_id: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
