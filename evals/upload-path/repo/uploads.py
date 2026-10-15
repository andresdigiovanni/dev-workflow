from pathlib import Path

UPLOAD_DIR = Path(__file__).parent / "uploads"


def list_uploads():
    """Names of the files in the uploads directory."""
    return sorted(p.name for p in UPLOAD_DIR.iterdir() if p.is_file())
