#!/usr/bin/ruby

USERS = ARGV[0] || ENV["AUTHORIZED_GH_USERS"]

begin
  `mkdir --mode=700 /home/dev/.ssh`
  `touch /home/dev/.ssh/authorized_keys`
  `chmod 600 /home/dev/.ssh/authorized_keys`
  USERS.split(",").map(&:strip).each do |username|
    output = `/usr/bin/fish -l -c 'gh-auth add --users=#{username}'`
    if output.include?("Adding 0 key")
      puts <<-EOS
        The user '#{username}' either does not exist on GitHub or does not have
        any SSH keys uploaded!
      EOS
      exit 1
    end

    puts "Authorized SSH key(s) for #{username}..."
  end
rescue
  puts <<-EOS
    You need to specify environment variables as a comma-separated list of GitHub
    users whose SSH keys should be authorized to connect to this machine!
  EOS
  exit 1
end
