#!/bin/bash
# Script to generate SSH key pair and install public key for current user

# Generate SSH key pair (no passphrase, default path)
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# Install public key
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

echo "SSH key setup complete!"
