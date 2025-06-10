#!/bin/bash

set -e

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

echo "Updating Homebrew..."
brew update

# Docker
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  brew install --cask docker
else
  echo "Docker is already installed."
fi

# Docker Compose (included with Docker Desktop, but also available as a separate package)
if ! command -v docker-compose &> /dev/null; then
  echo "Installing Docker Compose..."
  brew install docker-compose
else
  echo "Docker Compose is already installed."
fi

# Python 3.9+
PYTHON_VERSION=$(python3 -V 2>&1 | awk '{print $2}')
if python3 -c "import sys; exit(0) if sys.version_info >= (3,9) else exit(1)"; then
  echo "Python $PYTHON_VERSION is already installed."
else
  echo "Installing Python 3.9+ and pip..."
  brew install python
fi

echo "Ensuring pip is up to date..."
python3 -m pip install --upgrade pip

# Django
if python3 -m django --version &> /dev/null; then
  echo "Django is already installed."
else
  echo "Installing Django..."
  python3 -m pip install django
fi

echo "All tools installed successfully!"