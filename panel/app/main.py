"""SetupOpenClaw Web Panel - FastAPI Application with Enhanced Security"""
from fastapi import FastAPI, Request, Form, Depends, HTTPException, status
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
import os
import secrets

from .auth import verify_credentials, is_authenticated, require_auth
from .runner import run_installer_action, get_openclaw_status, get_installer_log, ALLOWED_ACTIONS
from .security import (
    check_login_rate_limit, check_action_rate_limit,
    validate_password_strength, log_security_event,
    sanitize_input, SecurityError
)

app = FastAPI(title="SetupOpenClaw Panel", version="1.0.0")

# Generate secure secret key if not provided
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY or SECRET_KEY == "changeme-in-production-please":
    SECRET_KEY = secrets.token_urlsafe(32)
    print(f"⚠️  WARNING: Using auto-generated SECRET_KEY. Set SECRET_KEY env var for production!")

app.add_middleware(SessionMiddleware, secret_key=SECRET_KEY, max_age=3600)  # 1 hour session

templates = Jinja2Templates(directory="/app/app/templates")

def get_client_ip(request: Request) -> str:
    """Get client IP address"""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Root redirect"""
    if is_authenticated(request):
        return RedirectResponse(url="/dashboard", status_code=302)
    return RedirectResponse(url="/login", status_code=302)

@app.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    """Login page"""
    if is_authenticated(request):
        return RedirectResponse(url="/dashboard", status_code=302)
    
    # Check if IP is locked out
    client_ip = get_client_ip(request)
    allowed, unlock_in = check_login_rate_limit(client_ip)
    
    context = {"request": request}
    if not allowed:
        context["error"] = f"Too many failed attempts. Try again in {unlock_in} seconds."
    
    return templates.TemplateResponse("login.html", context)

@app.post("/login")
async def login(request: Request, username: str = Form(...), password: str = Form(...)):
    """Handle login with rate limiting"""
    client_ip = get_client_ip(request)
    
    # Check rate limit
    allowed, unlock_in = check_login_rate_limit(client_ip)
    if not allowed:
        log_security_event("LOGIN_BLOCKED", client_ip, f"Rate limited for {unlock_in}s")
        return templates.TemplateResponse(
            "login.html",
            {"request": request, "error": f"Too many attempts. Wait {unlock_in} seconds."}
        )
    
    # Sanitize inputs
    username = sanitize_input(username, 50)
    password = sanitize_input(password, 100)
    
    # Verify credentials
    if verify_credentials(username, password):
        request.session["user"] = username
        request.session["ip"] = client_ip
        log_security_event("LOGIN_SUCCESS", username, f"from {client_ip}")
        return RedirectResponse(url="/dashboard", status_code=302)
    
    log_security_event("LOGIN_FAILED", username, f"from {client_ip}")
    return templates.TemplateResponse(
        "login.html",
        {"request": request, "error": "Invalid credentials"}
    )

@app.get("/logout")
async def logout(request: Request):
    """Logout"""
    user = request.session.get("user", "unknown")
    log_security_event("LOGOUT", user)
    request.session.clear()
    return RedirectResponse(url="/login", status_code=302)

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request, user: str = Depends(require_auth)):
    """Main dashboard"""
    # Verify session IP hasn't changed
    session_ip = request.session.get("ip")
    current_ip = get_client_ip(request)
    
    if session_ip and session_ip != current_ip:
        log_security_event("SESSION_HIJACK_ATTEMPT", user, f"IP changed from {session_ip} to {current_ip}")
        request.session.clear()
        raise HTTPException(status_code=401, detail="Session invalid")
    
    return templates.TemplateResponse(
        "dashboard.html",
        {"request": request, "user": user, "actions": ALLOWED_ACTIONS}
    )

@app.post("/action/{action}")
async def execute_action(
    action: str,
    request: Request,
    user: str = Depends(require_auth)
):
    """Execute installer action with rate limiting"""
    # Sanitize action
    action = sanitize_input(action, 20)
    
    # Check action rate limit
    allowed, unlock_in = check_action_rate_limit(user, action)
    if not allowed:
        log_security_event("ACTION_BLOCKED", user, f"Rate limited: {action}")
        return JSONResponse({
            "success": False,
            "error": f"Too many requests. Wait {unlock_in} seconds."
        }, status_code=429)
    
    # Execute
    log_security_event("ACTION_EXECUTE", user, f"Running: {action}")
    exit_code, stdout, stderr = run_installer_action(action)
    
    return JSONResponse({
        "success": exit_code == 0,
        "action": action,
        "output": stdout,
        "error": stderr
    })

@app.get("/status")
async def status(request: Request, user: str = Depends(require_auth)):
    """Get OpenClaw status"""
    status_data = get_openclaw_status()
    return JSONResponse(status_data)

@app.get("/status-badge", response_class=HTMLResponse)
async def status_badge(request: Request, user: str = Depends(require_auth)):
    """HTMX endpoint for status badge"""
    status_data = get_openclaw_status()
    
    if status_data["success"] and "running" in status_data["output"].lower():
        badge_class = "bg-green-500"
        badge_text = "Online"
    else:
        badge_class = "bg-red-500"
        badge_text = "Offline"
    
    return templates.TemplateResponse(
        "partials/status.html",
        {"request": request, "badge_class": badge_class, "badge_text": badge_text}
    )

@app.get("/logs", response_class=HTMLResponse)
async def logs_page(request: Request, user: str = Depends(require_auth)):
    """Logs page"""
    log_content = get_installer_log()
    return templates.TemplateResponse(
        "logs.html",
        {"request": request, "log_content": log_content}
    )

@app.get("/health")
async def health():
    """Health check (no auth required)"""
    return {"status": "healthy"}

@app.on_event("startup")
async def startup_event():
    """Create security log on startup"""
    os.makedirs("/var/log/setup-openclaw", exist_ok=True)
    log_security_event("PANEL_STARTED", "system", "SetupOpenClaw panel started")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
