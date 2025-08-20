# Orchestration Stubs

This folder contains template stubs for using different orchestration tools to manage Swarm nodes and perform system tasks:

- `pulumi.ts`: Pulumi TypeScript script for provisioning and remote command execution
- `chef.rb`: Chef recipe to configure nodes
- `ansible-playbook.yml`: Ansible playbook for orchestrating tasks

Each stub includes TODO comments outlining the steps to:

1. Detect nodes labeled as "nodejs"
2. Check and install [fnm (Fast Node Manager)](https://github.com/Schniz/fnm)
3. Downgrade and upgrade Node.js versions
4. Ensure `curl` is installed, run a curl command, and collect/report results
5. Check and report each node's hostname

Fill in the stub code with your infrastructure details and credentials to complete each task.
