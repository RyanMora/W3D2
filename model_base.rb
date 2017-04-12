require 'byebug'

class ModelBase
  def self.find_by_id(id)
    models = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table}
      WHERE
        id = ?
    SQL
    return nil unless models.length > 0

    self.new(models.first)
  end
end
