CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Ryan', 'Mora'),
  ('Grey', 'Keith');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('Life', "What doth life?", (SELECT id FROM users WHERE fname = 'Ryan')),
  ('How do you know?', "How do you really know if that's what it's for?", (SELECT id FROM users WHERE fname = 'Grey'));

INSERT INTO
  question_follows (question_id, user_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'Life'),(SELECT id FROM users WHERE fname = 'Ryan')),
  ((SELECT id FROM questions WHERE title = 'How do you know?'),(SELECT id FROM users WHERE fname = 'Grey')),
  ((SELECT id FROM questions WHERE title = 'Life'),(SELECT id FROM users WHERE fname = 'Grey'));

INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'Life'),
  NULL,
  (SELECT id FROM users WHERE fname = 'Grey'),
  'Can we really even know?'),

  ((SELECT id FROM questions WHERE title = 'Life'),
  1,
  (SELECT id FROM users WHERE fname = 'Ryan'),
  'Yes');

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Ryan'), (SELECT id FROM questions WHERE title = 'How do you know?'));
