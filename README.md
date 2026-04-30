# Agent Farm Orchestrator

This repository serves as scaffolding for a project that leverages the Gemini CLI and GitHub Actions as an Agent orchestrator. It sets up an environment where specialized AI agents (Engineer, QA, PM, TPM, etc.) can autonomously manage the software development lifecycle across repositories.

## Prerequisites

Before getting started, ensure you have the following installed and configured:

- [GitHub CLI (`gh`)](https://cli.github.com/) - Authenticated with `gh auth login`.
- [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) - Authenticated with `gcloud auth login` and linked to an active GCP project.
- [Gemini CLI](https://github.com/google/gemini-cli) - Installed globally.

## Setup Instructions

### 1. Fork this Repository
Fork this repository to your own GitHub account or organization so you can run the GitHub Actions securely.

### 2. Configure Google Cloud Platform
To allow GitHub Actions to securely access your Google Cloud resources, we use Workload Identity Federation. This avoids the need for long-lived service account keys.

Run the following scripts from the root of this repository:

1. **Set up environment variables:**
   ```bash
   bash .github/scripts/setup-env.sh
   ```
   This script will prompt you for your GitHub org/repo and GCP project details, and then save them to a `.env` file.

2. **Enable required GCP services:**
   ```bash
   bash .github/scripts/enable-api.sh
   ```

3. **Configure Workload Identity Federation:**
   ```bash
   bash .github/scripts/enable-gh-actions.sh
   ```
   This script creates a service account, a Workload Identity Pool, and a Provider. It links your GitHub repository to the GCP service account.
   
   **Important:** At the end of this script, it will output variables like `GCP_WI_PROVIDER_ID`. Note these down, as you will need to add them as **Repository Variables** in your GitHub repository settings (`Settings` > `Secrets and variables` > `Actions`).

4. **Grant necessary IAM roles:**
   ```bash
   bash .github/scripts/enable-iam.sh
   ```
   This grants the required permissions to the service accounts used by GitHub Actions and Cloud Build.

### 3. Create a GitHub App (Bot Executor)
The automated workflows (QA, Engineer, Triage, PR Review, etc.) run headless in GitHub Actions. To allow these workflows to securely bypass branch protections, push code, and leave comments, you must configure a GitHub App.

> **Note on reusing apps:** While you *can* create a single "Agent Farm Bot" App and install it across multiple repositories in your organization (reusing the same `BOT_APP_ID` and `BOT_APP_PRIVATE_KEY` repository secrets), it is generally recommended to **create a dedicated App per organizational boundary or major project** to adhere to the Principle of Least Privilege.


1. **Create the App:**
   - Go to your GitHub **Settings > Developer settings > GitHub Apps** and click **New GitHub App**.
   - **Name:** e.g., `agent-farm-executor`
   - **Homepage URL:** (any valid URL, e.g., your repository URL)
   - **Webhook:** Disable "Active" (you don't need webhooks for this setup).

2. **Set Permissions:**
   Grant the app the following **Repository permissions**:
   - **Contents:** Read & write (to push commits)
   - **Issues:** Read & write (to comment and change labels)
   - **Pull requests:** Read & write (to create PRs and post reviews)
   - **Metadata:** Read-only (mandatory)

3. **Install and get Credentials:**
   - Click **Create GitHub App**.
   - On the App's settings page, note the **App ID**.
   - Scroll down to "Private keys" and click **Generate a private key**. This will download a `.pem` file.
   - Click **Install App** (in the left sidebar) and install it on your target repository.

4. **Add Secrets to your Repository:**
   Go to your repository's **Settings > Secrets and variables > Actions**, and add two **New repository secrets**:
   - `BOT_APP_ID`: The App ID you noted earlier.
   - `BOT_APP_PRIVATE_KEY`: The entire contents of the downloaded `.pem` file (including the `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines).

### 4. Link the Gemini CLI Extension
This repository includes a Gemini CLI extension (`agent-farm`) that adds specialized commands and subagents to your local environment.

To install the extension, navigate to the root of your forked repository and run:

```bash
gemini extensions link ./extensions/agent-farm
```

Make sure `experimental.enableAgents` is set to `true` in your `~/.gemini/settings.json`.

During the linking process, Gemini CLI may prompt you for a GitHub Personal Access Token (PAT) with repository permissions. This token powers the GitHub MCP server so agents can read and update issues and PRs.

## Usage

Once setup is complete, you can interact with the orchestration framework locally using the Gemini CLI:

- **Start Planning a Feature:** `/farm:pm create a new login page`
- **Refine Technical Plans:** `/farm:tpm <issue_number>`
- **View Agent Dashboard:** `/farm:status`
- **List Available Agents:** `/agents`

For more details on the specific capabilities and workflows of the extension, see the [Extension README](extensions/agent-farm/README.md).
