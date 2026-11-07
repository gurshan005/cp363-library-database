"""Search and edit a local library catalog in a Tkinter window."""

import argparse
from contextlib import closing
import sqlite3
try:
    from tkinter import TclError, Tk, StringVar, messagebox, ttk
except ImportError:
    raise SystemExit("The desktop app needs Tkinter. Use a Python build with Tk support, "
                     "or run python3 app.py search for the command-line demo.")

from app import add_book, open_library, publishers, search_books


def build_window(root, db):
    root.columnconfigure(0, weight=1)
    root.rowconfigure(0, weight=1)
    tabs = ttk.Notebook(root)
    tabs.grid(sticky="nsew", padx=12, pady=12)
    browse = ttk.Frame(tabs, padding=12)
    entry = ttk.Frame(tabs, padding=12)
    tabs.add(browse, text="Catalog")
    tabs.add(entry, text="Add book")
    browse.rowconfigure(2, weight=1)
    browse.columnconfigure(0, weight=1)

    def fields(parent, labels):
        values = []
        for row, label in enumerate(labels):
            value = StringVar(parent)
            ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", pady=3)
            ttk.Entry(parent, textvariable=value).grid(
                row=row, column=1, sticky="ew", padx=(12, 0), pady=3)
            values.append(value)
        parent.columnconfigure(1, weight=1)
        return values

    filters = ttk.Frame(browse)
    filters.grid(sticky="ew")
    title, isbn, year = fields(filters, ["Title contains", "ISBN", "Year"])
    result = ttk.Treeview(browse, columns=("title", "isbn", "year", "publisher", "pages"),
                          show="headings", height=12)
    for col, heading, width in (("title", "Title", 225), ("isbn", "ISBN", 150),
                                ("year", "Year", 65), ("publisher", "Publisher", 170),
                                ("pages", "Pages", 65)):
        result.heading(col, text=heading)
        result.column(col, width=width)
    result.grid(row=2, column=0, sticky="nsew")
    scrollbar = ttk.Scrollbar(browse, orient="vertical", command=result.yview)
    scrollbar.grid(row=2, column=1, sticky="ns")
    result.configure(yscrollcommand=scrollbar.set)
    status = StringVar(browse)
    ttk.Label(browse, textvariable=status).grid(row=3, column=0, sticky="w", pady=(6, 0))

    def search():
        try:
            pub_year = int(year.get()) if year.get().strip() else None
            rows = list(search_books(db, title.get(), isbn.get(), pub_year))
        except (ValueError, OverflowError, sqlite3.Error) as exc:
            messagebox.showerror("Search", str(exc), parent=root)
            return
        result.delete(*result.get_children())
        for row in rows:
            result.insert("", "end", values=["" if value is None else value for value in row])
        status.set(f"{len(rows)} matching title{'s' if len(rows) != 1 else ''}")

    ttk.Button(browse, text="Search", command=search).grid(row=1, column=0, sticky="w", pady=8)
    for widget in filters.winfo_children():
        if isinstance(widget, ttk.Entry):
            widget.bind("<Return>", lambda event: search())
    new_title, new_isbn, new_year, pages = fields(entry, ["Title", "ISBN", "Year", "Pages (optional)"])
    available = {name: publisher_id for publisher_id, name in publishers(db)}
    ttk.Label(entry, text="Publisher").grid(row=4, column=0, sticky="w", pady=3)
    publisher = ttk.Combobox(entry, state="readonly", values=list(available))
    publisher.grid(row=4, column=1, sticky="ew", padx=(12, 0), pady=3)
    if available:
        publisher.current(0)

    def save():
        try:
            year_value = int(new_year.get())
            page_count = int(pages.get()) if pages.get().strip() else None
            if publisher.get() not in available:
                raise ValueError("Choose a publisher.")
            add_book(db, new_title.get(), new_isbn.get(), year_value,
                     available[publisher.get()], page_count)
        except (ValueError, OverflowError, sqlite3.Error) as exc:
            messagebox.showerror("Add book", str(exc), parent=root)
            return
        title.set("")
        year.set("")
        isbn.set(new_isbn.get().strip())
        for value in (new_title, new_isbn, new_year, pages):
            value.set("")
        tabs.select(browse)
        search()

    ttk.Button(entry, text="Add book", command=save).grid(row=5, column=1, sticky="e", pady=12)
    search()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default=":memory:", metavar="FILE",
                        help="use a local database file (default: in-memory demo)")
    args = parser.parse_args()
    try:
        root = Tk()
        root.title("Library catalog" + (" · in-memory demo" if args.db == ":memory:" else ""))
        with closing(open_library(args.db)) as db:
            build_window(root, db)
            root.mainloop()
    except (OSError, ValueError, sqlite3.Error, TclError) as exc:
        parser.exit(1, f"Library: {exc}\n")


if __name__ == "__main__":
    main()
