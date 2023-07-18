# Examples and comments

An example of an adhoc command:

 ansible ubuntu -m ansible.builtin.shell -a 'uptime' -i ./inventory/hosts --user serveradmin
