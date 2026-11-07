-- Catalogue entries stay visible even before a branch acquires a copy.
-- Count copies separately from loan records: the same copy can circulate many times.
CREATE VIEW catalogue AS
WITH circulation AS (
    SELECT c.book_id, COUNT(DISTINCT c.copy_id) AS copy_count, COUNT(l.loan_id) AS loan_count
    FROM copy AS c
    LEFT JOIN loan AS l ON l.copy_id = c.copy_id
    GROUP BY c.book_id
)
SELECT b.book_id, b.title, b.isbn, b.publication_year, b.publisher_id,
       p.name AS publisher, b.pages,
       COALESCE(c.copy_count, 0) AS copy_count,
       COALESCE(c.loan_count, 0) AS loan_count,
       DENSE_RANK() OVER (ORDER BY COALESCE(c.loan_count, 0) DESC) AS circulation_rank
FROM book AS b
JOIN publisher AS p ON p.publisher_id = b.publisher_id
LEFT JOIN circulation AS c ON c.book_id = b.book_id;

CREATE VIEW member_activity AS
SELECT m.member_id, m.label AS member_label, COUNT(l.loan_id) AS loan_count,
       COUNT(CASE WHEN l.return_date IS NULL THEN l.loan_id END) AS open_loan_count,
       MAX(l.loan_date) AS last_loan_date
FROM member AS m
LEFT JOIN loan AS l ON l.member_id = m.member_id
GROUP BY m.member_id, m.label;

-- An old, returned loan has no effect on current availability.
CREATE VIEW branch_availability AS
SELECT b.branch_id, b.name AS branch, COUNT(c.copy_id) AS total_copies,
       COUNT(CASE WHEN l.loan_id IS NULL AND c.in_repair = 0 THEN c.copy_id END)
           AS available_copies,
       COUNT(l.loan_id) AS checked_out_copies,
       COUNT(CASE WHEN l.loan_id IS NULL AND c.in_repair = 1 THEN c.copy_id END)
           AS repair_copies
FROM branch AS b
LEFT JOIN copy AS c ON c.branch_id = b.branch_id
LEFT JOIN loan AS l ON l.copy_id = c.copy_id AND l.return_date IS NULL
GROUP BY b.branch_id, b.name;
