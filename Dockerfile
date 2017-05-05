FROM ubuntu:16.10
LABEL Maintainer="Daniel P. Clark <6ftdan@gmail.com>" \
      Version="1.0" \
      Description="Heroku version: Remote pair programming environment with Ruby, Rust, VIM, RVM, neovim, tmux, SSH, and FishShell."

ENV USER root
ENV RUST_VERSION=1.16.0
ENV RUBY_VERSION=2.4.1

# Start by changing the apt output, as stolen from Discourse's Dockerfiles.
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections &&\
# Probably a good idea
    apt-get update &&\

# Basic dev tools (Custom VIM build needed for plugins)
    apt-get install -y sudo openssh-client git build-essential \
        ctags man curl direnv software-properties-common curl \
        libncurses5-dev libgnome2-dev libgnomeui-dev wget pkg-config \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev libssl-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        ruby-dev lua5.1 liblua5.1-0-dev libperl-dev nano &&\

# Clean up
    apt-get clean -y &&\
    apt-get autoremove -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Begin VIM build & install
RUN git clone https://github.com/vim/vim.git &&\
    cd vim &&\
    git checkout v8.0.0476 &&\
    ./configure --with-features=huge \
                --enable-multibyte \
                --enable-rubyinterp=yes \
                --enable-pythoninterp=yes \
                --with-python-config-dir=/usr/lib/python2.7/config \
                --enable-perlinterp=yes \
                --enable-luainterp=yes \
                --enable-gui=gtk2 --enable-cscope --prefix=/usr &&\
    make VIMRUNTIMEDIR=/usr/share/vim/vim80 &&\
    make install &&\
    cd .. &&\
    rm -rf vim &&\
    update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1 &&\
    update-alternatives --set editor /usr/bin/vim &&\
    update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1 &&\
    update-alternatives --set vi /usr/bin/vim &&\

# Install Rust
    curl -sO https://static.rust-lang.org/dist/rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.gz &&\
    tar -xzf rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.gz &&\
    ./rust-$RUST_VERSION-x86_64-unknown-linux-gnu/install.sh --without=rust-docs &&\
    rm -rf rust-$RUST_VERSION-x86_64-unknown-linux-gnu rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.gz &&\

# Make home directory
    mkdir /home/dev &&\

# Install Racer (Rust auto-completion for VIM)
    git clone https://github.com/phildawes/racer.git &&\
    cd racer &&\
    cargo build --release &&\
    mkdir /home/dev/bin &&\
    mv ./target/release/racer /home/dev/bin &&\
    cd .. &&\
    rm -rf racer &&\

# Clean up
    apt-get clean -y &&\
    apt-get autoremove -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy .vimrc
RUN curl -sL https://raw.githubusercontent.com/danielpclark/ruby-pair/master/.vimrc > /home/dev/.vimrc &&\

# Install Vundle
    git clone https://github.com/VundleVim/Vundle.vim.git /home/dev/.vim/bundle/Vundle.vim &&\

# Install VIM plugins
    HOME=/home/dev vim +PluginInstall +qall &&\

# Manually update DB Ext plugin
    curl -L --create-dirs -o /home/dev/.vim/bundle/dbext.vim/dbext_2500.zip http://www.vim.org/scripts/download_script.php\?src_id=24935 &&\
    cd /home/dev/.vim/bundle/dbext.vim/ &&\
    unzip dbext_2500.zip &&\
    rm dbext_2500.zip &&\
    cd - &&\

# Set up for pairing with wemux and install neovim
    add-apt-repository ppa:neovim-ppa/unstable &&\
    apt-get update &&\
    apt-get install -y tmux neovim &&\
    git clone git://github.com/zolrath/wemux.git /usr/local/share/wemux &&\
    ln -s /usr/local/share/wemux/wemux /usr/local/bin/wemux &&\
    cp /usr/local/share/wemux/wemux.conf.example /usr/local/etc/wemux.conf &&\
    echo "host_list=(dev)" >> /usr/local/etc/wemux.conf &&\

# Install fish
    apt-get install -y fish &&\
    curl -L --create-dirs -o /home/dev/.config/fish/functions/fish_prompt.fish https://raw.githubusercontent.com/danielpclark/fish_prompt/master/fish_prompt.fish &&\

# Install a couple of helpful utilities
    apt-get install -y ack-grep &&\

# Set up SSH. We set up SSH forwarding so that transactions like git pushes
# from the container happen magically.
    apt-get install -y openssh-server &&\
    mkdir /var/run/sshd &&\
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config &&\

# Fix for occasional errors in perl stuff (git, ack) saying that locale vars
# aren't set.
    locale-gen en_US en_US.UTF-8 && dpkg-reconfigure locales &&\

    useradd dev -d /home/dev -m -s /usr/bin/fish &&\
    adduser dev sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&\

# Clean up
    apt-get clean -y &&\
    apt-get autoremove -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\

# Ownership
    chown -R dev.dev /home/dev &&\
    chown -R dev.dev /var/lib/gems

#USER dev

#ADD bin/ssh_key_adder.rb /home/dev/bin/ssh_key_adder.rb

RUN \
# Setup neovim
    ln -s /home/dev/.vim /home/dev/.config/nvim &&\
    ln -s /home/dev/.vimrc /home/dev/.config/nvim/init.vim &&\
 
# Install RVM
    sudo apt-get update &&\
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 &&\
    curl -sSL https://get.rvm.io | sudo bash -s stable --ruby=$RUBY_VERSION &&\
    curl -L --create-dirs -o /home/dev/.config/fish/functions/rvm.fish https://raw.github.com/lunks/fish-nuggets/master/functions/rvm.fish &&\
    echo "rvm default" >> /home/dev/.config/fish/config.fish &&\

# SSH script, ngrok, and startup script
    curl -sL -o /home/dev/bin/ssh_key_adder.rb https://raw.githubusercontent.com/danielpclark/ruby-pair/master/ssh_key_adder.rb &&\
    chmod +x /home/dev/bin/ssh_key_adder.rb &&\
    wget -O /home/dev/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip &&\
    unzip -d /usr/bin /home/dev/ngrok.zip &&\
    rm /home/dev/ngrok.zip &&\
    echo '#!/bin/bash\n\n\
AUTHORIZED_GH_USERS=$1 /home/dev/bin/ssh_key_adder.rb\n\
sudo /usr/sbin/sshd\n\
echo "web_addr: 0.0.0.0:$PORT" > /home/dev/.ngrok2/ngrok.yml
/usr/bin/ngrok authtoken $2\n\
/usr/bin/ngrok tcp 22\n' > /home/dev/bin/startup.sh &&\
    chmod +x /home/dev/bin/startup.sh &&\


# Clean up
    sudo apt-get clean -y &&\
    sudo apt-get autoremove -y &&\
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\

# Locale
    sudo locale-gen "en_US.UTF-8"

# Install the Github Auth gem, which will be used to get SSH keys from GitHub
# to authorize users for SSH
    RUN /bin/bash -c "source ~/.rvm/scripts/rvm;rvm use $RUBY_VERSION;gem install rake bundler rails github-auth git-duet seeing_is_believing --no-rdoc --no-ri"

# Expose SSH (local only, not Heroku)
EXPOSE 22

# Install the SSH keys of ENV-configured GitHub users before running the SSH
# server process.
CMD /home/dev/bin/startup.sh $GH_USERS $NGROK
