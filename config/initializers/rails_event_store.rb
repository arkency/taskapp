require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

class LinkByTenantId
  def initialize(event_store: Rails.configuration.event_store, prefix: "$by_tenant_id_")
    @event_store = event_store
    @prefix = prefix
  end

  def call(event)
    tenant_id = event.metadata[:tenant_id]
    @event_store.link([event.event_id], stream_name: "#{@prefix}#{tenant_id}") if tenant_id
  end
end

class LinkAllWithNameParam
  def initialize(event_store: Rails.configuration.event_store, prefix: "$by_name_")
    @event_store = event_store
    @prefix = prefix
  end

  def call(event)
    name = event.data[:name]
    @event_store.link([event.event_id], stream_name: "#{@prefix}#{name}") if name
  end
end

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new
  Rails.configuration.command_bus = Arkency::CommandBus.new

  AggregateRoot.configure do |config|
    config.default_event_store = Rails.configuration.event_store
  end

  Rails.configuration.event_store.tap do |store|
    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
    store.subscribe_to_all_events(LinkByTenantId.new)
    store.subscribe_to_all_events(LinkAllWithNameParam.new)
    # store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :tenant_id))
  end
end
