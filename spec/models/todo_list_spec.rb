require 'rails_helper'

RSpec.describe TodoList, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      todo_list = FactoryBot.build(:todo_list, name: nil)
      expect(todo_list).not_to be_valid
      expect(todo_list.errors[:name]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'has many items with dependent destroy' do
      assoc = described_class.reflect_on_association(:items)
      expect(assoc.macro).to eq :has_many
      expect(assoc.options[:dependent]).to eq :destroy
    end

    it 'destroys associated items when destroyed' do
      todo_list = FactoryBot.create(:todo_list)
      FactoryBot.create_list(:item, 2, todo_list: todo_list)
      expect { todo_list.destroy }.to change(Item, :count).by(-2)
    end
  end

  describe 'default scope' do
    it 'orders todo lists by created_at in descending order' do
      older = FactoryBot.create(:todo_list, created_at: 2.days.ago)
      newer = FactoryBot.create(:todo_list, created_at: 1.day.ago)
      expect(TodoList.all.to_a).to eq([newer, older])
    end
  end

  describe 'database constraints' do
    it 'enforces name not null' do
      expect {
        TodoList.create!(name: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
