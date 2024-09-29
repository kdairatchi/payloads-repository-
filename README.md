# payloads-repository-
0 0 * * * /usr/bin/python3 /path/to/your/script.py




for github cli
"""
import subprocess

def update_github_cli():
    try:
        subprocess.run(["git", "add", PAYLOAD_FILE, EXPLANATION_FILE], check=True)
        subprocess.run(["git", "commit", "-m", "Automated payloads update"], check=True)
        subprocess.run(["git", "push"], check=True)
        print("GitHub repository updated successfully using GitHub CLI.")
    except subprocess.CalledProcessError as e:
        print(f"Error during GitHub update: {e}")

# Call this after writing to files
update_github_cli()
"""
