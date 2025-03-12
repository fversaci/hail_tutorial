import hashlib
import random
import sys

# Step 1: Read the passphrase from stdin
passphrase = input("Enter passphrase: ")

# Constants
salt_len = 12

# Create a new SHA-256 hash object
h = hashlib.new('sha256')

# Generate a salt
salt = ("%0" + str(salt_len) + "x") % random.getrandbits(4 * salt_len)

# Update the hash object with the passphrase and salt
h.update(passphrase.encode("utf-8") + salt.encode("ascii"))

# Generate the new value in the form 'sha256:salt:hashed-password'
new_value = ":".join(('sha256', salt, h.hexdigest()))
print(new_value)

# Path to the configuration file
config_file_path = 'jupyter_lab_config.py'

# Read the existing configuration file
with open(config_file_path, 'r') as file:
    config_lines = file.readlines()

# Replace the existing password line with the new value
with open(config_file_path, 'w') as file:
    for line in config_lines:
        if line.strip().startswith("c.ServerApp.password"):
            file.write(f"c.ServerApp.password = '{new_value}'\n")
        else:
            file.write(line)
