# GPG Commit Signing Guide

This guide walks you through setting up GPG commit signing for the build-tools repository.

## Why Sign Commits?

**Without GPG signing:**
```bash
# Anyone can impersonate you
git config user.name "YourName"
git config user.email "your@email.com"
git commit -m "Malicious commit"
# → Shows as "YourName" but NOT VERIFIED ⚠️
```

**With GPG signing:**
```bash
git commit -S -m "Legitimate commit"
# → Shows "Verified" badge on GitHub ✅
# → Cryptographic proof it's really you
```

## Prerequisites

- Git installed
- GitHub account
- GPG installed (check with `gpg --version`)

**Install GPG if needed:**
```bash
# macOS
brew install gnupg

# Ubuntu/Debian
sudo apt-get install gnupg

# Windows
# Download from https://gpg4win.org/
```

## Step 1: Generate GPG Key

### 1.1 Start GPG Key Generation

```bash
gpg --full-generate-key
```

### 1.2 Select Key Type

```
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection?
```

**Answer:** `1` (RSA and RSA)

### 1.3 Select Key Size

```
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072)
```

**Answer:** `4096` (maximum security)

### 1.4 Select Expiration

```
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
```

**Recommended:** `2y` (expires in 2 years - good security practice)
**Alternative:** `0` (no expiration - simpler but less secure)

### 1.5 Confirm

```
Is this correct? (y/N)
```

**Answer:** `y`

### 1.6 Enter User Information

```
Real name: Your Name
Email address: your@email.com
Comment: GitHub signing key
```

**Use the SAME email as your GitHub account!**

To check your GitHub email:
```bash
# Check current git config
git config user.email

# Or check on GitHub
# Settings > Emails > Primary email address
```

### 1.7 Set Passphrase

**IMPORTANT:** Choose a strong passphrase you'll remember!
- You'll need to enter it every time you commit (or use GPG agent caching)
- Store it in a password manager

## Step 2: Get Your GPG Key ID

```bash
gpg --list-secret-keys --keyid-format=long
```

**Output:**
```
/Users/you/.gnupg/secring.gpg
------------------------------------
sec   rsa4096/3AA5C34371567BD2 2025-11-07 [SC] [expires: 2027-11-07]
      ABC123DEF456GHI789JKL012MNO345PQR678STU9
uid                 [ultimate] Your Name <your@email.com>
ssb   rsa4096/42B317FD4BA89E7A 2025-11-07 [E] [expires: 2027-11-07]
```

**Your Key ID:** `3AA5C34371567BD2` (the part after `rsa4096/`)

## Step 3: Export Public Key

```bash
# Replace 3AA5C34371567BD2 with YOUR key ID
gpg --armor --export 3AA5C34371567BD2
```

**Output (copy everything including BEGIN/END lines):**
```
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGcM... (long base64 string)
...
-----END PGP PUBLIC KEY BLOCK-----
```

## Step 4: Add GPG Key to GitHub

### 4.1 Go to GitHub Settings

1. Open https://github.com/settings/keys
2. Click **"New GPG key"**

### 4.2 Paste Your Public Key

1. Paste the ENTIRE output from Step 3 (including BEGIN/END lines)
2. Click **"Add GPG key"**
3. Confirm with your GitHub password if prompted

### 4.3 Verify Email

GitHub will send a verification email if your GPG key email isn't already verified.

**IMPORTANT:** The email in your GPG key MUST match a verified email on GitHub!

## Step 5: Configure Git

### 5.1 Tell Git About Your Signing Key

```bash
# Replace with YOUR key ID from Step 2
git config --global user.signingkey 3AA5C34371567BD2
```

### 5.2 Enable Automatic Signing

```bash
# Sign all commits by default
git config --global commit.gpgsign true

# Sign all tags by default (optional)
git config --global tag.gpgsign true
```

### 5.3 Configure GPG Program (if needed)

```bash
# Usually not needed, but if Git can't find GPG:
git config --global gpg.program gpg
```

### 5.4 Verify Configuration

```bash
git config --global --list | grep -E '(signingkey|gpgsign)'
```

**Expected output:**
```
user.signingkey=3AA5C34371567BD2
commit.gpgsign=true
```

## Step 6: Test Signing

### 6.1 Create Test Commit

```bash
cd /path/to/build-tools
git commit --allow-empty -m "Test GPG signing"
```

**If prompted for passphrase:** Enter the passphrase you set in Step 1.6

### 6.2 Verify Signature Locally

```bash
git log --show-signature -1
```

