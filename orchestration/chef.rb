# Chef stub for Swarm node configuration
# TODO: Configure Chef knife and node discovery
# NOTE: Ensure Docker Engine and Docker Compose are installed on 'nodejs' nodes for orchestration.

# Discover nodes with role 'nodejs'
# TODO: Implement search for 'role:nodejs'

# For each node:
# TODO:
# - Check fnm installation (e.g., `fnm --version`)
# - Install fnm if missing via curl (e.g., `curl -fsSL https://fnm.vercel.app/install | bash`)
# - Use fnm to list and switch Node.js versions:
#     `fnm list`  
#     `fnm use 14`  
#     `fnm use 18`  
# - Ensure 'curl' package is installed (platform dependent, e.g., `package 'curl'`)
# - Run `curl --version` and capture output
# - Retrieve hostname: `execute 'hostname'` and log

# Placeholder recipe
Chef::Recipe.send(:include, FNMSupport)

FNMSupport.do_install_fnm
FNMSupport.do_manage_node_version(['14', '18'])
FNMSupport.do_install_package('curl')
FNMSupport.do_run_command('curl --version')
FNMSupport.do_run_command('hostname')
