# Examples and comments

Look into the correct use of the ansible.cfg file.

An example of an adhoc command:

`ansible apt -m ansible.builtin.shell -a 'uptime' -i ./inventory/hosts --user serveradmin`

Note: the "apt" entry refers to the filter applied to the inventory list.

## Todo

[] In the add user playbook, need to add the correct nopasswd into /etc/sudoers.
