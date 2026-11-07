-- Fictional catalogue entries and local demonstration records.
INSERT INTO publisher (publisher_id, name) VALUES
    (1, 'Folded Map Press'),
    (2, 'Glass Kite Editions');

INSERT INTO publisher_office (publisher_id, office_label) VALUES
    (1, 'Map Room'), (1, 'Chart Workshop'), (2, 'Kite Loft');

INSERT INTO book (book_id, title, isbn, publication_year, publisher_id, pages) VALUES
    (1, 'Atlas of Paper Harbors', '978-0-00-000001-9', 2020, 1, 224),
    (2, 'The Clockwork Orchard', '978-0-00-000002-6', 2022, 2, 176),
    (3, 'A Field Guide to Painted Tides', '978-0-00-000003-3', 2021, 1, 224),
    (4, 'Folding Bridges', '978-0-00-000004-0', 2023, 2, 144);

INSERT INTO author (author_id, name) VALUES
    (1, 'Mapmaking Studio'), (2, 'The Kite Collective'), (3, 'Folio Workshop');

INSERT INTO book_author (book_id, author_id) VALUES
    (1, 1), (1, 3), (2, 2), (3, 1), (4, 3);

INSERT INTO branch (branch_id, name) VALUES
    (1, 'Lantern Quay'), (2, 'Copper Canopy'), (3, 'Mirror Loft');

INSERT INTO copy (copy_id, book_id, branch_id, in_repair) VALUES
    (1, 1, 1, 0), (2, 1, 2, 0), (3, 2, 1, 0),
    (4, 3, 2, 1), (5, 3, 1, 0);

INSERT INTO member (member_id, label) VALUES
    (1, 'Reader Amber'), (2, 'Reader Blue'), (3, 'Reader Green');

INSERT INTO member_contact (member_id, channel) VALUES
    (1, 'pickup desk'), (1, 'catalogue inbox'), (2, 'catalogue inbox');

INSERT INTO staff (staff_id, label, branch_id, role) VALUES
    (1, 'Quay Desk', 1, 'librarian'), (2, 'Canopy Desk', 2, 'assistant');

INSERT INTO loan (loan_id, copy_id, member_id, staff_id, loan_date, due_date, return_date) VALUES
    (1, 1, 1, 1, '2025-03-01', '2025-03-15', '2025-03-18'),
    (2, 2, 2, 2, '2025-03-04', '2025-03-18', NULL),
    (3, 3, 1, 1, '2025-03-07', '2025-03-21', '2025-03-16'),
    (4, 1, 2, 1, '2025-03-21', '2025-04-04', '2025-03-27');

INSERT INTO fine (fine_id, loan_id, staff_id, amount_cents, issued_date, paid_date) VALUES
    (1, 1, 1, 150, '2025-03-18', '2025-03-20'),
    (2, 2, 2, 75, '2025-03-22', NULL);
