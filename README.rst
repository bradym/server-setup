server-setup
------------

server-setup is used for setting up new Ubuntu servers with a single command
using `capistrano <https://github.com/capistrano/capistrano>`_. This is meant
for people who occasionally setup a new server, not for people who need to
manage large numbers of servers and ensure that the same version of software is
used everywhere.

Dependencies
------------

1. An Ubuntu box you can login to via ssh and a user with sudo access.
2. `Capistrano <https://github.com/capistrano/capistrano>`_ installed locally

Usage
-----

cap -T will show you the available tasks:

::

    $ cap -T
    cap apache_configure # Configure Apache
    cap cleanup          # Remove unused packages
    cap essential        # Install essential tools
    cap firewall         # Setup firewall
    cap invoke           # Invoke a single command on the remote servers.
    cap lamp             # Install LAMP server
    cap mail_config      # Enable sending mail
    cap mysql_secure     # Improve MySQL security
    cap php_configure    # Configure PHP
    cap reboot           # Reboot system
    cap setup            # Setup new server
    cap shell            # Begin an interactive Capistrano session.
    cap time             # Setup NTP and select timezone
    cap updates          # Update software currently installed

You can run any of these tasks individually, or you can use the setup task
to run all setup tasks sequentially. Take a look at config/deploy.rb for
details on what the tasks do.

When running tasks, you'll need to define the server(s) where you want to
run the tasks by setting the HOSTS variable:

To setup a single server:

::

    cap setup HOSTS=example.com

To setup multiple servers:

::

    cap setup HOSTS=host1.example.com,host2.example.com


Contributing
------------

If you'd like to contribute please fork the repo and make any changes then submit your changes as pull requests.

If you find this useful, let me know what could be done to improve it by submitting issues.

