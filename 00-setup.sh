#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Array of script names
scripts=(
  "01-ssh.sh"
  "02-ufw.sh"
  "03-tuned.sh"
  "04-certbot.sh"
  "05-nginx.sh"
  "06-nvm.sh"
  "07-image.sh"
  "08-timezone.sh"
  "09-php.sh"
  "10-mysql.sh"
  "11-redis.sh"
  "12-aws.sh"
  "13-gh.sh"
  "14-backup.sh"
)

# Iterate over each script
for script in "${scripts[@]}"; do
  # Prompt for confirmation
  read -p "Do you want to execute $script? (y/n): " confirm
  case $confirm in
    [Yy]*)
      # Execute the script if confirmed
      ./$script
      ;;
    [Nn]*)
      # Skip the script if not confirmed
      echo "Skipping $script."
      ;;
    *)
      # Handle invalid input
      echo "Invalid input. Please enter 'y' or 'n'."
      ;;
  esac
done
