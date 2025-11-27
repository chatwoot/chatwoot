#!/bin/bash

# Clean up any leftover Overmind socket
rm -f /workspace/.overmind.sock

# Start the development server
cd /workspace
pnpm dev
