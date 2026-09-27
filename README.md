# Bash-CLI-Vault-Educational-Project-

A lightweight, interactive command-line credential manager written in Bash. This utility allows users to generate, store, retrieve, update, and audit encrypted key-value pairs directly from the terminal.

Disclaimer: This was developed as an educational shell-scripting project. It contains intentional design simplifications and security limitations (e.g., direct string interpolation and local key storage) and is not intended for production use.

Prerequisites

Ensure you have the following installed on your system:

- Bash (v4.0 or higher)
- OpenSSL
- SQLite3

  Use this line to install required libraries and software
  - Ubuntu / Debian:
  ```bash
  sudo apt update && sudo apt install sqlite3 openssl -y
