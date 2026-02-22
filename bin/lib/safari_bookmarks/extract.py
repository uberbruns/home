"""Bookmark extraction and filtering from Safari's Bookmarks.plist."""

import fnmatch
import os
import plistlib


PLIST_PATH = os.path.expanduser("~/Library/Safari/Bookmarks.plist")


# --------------------------------------------------------------------------- #
# Loading
# --------------------------------------------------------------------------- #

def load_plist():
    """Read and return the parsed Safari bookmarks plist."""
    with open(PLIST_PATH, "rb") as f:
        return plistlib.load(f)


# --------------------------------------------------------------------------- #
# Extraction
# --------------------------------------------------------------------------- #

def extract_bookmarks(node, folder=""):
    """Walk the bookmark tree, yielding (folder, title, url) tuples.

    Folder paths use / as the internal delimiter regardless of output format.
    """
    bookmark_type = node.get("WebBookmarkType", "")

    if bookmark_type == "WebBookmarkTypeList":
        title = node.get("Title", "")
        child_folder = f"{folder}/{title}" if folder else title
        for child in node.get("Children", []):
            yield from extract_bookmarks(child, child_folder)

    elif bookmark_type == "WebBookmarkTypeLeaf":
        url = node.get("URLString", "")
        if not url:
            return
        title = node.get("URIDictionary", {}).get("title", "") or url
        yield folder, title, url


# --------------------------------------------------------------------------- #
# Filtering
# --------------------------------------------------------------------------- #

def filter_bookmarks(bookmarks, root="", includes=None, excludes=None):
    """Filter bookmarks by root prefix and include/exclude glob patterns.

    - root: only yield bookmarks under this path prefix (stripped from output)
    - includes: path must match at least one pattern; OR semantics (default: all)
    - excludes: any match removes the bookmark; takes precedence over includes
    """
    root_prefix = root + "/" if root else ""

    for folder, title, url in bookmarks:
        path = f"{folder}/{title}" if folder else title

        # Skip bookmarks outside root
        if root and not path.startswith(root):
            continue

        # Strip root prefix from folder
        stripped_folder = _strip_root(folder, root, root_prefix)
        stripped_path = f"{stripped_folder}/{title}" if stripped_folder else title

        # Exclude takes precedence over include
        if excludes and any(fnmatch.fnmatch(stripped_path, p) for p in excludes):
            continue
        if includes and not any(fnmatch.fnmatch(stripped_path, p) for p in includes):
            continue

        yield stripped_folder, title, url


def _strip_root(folder, root, root_prefix):
    """Remove root prefix from a folder path."""
    if root_prefix and folder.startswith(root_prefix):
        return folder[len(root_prefix):]
    if root and folder == root:
        return ""
    return folder
