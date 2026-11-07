-- Catalogue and contributors
CREATE TABLE publisher (
    publisher_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE CHECK (length(trim(name)) > 0)
);

CREATE TABLE publisher_office (
    publisher_id INTEGER NOT NULL REFERENCES publisher ON DELETE CASCADE,
    office_label TEXT NOT NULL CHECK (length(trim(office_label)) > 0),
    PRIMARY KEY (publisher_id, office_label)
);

CREATE TABLE book (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL CHECK (length(trim(title)) > 0),
    isbn TEXT NOT NULL UNIQUE CHECK (length(isbn) > 0 AND isbn = trim(isbn)),
    publication_year INTEGER NOT NULL
        CHECK (typeof(publication_year) = 'integer' AND publication_year BETWEEN 1 AND 9999),
    publisher_id INTEGER NOT NULL REFERENCES publisher,
    pages INTEGER CHECK (pages IS NULL OR (typeof(pages) = 'integer' AND pages > 0))
);

CREATE TABLE author (
    author_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0)
);

CREATE TABLE book_author (
    book_id INTEGER NOT NULL REFERENCES book ON DELETE CASCADE,
    author_id INTEGER NOT NULL REFERENCES author ON DELETE CASCADE,
    PRIMARY KEY (book_id, author_id)
);

-- Stock and participants
CREATE TABLE branch (
    branch_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE CHECK (length(trim(name)) > 0)
);

CREATE TABLE copy (
    copy_id INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES book,
    branch_id INTEGER NOT NULL REFERENCES branch,
    in_repair INTEGER NOT NULL DEFAULT 0 CHECK (in_repair IN (0, 1))
);

CREATE TABLE member (
    member_id INTEGER PRIMARY KEY,
    label TEXT NOT NULL UNIQUE CHECK (length(trim(label)) > 0)
);

-- Model a member's contact preferences without storing contact details.
CREATE TABLE member_contact (
    member_id INTEGER NOT NULL REFERENCES member ON DELETE CASCADE,
    channel TEXT NOT NULL CHECK (length(trim(channel)) > 0),
    PRIMARY KEY (member_id, channel)
);

CREATE TABLE staff (
    staff_id INTEGER PRIMARY KEY,
    label TEXT NOT NULL UNIQUE CHECK (length(trim(label)) > 0),
    branch_id INTEGER NOT NULL REFERENCES branch,
    role TEXT NOT NULL CHECK (role IN ('librarian', 'assistant', 'manager'))
);

-- Store calendar dates as ISO text so date comparisons are chronological.
CREATE TABLE loan (
    loan_id INTEGER PRIMARY KEY,
    copy_id INTEGER NOT NULL REFERENCES copy,
    member_id INTEGER NOT NULL REFERENCES member,
    staff_id INTEGER REFERENCES staff ON DELETE SET NULL,
    loan_date TEXT NOT NULL CHECK (date(loan_date, '+0 days') IS loan_date),
    due_date TEXT NOT NULL CHECK (date(due_date, '+0 days') IS due_date AND due_date >= loan_date),
    return_date TEXT CHECK (return_date IS NULL OR
        (date(return_date, '+0 days') IS return_date AND return_date >= loan_date))
);

CREATE UNIQUE INDEX one_open_loan_per_copy ON loan (copy_id) WHERE return_date IS NULL;

CREATE TRIGGER check_copy_on_checkout
BEFORE INSERT ON loan
WHEN NEW.return_date IS NULL AND (SELECT in_repair FROM copy WHERE copy_id = NEW.copy_id) = 1
BEGIN
    SELECT RAISE(ABORT, 'A copy under repair cannot be checked out');
END;

CREATE TRIGGER check_copy_on_loan_change
BEFORE UPDATE OF copy_id, return_date ON loan
WHEN NEW.return_date IS NULL AND (SELECT in_repair FROM copy WHERE copy_id = NEW.copy_id) = 1
BEGIN
    SELECT RAISE(ABORT, 'A copy under repair cannot be checked out');
END;

CREATE TRIGGER check_copy_before_repair
BEFORE UPDATE OF in_repair ON copy
WHEN NEW.in_repair = 1 AND EXISTS (
    SELECT 1 FROM loan WHERE copy_id = NEW.copy_id AND return_date IS NULL
)
BEGIN
    SELECT RAISE(ABORT, 'Return the copy before placing it under repair');
END;

CREATE TABLE fine (
    fine_id INTEGER PRIMARY KEY,
    loan_id INTEGER NOT NULL REFERENCES loan ON DELETE CASCADE,
    staff_id INTEGER NOT NULL REFERENCES staff,
    amount_cents INTEGER NOT NULL CHECK (typeof(amount_cents) = 'integer' AND amount_cents > 0),
    issued_date TEXT NOT NULL CHECK (date(issued_date, '+0 days') IS issued_date),
    paid_date TEXT CHECK (paid_date IS NULL OR
        (date(paid_date, '+0 days') IS paid_date AND paid_date >= issued_date))
);
