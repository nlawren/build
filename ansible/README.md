# Examples and comments

Look into the correct use of the ansible.cfg file.

An example of an adhoc command:

 ansible ubuntu -m ansible.builtin.shell -a 'uptime' -i ./inventory/hosts --user serveradmin
