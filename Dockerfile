# Start from the code-server Debian base image
FROM codercom/code-server:4.101.2-39

USER coder

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash

# Install basic packages first (including unzip for rclone)
RUN sudo dnf update -y && sudo dnf install -y \
gcc \
gcc-c++ \
make \
curl \
wget \
git \
vim \
nano \
htop \
tree \
jq \
unzip \
python3 \
python3-pip \
python3-devel \
&& sudo dnf clean all

# Install rclone (now that unzip is available)
RUN curl https://rclone.org/install.sh | sudo bash

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Create symbolic links for easier usage
RUN sudo ln -sf /usr/bin/python3 /usr/bin/python
RUN sudo ln -sf /usr/bin/pip3 /usr/bin/pip

# Install Node.js and npm (using NodeSource repository for latest LTS)
RUN curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
RUN sudo dnf install -y nodejs npm

# Fix permissions for code-server
RUN sudo chown -R coder:coder /home/coder/.local

# You can add custom software and dependencies for your environment below
# -----------

# Install a VS Code extension:
# Note: we use a different marketplace than VS Code. See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
RUN code-server --install-extension esbenp.prettier-vscode
RUN code-server --install-extension saoudrizwan.claude-dev

# Install global npm packages that are commonly used
RUN sudo npm install -g \
create-react-app \
create-vite \
typescript \
ts-node \
nodemon \
pm2 \
serve

# Create a global Python virtual environment for common packages
RUN python3 -m venv ~/.venv
RUN source ~/.venv/bin/activate

# Install common Python packages in the virtual environment
RUN pip install \
requests \
flask \
django \
fastapi \
uvicorn \
jupyter \
pandas \
numpy \
matplotlib \
seaborn

# Add virtual environment to bashrc so it's always activated
RUN echo 'source ~/.venv/bin/activate' >> ~/.bashrc


# Copy files: 
COPY deploy-container/myTool /home/coder/myTool

# -----------

# Port
ENV PORT=8080

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
