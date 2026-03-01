"""Authentication module for SetupOpenClaw panel"""
import os
from functools import wraps
from fastapi import Request, HTTPException, status
from fastapi.responses import RedirectResponse

def get_credentials():
    """Get admin credentials from environment"""
    username = os.getenv("PANEL_USER", "admin")
    password = os.getenv("PANEL_PASSWORD", "changeme")
    return username, password

def verify_credentials(username: str, password: str) -> bool:
    """Verify user credentials"""
    admin_user, admin_pass = get_credentials()
    return username == admin_user and password == admin_pass

def get_current_user(request: Request) -> str:
    """Get current logged-in user from session"""
    return request.session.get("user")

def is_authenticated(request: Request) -> bool:
    """Check if user is authenticated"""
    return get_current_user(request) is not None

def require_auth(request: Request):
    """Decorator/dependency to require authentication"""
    if not is_authenticated(request):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    return get_current_user(request)
