"""Security utilities for SetupOpenClaw panel"""
import time
import hashlib
import secrets
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Optional

# Rate limiting storage (in production, use Redis)
login_attempts = defaultdict(list)
action_attempts = defaultdict(list)

# Configuration
MAX_LOGIN_ATTEMPTS = 5
MAX_ACTION_ATTEMPTS = 10
LOCKOUT_DURATION = 300  # 5 minutes in seconds
MIN_PASSWORD_LENGTH = 12

class SecurityError(Exception):
    """Security-related error"""
    pass

def generate_secure_token(length: int = 32) -> str:
    """Generate cryptographically secure token"""
    return secrets.token_urlsafe(length)

def validate_password_strength(password: str) -> tuple[bool, str]:
    """
    Validate password meets security requirements
    Returns: (is_valid, error_message)
    """
    if len(password) < MIN_PASSWORD_LENGTH:
        return False, f"Password must be at least {MIN_PASSWORD_LENGTH} characters"
    
    if not any(c.isupper() for c in password):
        return False, "Password must contain at least one uppercase letter"
    
    if not any(c.islower() for c in password):
        return False, "Password must contain at least one lowercase letter"
    
    if not any(c.isdigit() for c in password):
        return False, "Password must contain at least one number"
    
    if not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
        return False, "Password must contain at least one special character"
    
    return True, ""

def check_rate_limit(identifier: str, max_attempts: int, window_seconds: int, 
                     storage: dict) -> tuple[bool, Optional[int]]:
    """
    Check if identifier has exceeded rate limit
    Returns: (is_allowed, seconds_until_unlock)
    """
    now = time.time()
    
    # Clean old attempts
    storage[identifier] = [t for t in storage[identifier] if now - t < window_seconds]
    
    # Check if locked out
    if len(storage[identifier]) >= max_attempts:
        oldest_attempt = min(storage[identifier])
        unlock_time = oldest_attempt + window_seconds
        if now < unlock_time:
            return False, int(unlock_time - now)
    
    # Record attempt
    storage[identifier].append(now)
    return True, None

def check_login_rate_limit(ip: str) -> tuple[bool, Optional[int]]:
    """Check login rate limit for IP address"""
    return check_rate_limit(ip, MAX_LOGIN_ATTEMPTS, LOCKOUT_DURATION, login_attempts)

def check_action_rate_limit(user: str, action: str) -> tuple[bool, Optional[int]]:
    """Check action rate limit for user"""
    identifier = f"{user}:{action}"
    return check_rate_limit(identifier, MAX_ACTION_ATTEMPTS, 60, action_attempts)

def sanitize_input(input_str: str, max_length: int = 100) -> str:
    """Sanitize user input"""
    # Remove null bytes and control characters
    sanitized = ''.join(c for c in input_str if c.isprintable())
    # Limit length
    return sanitized[:max_length]

def hash_identifier(identifier: str) -> str:
    """Hash identifier for privacy in logs"""
    return hashlib.sha256(identifier.encode()).hexdigest()[:16]

def log_security_event(event_type: str, identifier: str, details: str = ""):
    """Log security-related events"""
    timestamp = datetime.now().isoformat()
    hashed_id = hash_identifier(identifier)
    log_entry = f"[SECURITY] {timestamp} - {event_type} - ID:{hashed_id} - {details}\n"
    
    try:
        with open("/var/log/setup-openclaw/security.log", "a") as f:
            f.write(log_entry)
    except Exception:
        pass  # Fail silently for logging

def validate_session_token(token: str) -> bool:
    """Validate session token format"""
    if not token or len(token) < 32:
        return False
    return all(c.isalnum() or c in '-_' for c in token)
