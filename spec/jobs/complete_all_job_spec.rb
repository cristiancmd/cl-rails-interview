require 'rails_helper'

RSpec.describe CompleteAllJob, type: :job do
  include ActiveJob::TestHelper

  let(:todo_list) { FactoryBot.create(:todo_list) }

  describe '#perform' do
    context 'when todo list has items' do
      let!(:uncompleted_item) { FactoryBot.create(:item, todo_list: todo_list, completed: false) }
      let!(:completed_item) { FactoryBot.create(:item, todo_list: todo_list, completed: true) }

      it 'marks all items as completed' do
        perform_enqueued_jobs do
          CompleteAllJob.perform_now(todo_list)
        end

        uncompleted_item.reload
        completed_item.reload

        expect(uncompleted_item.completed).to be true
        expect(completed_item.completed).to be true
        expect(todo_list.items.all? { |item| item.completed }).to be true
      end
    end

    context 'when todo list has no items' do
      it 'does not raise an error' do
        expect {
          perform_enqueued_jobs do
            CompleteAllJob.perform_now(todo_list)
          end
        }.not_to raise_error

        expect(todo_list.items.count).to eq(0)
      end
    end
  end

  describe 'queueing' do
    it 'queues the job in the default queue' do
      expect {
        CompleteAllJob.perform_later(todo_list)
      }.to have_enqueued_job(CompleteAllJob).with(todo_list).on_queue('default')
    end
  end
end
