My ideal shell development environment. Originally taken from a pair programming image https://github.com/dpetersen/dev-container-base

### Originally included
* SSH support (github user account used for SSH login permission)
* tmux
* neovim

### Modified to include
* custom VIM with plugins (racer, syntax-highlighting, and more)
* RVM (adjusted for FishShell)
* RVM: Ruby 2.4.0 installed with some basic gems included (rake, bundler, rails, github-auth)
* Rust version 1.15.1
* Fish Shell with custom Github centered prompt

# Original README

A container with my basic dev tools running on Ubuntu. ~~It does not have any languages or their specific tools installed.~~ This could be used as a base image for developing in a specific language. Access is via SSH with the account `dev`, which has sudo.

## Starting

The container exposes SSH and uses [GitHub's public key API](https://developer.github.com/v3/users/keys/) to add the keys for authorized users to `~/.ssh/authorized_keys` for the `dev` account. You must specify all of the allowed GitHub usernames as the `AUTHORIZED_GH_USERS` environment variable during `docker run`. Here's an example:

I start it like so:
```bash
docker run -d \
  -e AUTHORIZED_GH_USERS="dpetersen,otherperson" \
  -p 0.0.0.0:31981:22 \
  dpetersen/dev-container-base:latest
```

If the GitHub API is down or the user doesn't exist / has no keys, you'll get an error.

*You'll probably want to add some volume mounts to that command, so that your code isn't cloned inside of the container and potentially lost!*

Step 3: profit.

## Connecting

You have the running container, and now it's time to pair. Except you keep forgetting the IP address and the port and the username, and you're sick of having to copy your SSH private key over to the server. Do what the pros do and set up an alias! In `~/.ssh/config`, add something like this:

```
Host devbox
  HostName <YOUR IP OR HOSTNAME>
  Port <YOUR MAPPED SSH PORT FROM ABOVE>
  User dev
  ForwardAgent true
# Feel free to leave this out if you find it unsafe. I tear down
# my dev box frequently and am sick of the warnings about the 
# changed host.
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
```

And now can:

```bash
ssh devbox
```

And everything is magically handled for you! You may have to configure your SSH client to allow SSH forwarding, but it will allow you to `git push` to private repositories without having to authenticate every time, and without copying your key to the server (where it can be lost if the container stops).

