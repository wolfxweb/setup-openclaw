"""SetupOpenClaw Web Panel - FastAPI Application"""
from fastapi import FastAPI, Request, Form, Depends, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware
import os

from .auth import verify_credentials, is_authenticated, require_auth
from .runner import run_installer_action, get_openclaw_status, get_installer_log, ALLOWED_ACTIONS

app = FastAPI(title="SetupOpenClaw Panel", version="1.0.0")

# Session middleware
SECRET_KEY = os.getenv("SECRET_KEY", "changeme-in-production-please")
app.add_middleware(SessionMiddleware, secret_key=SECRET_KEY)

# Templates
templates = Jinja2Templates(directory="/app/app/templates")

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Root redirect to dashboard or login"""
    if is_authenticated(request):
        return RedirectResponse(url="/dashboard", status_code=302)
    return RedirectResponse(url="/login", status_code=302)

@app.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    """Login page"""
    if is_authenticated(request):
        return RedirectResponse(url="/dashboard", status_code=302)
    return templates.TemplateResponse("login.html", {"request": request})

@app.post("/login")
async def login(request: Request, username: str = Form(...), password: str = Form(...)):
    """Handle login"""
    if verify_credentials(username, password):
        request.session["user"] = username
        return RedirectResponse(url="/dashboard", status_code=302)
    
    return templates.TemplateResponse(
        "login.html",
        {"request": request, "error": "Invalid credentials"}
    )

@app.get("/logout")
async def logout(request: Request):
    """Logout"""
    request.session.clear()
    return RedirectResponse(url="/login", status_code=302)

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request, user: str = Depends(require_auth)):
    """Main dashboard"""
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
    """Execute installer action"""
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
    """Health check"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
