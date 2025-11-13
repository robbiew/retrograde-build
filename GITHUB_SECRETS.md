# GitHub Secrets Setup for External Binary Builds

This document explains how to configure GitHub secrets for the automated external binary build and upload process.

## Required Secrets

### `GITHUB_TOKEN` (Automatic)

GitHub automatically provides this secret with limited permissions. It works for:

- Reading public repositories
- Basic GitHub CLI operations
- Checking if releases exist

### `RETROGRADE_RELEASE_TOKEN` (Optional)

If you need to automatically upload binaries to the Retrograde BBS repository releases, you may need a personal access token with additional permissions.

## Setting Up Cross-Repository Access (Optional)

If the automatic `GITHUB_TOKEN` doesn't have sufficient permissions for uploading to the retrograde repository:

1. **Create a Personal Access Token (PAT):**
   - Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Create a new token with these permissions for the `robbiew/retrograde` repository:
     - Contents: Write (to upload release assets)
     - Metadata: Read
     - Pull requests: Read (if needed)

2. **Add the Secret:**
   - Go to your DockerBuilds repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `RETROGRADE_RELEASE_TOKEN`
   - Value: Your personal access token

3. **Update the Workflow (if needed):**
   - The workflow currently uses `GITHUB_TOKEN` as a fallback
   - You can modify it to prefer `RETROGRADE_RELEASE_TOKEN` if available

## Current Behavior

The workflow is configured to:

- ✅ Build binaries successfully regardless of token permissions
- ✅ Create and upload artifacts (always works)
- ⚠️ Upload to Retrograde releases only if token has permissions
- ⚠️ Gracefully handle missing or insufficient permissions

## Testing

You can test the workflow by:

1. Running it manually with workflow_dispatch
2. Checking the artifacts section of the workflow run
3. Verifying binaries are built correctly

The binaries will always be available as workflow artifacts even if the automatic upload fails.
