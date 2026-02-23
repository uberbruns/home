"""Output formatting for bookmark listings."""


# --------------------------------------------------------------------------- #
# Output
# --------------------------------------------------------------------------- #

def print_formatted(bookmarks, delimiter, columns, max_path=0, max_url=0):
    """Print bookmarks with path and url truncated to fit terminal width."""
    path_limit = max_path if max_path > 0 else columns // 2

    for folder, title, url in bookmarks:
        # Build and truncate path
        path = _replace_delimiter(f"{folder}/{title}" if folder else title, delimiter)
        display_path = _truncate(path, path_limit)

        # Truncate url to remaining space
        url_limit = max_url if max_url > 0 else max(columns - len(display_path) - 2, 20)
        display_url = _truncate(url, url_limit)

        print(f"{display_path}  {display_url}")


def print_raw(bookmarks, delimiter):
    """Print bookmarks as tab-separated folder, title, and url."""
    for folder, title, url in bookmarks:
        print(f"{_replace_delimiter(folder, delimiter)}\t{title}\t{url}")


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

def _replace_delimiter(path, delimiter):
    """Replace internal / delimiter with the output delimiter."""
    return path.replace("/", delimiter) if delimiter != "/" else path


def _truncate(text, max_length):
    """Shorten text to max_length with trailing ellipsis."""
    if len(text) <= max_length:
        return text
    return text[:max_length - 1] + "…"
