"""Secure command runner for SetupOpenClaw installer"""
import subprocess
import os
from typing import Tuple, List

INSTALLER_PATH = "/root/setup-openclaw/installer/install.sh"
ALLOWED_ACTIONS = ["install", "update", "proxy", "webauth", "ufw", "status", "uninstall"]

def validate_action(action: str) -> bool:
    """Validate that action is allowed"""
    return action in ALLOWED_ACTIONS

def run_installer_action(action: str) -> Tuple[int, str, str]:
    """
    Run installer with specified action
    Returns: (exit_code, stdout, stderr)
    """
    if not validate_action(action):
        return (1, "", f"Invalid action: {action}")
    
    if not os.path.exists(INSTALLER_PATH):
        return (1, "", f"Installer not found: {INSTALLER_PATH}")
    
    if not os.access(INSTALLER_PATH, os.X_OK):
        return (1, "", f"Installer not executable: {INSTALLER_PATH}")
    
    # Build command (no shell=True for security)
    cmd = ["/bin/bash", INSTALLER_PATH, "--action", action]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=600,  # 10 minutes max
            env=os.environ.copy()
        )
        
        return (result.returncode, result.stdout, result.stderr)
    
    except subprocess.TimeoutExpired:
        return (1, "", "Command timed out after 10 minutes")
    
    except Exception as e:
        return (1, "", f"Error executing command: {str(e)}")

def get_openclaw_status() -> dict:
    """Get current OpenClaw status"""
    exit_code, stdout, stderr = run_installer_action("status")
    
    return {
        "success": exit_code == 0,
        "output": stdout,
        "error": stderr
    }

def get_installer_log() -> str:
    """Read last 100 lines of installer log"""
    log_file = "/var/log/setup-openclaw/install.log"
    
    if not os.path.exists(log_file):
        return "Log file not found"
    
    try:
        with open(log_file, 'r') as f:
            lines = f.readlines()
            return ''.join(lines[-100:])  # Last 100 lines
    except Exception as e:
        return f"Error reading log: {str(e)}"
