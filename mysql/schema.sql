-- Library catalogue and circulation schema. Run in a new, empty MySQL database.

CREATE TABLE IF NOT EXISTS Publisher (
    publisher_id INT AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    contact_email VARCHAR(50) UNIQUE,
    country VARCHAR(20) NOT NULL,
    PRIMARY KEY (publisher_id)
);

CREATE TABLE IF NOT EXISTS PublisherOffice (
    publisher_id INT NOT NULL,
    office_id INT NOT NULL,
    office_location VARCHAR(100) NOT NULL,
    PRIMARY KEY (publisher_id , office_id),
    FOREIGN KEY (publisher_id)
        REFERENCES Publisher (publisher_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS LibraryBranch (
    branch_id INT AUTO_INCREMENT,
    branch_name VARCHAR(50) NOT NULL,
    address VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    PRIMARY KEY (branch_id)
);

CREATE TABLE IF NOT EXISTS Book (
    book_id INT AUTO_INCREMENT,
    title VARCHAR(225) NOT NULL,
    isbn VARCHAR(20) NOT NULL,
    publication_year YEAR NOT NULL,
    publisher_id INT NOT NULL,
    pages INT,
    PRIMARY KEY (book_id),
    UNIQUE (isbn),
    FOREIGN KEY (publisher_id)
        REFERENCES Publisher (publisher_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Author (
    author_id INT AUTO_INCREMENT,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    birth_date DATE,
    PRIMARY KEY (author_id)
);

CREATE TABLE IF NOT EXISTS BookAuthor (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Book(book_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Author(author_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Copy (
    copy_id INT AUTO_INCREMENT,
    book_id INT NOT NULL,
    branch_id INT NOT NULL,
    status ENUM('Available', 'Borrowed', 'Maintenance') DEFAULT 'Available' NOT NULL,
    PRIMARY KEY (copy_id),
    FOREIGN KEY (book_id) REFERENCES Book (book_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (branch_id)
        REFERENCES LibraryBranch (branch_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `Member` (
    member_id INT AUTO_INCREMENT,
    first_name VARCHAR (25) NOT NULL,
    last_name VARCHAR (25) NOT NULL,
    email VARCHAR (50) NOT NULL,
    date_joined DATE NOT NULL,
    PRIMARY KEY (member_id),
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS MemberPhone (
    member_id INT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (member_id, phone_number),
    FOREIGN KEY (member_id) REFERENCES `Member`(member_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Staff (
staff_id INT AUTO_INCREMENT,
first_name VARCHAR(25) NOT NULL,
last_name VARCHAR(25) NOT NULL,
role ENUM('Librarian', 'Assistant' , 'Manager') NOT NULL,
branch_id INT NOT NULL,
email VARCHAR(50),
PRIMARY KEY (staff_id),
UNIQUE (email),
FOREIGN KEY (branch_id) REFERENCES LibraryBranch(branch_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Loan (
loan_id INT AUTO_INCREMENT,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    staff_id INT,
    PRIMARY KEY (loan_id),
    FOREIGN KEY (copy_id) REFERENCES Copy(copy_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (member_id) REFERENCES `Member`(member_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Fine (
    fine_id INT AUTO_INCREMENT,
    loan_id INT NOT NULL,
    amount DECIMAL(8,2) NOT NULL,
    fine_date DATE NOT NULL,
    paid_date DATE,
    staff_id INT NOT NULL,
    PRIMARY KEY (fine_id),
    FOREIGN KEY (loan_id) REFERENCES Loan(loan_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
