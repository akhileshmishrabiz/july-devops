Basic linux 


# Generate Ed25519 key
ssh-keygen -t ed25519 -C "user@example.com"

```bash
# Generate RSA key
ssh-keygen -t rsa -b 4096 -C "user@example.com"

# Copy public key to remote server
ssh-copy-id user@host

# Copy a specific key
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host

# Copy key using a custom port
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 user@host

# Test SSH login
ssh user@host

```