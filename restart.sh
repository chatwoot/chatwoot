# Command 1
echo "Removing webpack cache..."
rm -rf node_modules/.cache/

# Command 2
echo "Compiling assets..."
RAILS_ENV=production bin/rails assets:precompile

# Command 3
echo "Restarting chatwoot..."
sudo cwctl --restart

echo "Restart complete"