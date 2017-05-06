FROM ubuntu:16.10
LABEL Maintainer="Daniel P. Clark <6ftdan@gmail.com>" \
      Version="1.0" \
      Description="Heroku version: No pair programming version (sshd failed to run)."

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

# Install Racer (Rust auto-completion for VIM)
    git clone https://github.com/phildawes/racer.git &&\
    cd racer &&\
    cargo build --release &&\
    mkdir /root/bin &&\
    mv ./target/release/racer /root/bin &&\
    cd .. &&\
    rm -rf racer &&\

# Clean up
    apt-get clean -y &&\
    apt-get autoremove -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy .vimrc
RUN curl -sL https://raw.githubusercontent.com/danielpclark/ruby-pair/master/.vimrc > /root/.vimrc &&\

# Install Vundle
    git clone https://github.com/VundleVim/Vundle.vim.git /root/.vim/bundle/Vundle.vim &&\

# Install VIM plugins
    HOME=/root vim +PluginInstall +qall &&\

# Manually update DB Ext plugin
    curl -L --create-dirs -o /root/.vim/bundle/dbext.vim/dbext_2500.zip http://www.vim.org/scripts/download_script.php\?src_id=24935 &&\
    cd /root/.vim/bundle/dbext.vim/ &&\
    unzip dbext_2500.zip &&\
    rm dbext_2500.zip &&\
    cd - &&\

# Set up for tmux
    apt-get update &&\
    apt-get install -y tmux &&\

# Install fish
    apt-get install -y fish &&\
    curl -L --create-dirs -o /root/.config/fish/functions/fish_prompt.fish https://raw.githubusercontent.com/danielpclark/fish_prompt/master/fish_prompt.fish &&\

# Install a couple of helpful utilities
    apt-get install -y ack-grep &&\

# Fix for occasional errors in perl stuff (git, ack) saying that locale vars
# aren't set.
    locale-gen en_US en_US.UTF-8 && dpkg-reconfigure locales &&\

    ln -s /root /home/dev &&\

# Clean up
    apt-get clean -y &&\
    apt-get autoremove -y &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\

RUN \
# Install RVM
    sudo apt-get update &&\
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 &&\
    curl -sSL https://get.rvm.io | sudo bash -s stable --ruby=$RUBY_VERSION &&\
    curl -L --create-dirs -o /root/.config/fish/functions/rvm.fish https://raw.github.com/lunks/fish-nuggets/master/functions/rvm.fish &&\
    echo "rvm default" >> /root/.config/fish/config.fish &&\

# Startup script
    echo '#!/bin/bash\n\n\
export HOME=/root\n\
export XDG_CONFIG_HOME=/root/.config\n\
export WORKDIR=/root\n\
export rvm_path=/usr/local/rvm\n\
export rvm_prefix=/usr/local\n\
export rvm_bin_path=/usr/local/rvm/bin\n\
export rvm_delete_flag=0\n' > /root/bin/startup.sh &&\
    chmod +x /root/bin/startup.sh &&\


# Clean up
    sudo apt-get clean -y &&\
    sudo apt-get autoremove -y &&\
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\

# Locale
    sudo locale-gen "en_US.UTF-8"

# Install the Github Auth gem, which will be used to get SSH keys from GitHub
# to authorize users for SSH
    RUN /bin/bash -c "source /usr/local/rvm/scripts/rvm;rvm use $RUBY_VERSION;gem install rake bundler rails github-auth git-duet seeing_is_believing --no-rdoc --no-ri"

CMD /root/bin/startup.sh
