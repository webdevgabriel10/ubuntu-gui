# Use the official Ubuntu base image
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    ubuntu-desktop \
    xfce4 \
    xfce4-goodies \
    xorg \
    dbus-x11 \
    x11-xserver-utils \
    sudo \
    xrdp \
    tightvncserver \
    firefox \
    gnome-themes-standard \
    yaru-theme-gtk \
    yaru-theme-icon \
    yaru-theme-sound \
    dconf-cli \
    && apt-get clean

# Create a user for running VNC server
RUN useradd -ms /bin/bash vncuser && echo 'vncuser:vncpassword' | chpasswd && adduser vncuser sudo

# Allow vncuser to run sudo commands without a password
RUN echo 'vncuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Set environment variables for the VNC server
ENV USER=vncuser
ENV PASSWORD=vncpassword

# Switch to the new user
USER vncuser
WORKDIR /home/vncuser

# Set up the VNC server
RUN mkdir -p ~/.vnc && \
    echo "$PASSWORD" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Configure XRDP to use Xfce
RUN echo "xfce4-session" > ~/.xsession

# Create the .Xauthority file
RUN touch /home/vncuser/.Xauthority

# Configure XFCE to use the Yaru theme
RUN mkdir -p /home/vncuser/.config/xfce4/xfconf/xfce-perchannel-xml
RUN echo '<?xml version="1.0" encoding="UTF-8"?>\
<channel name="xsettings" version="1.0">\
  <property name="Net" type="empty">\
    <property name="ThemeName" type="string" value="Yaru"/>\
    <property name="IconThemeName" type="string" value="Yaru"/>\
  </property>\
</channel>' > /home/vncuser/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

# Add a script to clean up existing VNC servers and lock files
RUN echo '#!/bin/bash\n\
vncserver -kill :1 &> /dev/null || true\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
vncserver :1 -geometry 1920x1080 -depth 24\n\
sudo service xrdp start\n\
tail -f /dev/null' > /home/vncuser/startup.sh

RUN chmod +x /home/vncuser/startup.sh

# Expose VNC and RDP ports
EXPOSE 5901
EXPOSE 3389

# Start the VNC and XRDP servers using the startup script
CMD ["/home/vncuser/startup.sh"]
