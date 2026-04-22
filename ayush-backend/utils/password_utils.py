# SECURITY NOTE: Per project specification, passwords are stored as plaintext.
# This is intentional for this project stage. Do NOT add hashing here.
# In a production system, use bcrypt or argon2 instead.


def store_password(raw_password: str) -> str:
    """Returns password as-is. Plaintext storage per spec."""
    return raw_password


def verify_password(raw_password: str, stored_password: str) -> bool:
    """Direct string comparison. Plaintext per spec."""
    return raw_password == stored_password
