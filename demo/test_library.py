"""Check circulation reports against a small library with known loan history."""

from pathlib import Path
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parent


class LibraryTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)
        self.db.execute("PRAGMA foreign_keys = ON")
        for filename in ("schema.sql", "reports.sql"):
            self.db.executescript((ROOT / filename).read_text(encoding="utf-8"))

    def add_test_library(self):
        self.db.executescript("""
            INSERT INTO publisher(publisher_id, name) VALUES (1, 'Workshop Press');
            INSERT INTO branch(branch_id, name) VALUES (1, 'Workshop'), (2, 'Annex');
            INSERT INTO member(member_id, label) VALUES (1, 'Reader A'), (2, 'Reader B');
            INSERT INTO staff(staff_id, label, branch_id, role)
                VALUES (1, 'Desk A', 1, 'librarian');
            INSERT INTO book(book_id, title, isbn, publication_year, publisher_id, pages) VALUES
                (1, 'Paper Wheels', '9780000000002', 2025, 1, 40),
                (2, 'Open Circles', '9780000000019', 2020, 1, 62),
                (3, 'Quiet Shelves', '9780000000026', 2022, 1, 54);
            INSERT INTO copy(copy_id, book_id, branch_id, in_repair) VALUES
                (1, 1, 1, 0), (2, 1, 1, 0), (3, 2, 1, 1);
            INSERT INTO loan(loan_id, copy_id, member_id, staff_id, loan_date, due_date, return_date)
                VALUES (1, 1, 1, 1, '2025-01-02', '2025-01-16', '2025-01-14'),
                       (2, 1, 1, 1, '2025-02-02', '2025-02-16', NULL);
        """)

    def test_synthetic_sample_obeys_constraints(self):
        self.db.executescript((ROOT / "sample_data.sql").read_text(encoding="utf-8"))
        self.assertEqual(self.db.execute("PRAGMA integrity_check").fetchall(), [("ok",)])
        self.assertEqual(self.db.execute("PRAGMA foreign_key_check").fetchall(), [])
        self.assertGreater(self.db.execute("SELECT COUNT(*) FROM catalogue").fetchone()[0], 0)

    def test_title_rank_includes_ties_and_unstocked_books(self):
        self.add_test_library()
        rows = self.db.execute("""
            SELECT title, copy_count, loan_count, circulation_rank
            FROM catalogue ORDER BY book_id
        """).fetchall()
        self.assertEqual(rows, [
            ("Paper Wheels", 2, 2, 1), ("Open Circles", 1, 0, 2), ("Quiet Shelves", 0, 0, 2)
        ])

    def test_member_activity_includes_an_idle_reader(self):
        self.add_test_library()
        rows = self.db.execute("""
            SELECT member_label, loan_count, open_loan_count, last_loan_date
            FROM member_activity ORDER BY member_id
        """).fetchall()
        self.assertEqual(rows, [("Reader A", 2, 1, "2025-02-02"), ("Reader B", 0, 0, None)])

    def test_availability_changes_on_return(self):
        self.add_test_library()
        query = """
            SELECT total_copies, available_copies, checked_out_copies, repair_copies
            FROM branch_availability ORDER BY branch_id
        """
        self.assertEqual(self.db.execute(query).fetchall(), [(3, 1, 1, 1), (0, 0, 0, 0)])
        self.db.execute("UPDATE loan SET return_date = '2025-02-15' WHERE loan_id = 2")
        self.assertEqual(self.db.execute(query).fetchall(), [(3, 2, 0, 1), (0, 0, 0, 0)])

    def test_copy_cannot_have_two_open_loans(self):
        self.add_test_library()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("""
                INSERT INTO loan(copy_id, member_id, staff_id, loan_date, due_date)
                VALUES (1, 2, 1, '2025-02-03', '2025-02-17')
            """)

    def test_copy_must_reference_an_existing_book(self):
        self.add_test_library()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO copy(book_id, branch_id, in_repair) VALUES (999, 1, 0)")


if __name__ == "__main__":
    unittest.main()
