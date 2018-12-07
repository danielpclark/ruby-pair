My ideal shell development environment. Originally taken from a pair programming image https://github.com/dpetersen/dev-container-base

## Includes
* Ubuntu 18.04
* SSH support (github user account used for SSH login permission)
* tmux
* VIM (compiled in container) with plugins (racer, ctags, YouCompleteMe, syntax-highlighting, and more)
* neovim
* RVM: Ruby 2.5.3 installed with some basic gems included (rake, bundler, github-auth)
* RVM (adjusted for FishShell)
* Rust version 1.31.0
* NodeJS
* Yarn
* Fish Shell with custom Github centeric prompt
* NGROK — for remote users to easily join you through ngrok.com

## Starting

The container exposes SSH and uses [GitHub's public key API](https://developer.github.com/v3/users/keys/) to add the keys for authorized users to `~/.ssh/authorized_keys` for the `dev` account. You must specify all of the allowed GitHub usernames as the `AUTHORIZED_GH_USERS` environment variable during `docker run`. Here's an example:

I start it like so:
```bash
docker run -d \
  -e AUTHORIZED_GH_USERS="dpetersen,otherperson" \
  -e NGROK="your-ngrok-API-key-here"
  -p 2222:22 \
  danielpclark/ruby-pair:latest
```

If the GitHub API is down or the user doesn't exist / has no keys, you'll get an error.

*You'll probably want to add some volume mounts to that command, so that your code isn't cloned inside of the container and potentially lost!*

Step 3: profit.

## Connecting

When the image boots up it runs ngrok with the key you provide and gives you a URL you can have some one SSH into remotely.
You yourself can ssh in locally.  If you set `-p 2222:22` on your `docker run` command then you can simply `ssh dev@localhost -p 2222`.
This docker image will use your public SSH keys from the Github username you provided via `AUTHORIZED_GH_USERS` so there's no need for entering a password.

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

And everything is handled for you! You may have to configure your SSH client to allow SSH forwarding, but it will allow you to `git push` to private repositories without having to authenticate every time, and without copying your key to the server (where it can be lost if the container stops).

