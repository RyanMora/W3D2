require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super ('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question
  attr_accessor :title, :body, :user_id

  def self.find_by_id(id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless questions.length > 0

    Question.new(questions.first)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map {|question| Question.new(question)}
  end

  def self.most_followed(n)
    Follow.most_followed_questions(n)
  end

  def self.most_liked(n)
    Like.most_liked_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def author
    User.find_by_id(@user_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    Follow.followers_for_question_id(@id)
  end

  def likers
    Like.likers_for_question_id(@id)
  end

  def num_likes
    Like.num_likes_for_question_id(@id)
  end
end

class Follow
  attr_accessor :question_id, :user_id

  def self.find_by_id(id)
    follows = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    return nil unless follows.length > 0

    Follow.new(follows.first)
  end

  def self.followers_for_question_id(question_id)
    follows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, fname, lname
      FROM
        question_follows
        JOIN users ON users.id = user_id
      WHERE
        question_id = ?
    SQL
    return nil unless follows.length > 0

    follows.map{|follow| User.new(follow)}
  end

  def self.followed_questions_for_user_id(user_id)
    follows = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, title, body, questions.user_id
      FROM
        question_follows
        JOIN questions ON question_id = questions.id
      WHERE
        question_follows.user_id = ?
    SQL
    return nil unless follows.length > 0

    follows.map{|follow| Question.new(follow)}
  end

  def self.most_followed_questions(n)
    follows = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, title, body, questions.user_id
      FROM
        questions
        JOIN question_follows ON questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.user_id) DESC
      LIMIT
        ?
    SQL
    return nil unless follows.length > 0

    follows.map{|follow| Question.new(follow)}
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end

class User
  attr_accessor :fname, :lname

  def self.find_by_id(id)
    users = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless users.length > 0

    User.new(users.first)
  end

  def self.find_by_name(fname, lname)
    users = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless users.length > 0

    users.map {|user| User.new(user)}
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    Follow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    Like.liked_questions_for_user_id(@id)
  end

  def average_karma
    users = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        COUNT(DISTINCT questions.id) / CAST(COUNT(question_likes.user_id) AS FLOAT) AS 'avg'
      FROM
        questions
        LEFT JOIN question_likes ON questions.id = question_likes.question_id
      WHERE
        questions.user_id = ?
    SQL
    return nil unless users.length > 0

    users.first['avg']
  end

end

class Reply
  attr_accessor :question_id, :user_id, :parent_id, :body

  def self.find_by_id(id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless replies.length > 0

    Reply.new(replies.first)
  end

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map {|reply| Reply.new(reply)}
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map {|reply| Reply.new(reply)}
  end

  def self.find_by_parent_id(parent_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map {|reply| Reply.new(reply)}
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    return nil unless @parent_id
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    Reply.find_by_parent_id(@id)
  end
end

class Like
  attr_accessor :question_id, :user_id

  def self.find_by_id(id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    return nil unless likes.length > 0

    Like.new(likes.first)
  end

  def self.likers_for_question_id(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, fname, lname
      FROM
        question_likes
        JOIN users ON question_likes.user_id = users.id
      WHERE
        question_id = ?
    SQL
    return nil unless likes.length > 0

    likes.map{|user| User.new(user)}
  end

  def self.num_likes_for_question_id(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(users.id) AS 'count'
      FROM
        question_likes
        JOIN users ON question_likes.user_id = users.id
      WHERE
        question_id = ?
    SQL
    return nil unless likes.length > 0
    likes.first['count']
  end

  def self.liked_questions_for_user_id(user_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, title, body, questions.user_id
      FROM
        question_likes
        JOIN questions ON questions.id = question_id
      WHERE
        question_likes.user_id = ?
    SQL
    return nil unless likes.length > 0

    likes.map{|question| Question.new(question)}
  end

  def self.most_liked_questions(n)
    likes = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, title, body, questions.user_id
      FROM
        questions
        JOIN question_likes ON questions.id = question_likes.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_likes.user_id) DESC
      LIMIT
        ?
    SQL
    return nil unless likes.length > 0

    likes.map{|like| Question.new(like)}
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end
