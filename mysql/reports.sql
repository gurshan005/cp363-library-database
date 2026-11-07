-- Catalogue and publishers
SELECT
  b.title AS 'Book Title',
  p.name AS 'Publisher'
FROM Book b
JOIN Publisher p ON b.publisher_id = p.publisher_id;

-- Members with a loan
SELECT
  m.member_id,
  m.first_name,
  m.last_name,
  m.email
FROM `Member` m
WHERE m.member_id IN (SELECT l.member_id FROM Loan l);

-- Books per author
SELECT
  a.author_id,
  CONCAT(a.first_name, ' ', a.last_name) AS 'Author',
  COUNT(ba.book_id) AS 'Number of Books'
FROM Author a
LEFT JOIN BookAuthor ba ON a.author_id = ba.author_id
GROUP BY a.author_id, a.first_name, a.last_name;

-- Most recent loan per member
SELECT
  m.member_id,
  m.first_name,
  m.last_name,
  (SELECT MAX(l.loan_date)
   FROM Loan l
   WHERE l.member_id = m.member_id) AS 'Last Loan Date'
FROM `Member` m;

-- Borrowed copies per title
SELECT
  b.book_id,
  b.title,
  (SELECT COUNT(*)
   FROM Copy c
   WHERE c.book_id = b.book_id AND c.status = 'Borrowed') AS 'Borrowed Copies'
FROM Book b;

-- Rank by page count
SELECT
  book_id,
  title,
  pages,
  RANK() OVER (ORDER BY pages DESC) AS 'PageRank'
FROM Book;

-- Page count buckets
SELECT
  book_id,
  title,
  pages,
  NTILE(2) OVER (ORDER BY pages DESC, book_id) AS 'PageGroup'
FROM Book;

-- Loan recency per member
SELECT
  loan_id,
  member_id,
  loan_date,
  ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY loan_date DESC, loan_id DESC) AS 'LoanOrder'
FROM Loan;

-- Available copies per branch
SELECT
  lb.branch_id,
  lb.branch_name,
  (SELECT COUNT(*)
   FROM Copy c
   WHERE c.branch_id = lb.branch_id AND c.status = 'Available') AS 'Available Copies'
FROM LibraryBranch lb;

-- Loans handled per staff member
SELECT
  s.staff_id,
  CONCAT(s.first_name, ' ', s.last_name) AS 'Staff Name',
  COUNT(l.loan_id) AS 'Loans Processed'
FROM Staff s
LEFT JOIN Loan l ON s.staff_id = l.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY COUNT(l.loan_id) DESC;
