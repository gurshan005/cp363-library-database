-- Reusable MySQL reporting views.

CREATE OR REPLACE VIEW ViewBooksWithPublisher AS
SELECT
  b.book_id,
  b.title,
  b.isbn,
  b.publication_year,
  YEAR(CURDATE()) - b.publication_year AS Years_Since_Publication,
  p.name AS Publisher
FROM Book b
JOIN Publisher p ON b.publisher_id = p.publisher_id
ORDER BY b.title;

CREATE OR REPLACE VIEW ViewMemberLoanSummary AS
SELECT
  m.member_id,
  CONCAT(m.first_name, ' ', m.last_name) AS Member_Name,
  COUNT(l.loan_id) AS Total_Loans,
  MAX(l.loan_date) AS Last_Loan_Date
FROM `Member` m
LEFT JOIN Loan l ON m.member_id = l.member_id
GROUP BY m.member_id, m.first_name, m.last_name
ORDER BY Total_Loans DESC;

CREATE OR REPLACE VIEW ViewBranchCopyStatus AS
SELECT
  lb.branch_id,
  lb.branch_name,
  COUNT(c.copy_id) AS Total_Copies,
  SUM(CASE WHEN c.status = 'Available' THEN 1 ELSE 0 END) AS Available_Copies,
  SUM(CASE WHEN c.status = 'Borrowed' THEN 1 ELSE 0 END) AS Borrowed_Copies,
  SUM(CASE WHEN c.status = 'Maintenance' THEN 1 ELSE 0 END) AS Maintenance_Copies
FROM LibraryBranch lb
LEFT JOIN Copy c ON lb.branch_id = c.branch_id
GROUP BY lb.branch_id, lb.branch_name
ORDER BY lb.branch_name;
