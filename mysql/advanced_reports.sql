-- Members with Overdue Loans or No Loans
SELECT
  m.member_id,
  CONCAT(m.first_name, ' ', m.last_name) AS MemberName,
  'Overdue' AS Status
FROM `Member` m
JOIN Loan l ON m.member_id = l.member_id
WHERE l.due_date < CURDATE()
  AND l.return_date IS NULL

UNION

SELECT
  m.member_id,
  CONCAT(m.first_name, ' ', m.last_name) AS MemberName,
  'No Loans' AS Status
FROM `Member` m
WHERE m.member_id NOT IN (SELECT member_id FROM Loan);

-- Publisher Stats (Average, Min, Max Pages)
SELECT
  p.publisher_id,
  p.name AS Publisher,
  AVG(b.pages) AS AveragePages,
  MIN(b.pages) AS MinPages,
  MAX(b.pages) AS MaxPages
FROM Publisher p
JOIN Book b ON p.publisher_id = b.publisher_id
GROUP BY p.publisher_id, p.name;

-- Library Branch Loan Counts
SELECT
  lb.branch_id,
  lb.branch_name,
  COUNT(l.loan_id) AS TotalLoans
FROM LibraryBranch lb
LEFT JOIN Copy c ON lb.branch_id = c.branch_id
LEFT JOIN Loan l ON c.copy_id = l.copy_id
GROUP BY lb.branch_id, lb.branch_name;

-- Top 5 Books by Loan Count
SELECT
  b.book_id,
  b.title,
  COUNT(l.loan_id) AS LoanCount
FROM Book b
JOIN Copy c ON b.book_id = c.book_id
JOIN Loan l ON c.copy_id = l.copy_id
GROUP BY b.book_id, b.title
ORDER BY LoanCount DESC
LIMIT 5;

-- Authors with No Loans
SELECT
  a.author_id,
  CONCAT(a.first_name, ' ', a.last_name) AS Author
FROM Author a
WHERE a.author_id NOT IN (
  SELECT DISTINCT ba.author_id
  FROM BookAuthor ba
  JOIN Book b ON ba.book_id = b.book_id
  JOIN Copy c ON b.book_id = c.book_id
  JOIN Loan l ON c.copy_id = l.copy_id
);

-- Recursive Number Sequence (1 to 10)
WITH RECURSIVE NumberSequence AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM NumberSequence
    WHERE n < 10
)
SELECT * FROM NumberSequence;

-- Branches with Above-Average Loans
WITH BranchLoanCounts AS (
  SELECT
    lb.branch_id,
    lb.branch_name,
    COUNT(l.loan_id) AS LoanCount
  FROM LibraryBranch lb
  LEFT JOIN Copy c ON lb.branch_id = c.branch_id
  LEFT JOIN Loan l ON c.copy_id = l.copy_id
  GROUP BY lb.branch_id, lb.branch_name
)
SELECT branch_id, branch_name, LoanCount
FROM BranchLoanCounts
WHERE LoanCount > (SELECT AVG(LoanCount) FROM BranchLoanCounts);