**Expected output:**
```
commit abc123def456...
gpg: Signature made Thu Nov  7 10:00:00 2025 EST
gpg:                using RSA key ABC123...
gpg: Good signature from "Your Name <your@email.com>" [ultimate]
Author: Your Name <your@email.com>
Date:   Thu Nov 7 10:00:00 2025 -0500

    Test GPG signing
```

### 6.3 Push and Verify on GitHub

```bash
git push origin your-branch
```

1. Go to your commit on GitHub
2. Look for **"Verified"** badge next to your commit ✅

## Troubleshooting

### Problem: "gpg: signing failed: Inappropriate ioctl for device"

**Solution (macOS/Linux):**
```bash
export GPG_TTY=$(tty)

# Add to ~/.bashrc or ~/.zshrc to make permanent
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
```

### Problem: "gpg: signing failed: No secret key"

**Solution:** Wrong key ID configured
```bash
# List your keys again
gpg --list-secret-keys --keyid-format=long

# Update git config with correct key ID
git config --global user.signingkey YOUR_CORRECT_KEY_ID
```

### Problem: "gpg: skipped: No secret key"

**Solution:** Email mismatch between git and GPG key
```bash
# Check git email
git config user.email

# Check GPG key email
gpg --list-secret-keys

# They must match! Update git config:
git config --global user.email "email@matching.gpgkey"
```

### Problem: Passphrase prompt every commit

**Solution:** Enable GPG agent caching

**macOS:**
```bash
# Create GPG agent config
mkdir -p ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program /usr/local/bin/pinentry-mac
EOF

# Reload GPG agent
gpgconf --kill gpg-agent
```

**Linux:**
```bash
cat > ~/.gnupg/gpg-agent.conf <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
EOF

gpgconf --kill gpg-agent
```

**Explanation:**
- `default-cache-ttl 28800` = Cache passphrase for 8 hours
- `max-cache-ttl 86400` = Maximum 24 hours

### Problem: "Verified" badge not showing on GitHub

**Checklist:**
1. ✅ GPG key added to GitHub (Step 4)
2. ✅ Email in GPG key matches GitHub verified email
3. ✅ Commit signed locally (`git log --show-signature` shows "Good signature")
4. ✅ Key not expired (`gpg --list-keys` check expiration date)

### Problem: Need to sign old commits

**Warning:** This rewrites history - only do on feature branches!

```bash
# Sign last 3 commits
git rebase --exec 'git commit --amend --no-edit -n -S' -i HEAD~3

# Force push (use with caution!)
git push --force-with-lease
```

## Best Practices

### 1. Backup Your Private Key

```bash
# Export private key (keep this VERY secure!)
gpg --export-secret-keys --armor 3AA5C34371567BD2 > ~/gpg-private-key-backup.asc

# Store in password manager or encrypted drive
# NEVER commit this file to Git!
```

### 2. Key Rotation

```bash
# If your key is about to expire, extend it:
gpg --edit-key 3AA5C34371567BD2
gpg> expire
gpg> key 1
gpg> expire
gpg> save

# Then re-export and update on GitHub (Step 3-4)
```

### 3. Multiple Machines

To use the same GPG key on multiple computers:

**On original machine:**
```bash
# Export private key
gpg --export-secret-keys --armor 3AA5C34371567BD2 > private.key
```

**On new machine:**
```bash
# Import private key
gpg --import private.key

# Trust the key
gpg --edit-key 3AA5C34371567BD2
gpg> trust
gpg> 5 (ultimate trust)
gpg> quit

# Configure Git (Steps 5.1-5.2)
```

### 4. Verify Before Merging

When reviewing PRs, check for "Verified" badge:
- ✅ Verified = Commit authenticity confirmed
- ⚠️ Unverified = Could be legitimate, but can't verify

## Quick Reference

```bash
# Generate key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format=long

# Export public key (for GitHub)
gpg --armor --export KEY_ID

# Configure Git
git config --global user.signingkey KEY_ID
git config --global commit.gpgsign true

# Test
git commit --allow-empty -m "Test" -S
git log --show-signature -1

# Troubleshooting
export GPG_TTY=$(tty)
gpgconf --kill gpg-agent
```

## Additional Resources

- [GitHub: Managing commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification)
- [Git: Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [GPG Documentation](https://gnupg.org/documentation/)

## Support

Questions? Open an issue or contact tech@ontheshoulders.cc

---

**Last Updated:** 2025-11-07
**Tested On:** macOS (Apple Silicon), Ubuntu 22.04, Windows 11
