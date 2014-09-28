# deploy.rb

set :apt, 'apt-get -qyu'

default_run_options[:pty] = true

desc "Setup new server"
task :setup do
  firewall
  updates
  essential
  time
  lamp
  mail_config
  cleanup
  reboot
end

desc "Remove unused packages"
task :cleanup do
  sudo "#{apt} autoremove"
end

desc "Update software currently installed"
task :updates do
  sudo "#{apt} update"
  sudo "#{apt} upgrade"
end

desc "Setup firewall"
task :firewall do
  sudo "ufw allow ssh"
  sudo "ufw allow http"
  sudo "ufw allow https"
  sudo "ufw enable" do |channel, stream, out|
    channel.send_data 'y'+"\n" if out =~ /Command may disrupt existing ssh connections. Proceed with operation (y|n)?/
  end
end

desc "Setup NTP and select timezone"
task :time do
  sudo "#{apt} install ntp"
  sudo "echo America/Los_Angeles | sudo tee /etc/timezone &> /dev/null"
  sudo "dpkg-reconfigure -f noninteractive tzdata"
end

desc "Install LAMP server"
task :lamp do
  if exists?(:mysql_password) == false
    set :mysql_password, Capistrano::CLI.password_prompt('MySQL Root Password: ')
  end
  sudo "#{apt} install lamp-server^" do |channel, stream, data|
    channel.send_data("#{mysql_password}\n\r") if data =~ /password/
  end

  apache_configure
  mysql_secure
  php_configure

end

desc "Install essential tools"
task :essential do
  sudo "#{apt} install build-essential finger libreadline-dev ncurses-dev git-core mercurial"
end

desc "Reboot system"
task :reboot  do
  sudo "shutdown -r now"
end

desc "Improve MySQL security"
task :mysql_secure do
  if exists?(:mysql_password) == false
    set :mysql_password, Capistrano::CLI.password_prompt('MySQL Root Password: ')
  end

  run "mysql -B -u root -p -e \"
    DELETE FROM mysql.user WHERE USER='';
    DELETE FROM mysql.user WHERE USER='root' AND HOST NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;\"" do |channel, stream, data|
    channel.send_data("#{mysql_password}\n\r") if data =~ /Enter password:/
  end
end

desc "Configure Apache"
task :apache_configure do
  sudo "sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf.d/security"
  sudo "sed -i 's/ServerSignature On/#ServerSignature On/' /etc/apache2/conf.d/security"
  sudo "sed -i 's/#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf.d/security"
  sudo "a2dismod autoindex status negotiation"
  sudo "a2enmod rewrite ssl"
  sudo "a2dissite default"
  sudo "apache2ctl restart"
end

desc "Configure PHP"
task :php_configure do
  sudo "sed -i 's/expose_php = On/expose_php = Off/' /etc/php5/apache2/php.ini"
  sudo "sed -i 's#;date.timezone =#date.timezone = America/Los_Angeles#' /etc/php5/apache2/php.ini"
end

desc "Enable sending mail"
task :mail_config do
  sudo "#{apt} install exim4-daemon-light mailutils mutt"
  sudo "cp /etc/exim4/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf.orig"
  upload "assets/update-exim4.conf.conf", "/tmp/update-exim4.conf.conf", :via => :scp
  sudo "mv /tmp/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf"
  sudo "sed -i 's/<HOSTNAME>/$CAPISTRANO:HOST$/' /etc/exim4/update-exim4.conf.conf"
  sudo "chown root:root /etc/exim4/update-exim4.conf.conf"
  sudo "update-exim4.conf"
end