# CP363 Library Database

A relational database for a lending library. A title can have several authors and physical copies; each copy belongs to a branch, and every loan refers to a specific copy. That distinction lets the library answer two different questions: “How often has this title been borrowed?” and “Is there a copy available at this branch?”

The [MySQL project](mysql/) contains the 12-table schema, 17 reporting queries, and three reusable views. The [Python demo](demo/) is a standalone SQLite adaptation with a searchable catalogue, a Tkinter interface, and synthetic circulation records. It runs locally without a server, account, or external package.

## Try the demo

From the repository root, with Python 3.8+ and SQLite 3.25+:

```sh
python3 demo/app.py search --title atlas
python3 demo/app.py report branches
python3 demo/app.py report catalogue
python3 -m unittest discover -s demo -v
```

The branch report shows three copies at Lantern Quay, one checked-out copy and one under repair at Copper Canopy, and zero copies at Mirror Loft. Returning a copy changes its availability; the catalogue keeps counting its past loans.

To add a title and keep it between runs:

```sh
python3 demo/app.py --db library.sqlite3 add --title 'Paper Signals' --isbn DEMO-SIGNALS --year 2025 --publisher 1 --pages 220
python3 demo/app.py --db library.sqlite3 search --isbn DEMO-SIGNALS
```

For the desktop interface, run `python3 demo/gui.py --db library.sqlite3` with a Python installation that includes Tk. Search by title, ISBN or year, or use **Add book**. Omitting `--db` opens a temporary, in-memory catalogue.

## Explore the MySQL project

Use MySQL 8 or later. Create a **new, empty database** for the example, select it in your MySQL client, and run these commands from the repository root:

```sql
SOURCE mysql/schema.sql;
SOURCE mysql/sample_data.sql;
SOURCE mysql/views.sql;
SOURCE mysql/reports.sql;
SOURCE mysql/advanced_reports.sql;
```

| File | What to look for |
| --- | --- |
| [Schema](mysql/schema.sql) | Twelve tables and thirteen distinct foreign keys. Composite keys keep author credits, publisher offices and member phone entries separate from the main records. |
| [Catalogue reports](mysql/reports.sql) | Ten queries, including correlated subqueries, ranking books with `RANK`, and ordering each member’s loans with `ROW_NUMBER`. |
| [Advanced reports](mysql/advanced_reports.sql) | Seven examples, including members with overdue loans or no borrowing history, the five most-borrowed titles, and branches with above-average circulation. |
| [Views](mysql/views.sql) | Book/publisher detail, member loan totals, and branch inventory. Left joins retain members and branches with no activity. |

The MySQL version records the copy’s status explicitly. The SQLite demo derives availability from open loans and repair status, prevents two open loans on one copy, and uses an anonymous contact preference instead of a phone number. The two editions use separate fictional datasets.
