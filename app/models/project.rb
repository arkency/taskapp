class Project < ApplicationRecord
  after_create_commit do
    broadcast_prepend_to "projects", target: :projects_table_body, locals: { project: self }
  end
end
