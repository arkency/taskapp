# frozen_string_literal: true

class Task
  attr_reader :name, :date

  def initialize
    @status = :open
  end

  def change_name(new_name)
    @name = new_name
  end

  def assign_date(new_date)
    @date = new_date
  end

  def complete
    @status = :completed
  end

  def delete
    @status = :deleted
  end

  def reopen
    @status = :open
  end

end
