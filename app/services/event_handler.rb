class EventHandler < ApplicationJob
  def perform(payload)
    event = event_store.read.event(payload.symbolize_keys.fetch(:event_id))
    event_store.with_metadata(
      **event.metadata.to_h.slice(:user_id, :locale, :tenant_id),
      correlation_id: event.metadata[:correlation_id],
      causation_id: event.event_id
    ) { call(event) }
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
