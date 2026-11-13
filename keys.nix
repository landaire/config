# SSH public keys shared by authorized_keys and the agenix recipients in
# secrets/secrets.nix, which is evaluated outside the flake.
{
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6CmOIY8QOpHzEN3otjDVxtabXC6evXnSBtdVHY9e95 landerbrandt@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfIfD4SY/F2kQLfLhc6M8iCK0zz8UOHo0Jj8UJNoDa9 lander@conficker.io"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICzPiahzSGQFXYWbaDmEtf/lRBybmCcfFLNaBmw6F/kZ landerbrandt@gmail.com"
  ];

  # Host keys from /etc/ssh/ssh_host_ed25519_key.pub, which agenix decrypts with.
  hosts = {
    junction = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDMZG5rMGht4wbZhSXdDp0wpJzTcbT4i2kUaLzHK6K/";
    caladan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkAzTAEEbXkgi02ML1kAf1U+dF1ryvUnaaFWHh5JUvv";
    rossak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAb/TCjUrt2zBBHOGI/sRcwFfXYYzfMsXcxPXMPe7jm3";
    richese = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgFxGzPINI25BGQbxYz8updAIDACArItCqSAdXVkM5x";
  };
}
