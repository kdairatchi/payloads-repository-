#!/bin/bash

echo "===== Automated GitHub Payload Repository Setup ====="

# Ask for user input to clone their GitHub repository
echo -n "Enter your GitHub repository URL (e.g., https://github.com/yourusername/yourrepository.git): "
read REPO_URL

# Clone the GitHub repository
echo "Cloning the repository..."
git clone $REPO_URL

# Extract repository name from URL
REPO_NAME=$(basename "$REPO_URL" .git)
cd "$REPO_NAME" || { echo "Error: Failed to enter repository directory."; exit 1; }

# Create a Python virtual environment
echo "Setting up a Python virtual environment..."
python3 -m venv env

# Activate the virtual environment
source env/bin/activate

# Install required Python packages
echo "Installing required Python dependencies..."
pip install requests beautifulsoup4 PyGithub

# Create Python script to scrape payloads and update the GitHub repo
PYTHON_SCRIPT="update_payloads.py"

cat <<EOF >$PYTHON_SCRIPT
import os
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from github import Github

# Replace with your GitHub token
GITHUB_TOKEN = "YOUR_GITHUB_TOKEN"
REPO_NAME = "$REPO_NAME"  # Repository name from Bash script
PAYLOAD_FILE = "payloads.txt"
EXPLANATION_FILE = "explanations.txt"

# GitHub setup
g = Github(GITHUB_TOKEN)
repo = g.get_repo(REPO_NAME)

def scrape_payloads():
    payloads = []
    explanations = []

    sources = [
        "https://portswigger.net/web-security",
    ]

    try:
        for source in sources:
            response = requests.get(source)
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                articles = soup.find_all('a', class_='Article-link')

                for article in articles:
                    payload_title = article.text.strip()
                    payload_link = "https://portswigger.net" + article['href']
                    payloads.append(payload_title)
                    explanations.append(f"{payload_title}\\nURL: {payload_link}\\n")

        return payloads, explanations

    except requests.RequestException as e:
        print(f"Error scraping data: {e}")
        return [], []

def write_to_files(payloads, explanations):
    with open(PAYLOAD_FILE, "w") as payload_file:
        payload_file.write("\\n".join(payloads))

    with open(EXPLANATION_FILE, "w") as explanation_file:
        explanation_file.write("\\n\\n".join(explanations))

def update_github_repo():
    try:
        with open(PAYLOAD_FILE, "r") as payload_file:
            payload_content = payload_file.read()
        with open(EXPLANATION_FILE, "r") as explanation_file:
            explanation_content = explanation_file.read()

        try:
            payloads_file = repo.get_contents(PAYLOAD_FILE)
            repo.update_file(
                payloads_file.path,
                f"Updated payloads on {datetime.now().strftime('%Y-%m-%d')}",
                payload_content,
                payloads_file.sha,
            )
        except:
            repo.create_file(
                PAYLOAD_FILE,
                f"Created payloads file on {datetime.now().strftime('%Y-%m-%d')}",
                payload_content,
            )

        try:
            explanation_file = repo.get_contents(EXPLANATION_FILE)
            repo.update_file(
                explanation_file.path,
                f"Updated explanations on {datetime.now().strftime('%Y-%m-%d')}",
                explanation_content,
                explanation_file.sha,
            )
        except:
            repo.create_file(
                EXPLANATION_FILE,
                f"Created explanations file on {datetime.now().strftime('%Y-%m-%d')}",
                explanation_content,
            )

        print("GitHub repository updated successfully.")

    except Exception as e:
        print(f"Failed to update GitHub repository: {e}")

def main():
    payloads, explanations = scrape_payloads()
    if payloads and explanations:
        write_to_files(payloads, explanations)
        update_github_repo()
    else:
        print("No payloads found to update.")

if __name__ == "__main__":
    main()
EOF

# Ask for GitHub token to replace in the script
echo -n "Enter your GitHub personal access token: "
read GITHUB_TOKEN

# Replace placeholder in Python script with actual GitHub token
sed -i "s/YOUR_GITHUB_TOKEN/$GITHUB_TOKEN/g" $PYTHON_SCRIPT

# Run the Python script once to test setup
echo "Running the Python script to scrape and update payloads..."
python3 $PYTHON_SCRIPT

# Add a cron job to run the script daily
CRON_JOB="0 0 * * * cd $(pwd) && source env/bin/activate && python3 $PYTHON_SCRIPT >> cron_log.txt 2>&1"

# Check if the cron job already exists, if not, add it
(crontab -l 2>/dev/null | grep -Fxq "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "The script has been successfully set up. It will run daily at midnight to update the payloads."
echo "Check the repository ($REPO_NAME) for daily updates!"
