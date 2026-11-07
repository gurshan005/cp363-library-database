-- Invented catalogue entries for a fresh demo database. No real contacts.
START TRANSACTION;

INSERT INTO Publisher (publisher_id, name, country)
VALUES (1, 'Folded Map Press', 'Demo Region'), (2, 'Prism Editions', 'Demo Region');
INSERT INTO PublisherOffice (publisher_id, office_id, office_location)
VALUES (1, 1, 'Map Room');
INSERT INTO LibraryBranch (branch_id, branch_name, address)
VALUES (1, 'Lantern Hall', 'East Wing'), (2, 'Paper Harbor', 'West Wing'), (3, 'Annex', 'South Wing');

-- Local demo identifiers in the ISBN field; these are not assigned ISBNs.
INSERT INTO Book (book_id, title, isbn, publication_year, publisher_id, pages) VALUES
    (1, 'Atlas of Paper Harbors', 'DEMO-ATLAS', 2020, 1, 240),
    (2, 'An Index of Lanterns', 'DEMO-LANTERN', 2023, 1, 180),
    (3, 'The Glass Map', 'DEMO-GLASS', 2024, 2, 240);
INSERT INTO Author (author_id, first_name, last_name)
VALUES (1, 'Workshop', 'Amber'), (2, 'Workshop', 'Indigo');
INSERT INTO BookAuthor (book_id, author_id) VALUES (1, 1), (1, 2), (2, 1), (3, 2);
INSERT INTO Copy (copy_id, book_id, branch_id, status) VALUES
    (1, 1, 1, 'Borrowed'), (2, 1, 2, 'Available'),
    (3, 2, 1, 'Available'), (4, 3, 2, 'Maintenance');

INSERT INTO `Member` (member_id, first_name, last_name, email, date_joined) VALUES
    (1, 'Demo', 'Reader-A', 'reader-a@example.invalid', '2024-01-10'),
    (2, 'Demo', 'Reader-B', 'reader-b@example.invalid', '2024-02-01');
INSERT INTO MemberPhone (member_id, phone_number) VALUES (1, 'DEMO-CONTACT');
INSERT INTO Staff (staff_id, first_name, last_name, role, branch_id) VALUES
    (1, 'Demo', 'Desk-A', 'Librarian', 1), (2, 'Demo', 'Desk-B', 'Assistant', 2);
INSERT INTO Loan (loan_id, copy_id, member_id, loan_date, due_date, return_date, staff_id) VALUES
    (1, 3, 1, '2024-03-01', '2024-03-15', '2024-03-17', 1),
    (2, 1, 1, '2024-04-01', '2024-04-15', NULL, 1);
INSERT INTO Fine (fine_id, loan_id, amount, fine_date, paid_date, staff_id)
VALUES (1, 1, 1.00, '2024-03-17', '2024-03-18', 1);
COMMIT;
