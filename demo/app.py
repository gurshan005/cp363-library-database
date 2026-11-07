"""Search a library catalog and run circulation reports using SQLite."""

import argparse
import csv
from pathlib import Path
import sqlite3
import sys

ROOT = Path(__file__).resolve().parent
APP_ID = 0x4C494244
REPORTS = {
    "catalogue": "SELECT * FROM catalogue ORDER BY circulation_rank, title, book_id",
    "branches": "SELECT * FROM branch_availability ORDER BY branch_id",
    "members": "SELECT * FROM member_activity ORDER BY member_id",
}


def open_library(path=":memory:"):
    db = sqlite3.connect(path)
    try:
        db.execute("PRAGMA foreign_keys = ON")
        if db.execute("PRAGMA application_id").fetchone()[0] == APP_ID:
            return db

        # Recheck under the write lock in case another process initialized it.
        db.execute("BEGIN IMMEDIATE")
        if db.execute("PRAGMA application_id").fetchone()[0] != APP_ID:
            if db.execute("SELECT 1 FROM sqlite_master LIMIT 1").fetchone():
                raise ValueError("Choose an empty file or an existing library demo database.")
            if db.execute("PRAGMA application_id").fetchone()[0]:
                raise ValueError("This file belongs to a different application.")
            for name in ("schema.sql", "sample_data.sql", "reports.sql"):
                # executescript commits before running. Execute each complete statement
                # here so that schema, example data, and reports share one transaction.
                pending = ""
                for chunk in (ROOT / name).read_text(encoding="utf-8").split(";"):
                    pending += chunk + ";"
                    if sqlite3.complete_statement(pending):
                        db.execute(pending)
                        pending = ""
                if pending.strip():
                    db.execute(pending)
            db.execute(f"PRAGMA application_id = {APP_ID}")
        db.commit()
        return db
    except Exception:
        db.close()
        raise


def search_books(db, title="", isbn="", year=None):
    return db.execute(
        """
        SELECT b.title, b.isbn, b.publication_year, p.name AS publisher, b.pages
          FROM book AS b
          JOIN publisher AS p ON b.publisher_id = p.publisher_id
         WHERE instr(lower(b.title), lower(?)) > 0
           AND (? = '' OR b.isbn = ?)
           AND (? IS NULL OR b.publication_year = ?)
         ORDER BY b.title, b.isbn
        """,
        (title.strip(), isbn.strip(), isbn.strip(), year, year),
    )


def add_book(db, title, isbn, year, publisher, pages=None):
    title, isbn = title.strip(), isbn.strip()
    if not title or not isbn:
        raise ValueError("Enter a title and an ISBN.")
    if not 1 <= year <= 9999 or (pages is not None and pages < 1):
        raise ValueError("Enter a year from 1 to 9999 and a positive page count.")
    with db:
        db.execute(
            """INSERT INTO book (title, isbn, publication_year, publisher_id, pages)
               VALUES (?, ?, ?, ?, ?)""",
            (title, isbn, year, publisher, pages),
        )


def publishers(db):
    return db.execute("SELECT publisher_id, name FROM publisher ORDER BY name")


def print_rows(cursor):
    output = csv.writer(sys.stdout, delimiter="\t", lineterminator="\n")
    output.writerow(column[0] for column in cursor.description)
    output.writerows(cursor)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default=":memory:", metavar="FILE",
                        help="use a local database file (default: in-memory demo)")
    commands = parser.add_subparsers(dest="command", required=True)
    search = commands.add_parser("search", help="search the catalog or list all books")
    search.add_argument("--title", default="", help="literal title substring")
    search.add_argument("--isbn", "--key", default="", help="exact catalog ISBN")
    search.add_argument("--year", type=int, help="exact publication year")
    insert = commands.add_parser("add", help="add a title to a persistent catalog")
    insert.add_argument("--title", required=True)
    insert.add_argument("--isbn", "--key", required=True)
    insert.add_argument("--year", required=True, type=int)
    insert.add_argument("--publisher", required=True, type=int, help="publisher ID")
    insert.add_argument("--pages", type=int)
    commands.add_parser("publishers", help="list the available publisher IDs")
    report = commands.add_parser("report", help="display a circulation report")
    report.add_argument("name", choices=REPORTS)
    args = parser.parse_args()
    if args.command == "add" and args.db == ":memory:":
        parser.error("Supply --db FILE before add so the new book is saved.")

    try:
        db = open_library(args.db)
        try:
            if args.command == "search":
                print_rows(search_books(db, args.title, args.isbn, args.year))
            elif args.command == "add":
                add_book(db, args.title, args.isbn, args.year, args.publisher, args.pages)
                print("Added:", args.title.strip())
            elif args.command == "publishers":
                print_rows(publishers(db))
            else:
                print_rows(db.execute(REPORTS[args.name]))
        finally:
            db.close()
    except (OSError, ValueError, OverflowError, sqlite3.Error) as exc:
        parser.exit(1, f"Library: {exc}\n")


if __name__ == "__main__":
    main()
