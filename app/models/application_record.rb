class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.with_advisory_lock(*args)
    transaction do
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{Zlib.crc32(args.join)})")
      yield
    end
  end
end
