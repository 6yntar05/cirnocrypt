# cirnocrypt
Change boring partition decrypt text to ascii cirno greeting <br>
###### Only for ArchLinux for now

## Installing
- `git clone https://github.com/6yntar05/cirnocrypt`
- `cd cirnocrypt`
- `sudo sh install.sh`
- Replace "encrypt" hook to "cirnocrypt" in /etc/mkinitcpio.conf (by hands for now)
- `sudo mkinitcpio -P` (by hands for now)

## Uninstalling
- Replace "cirnocrypt" hook to "encrypt" in /etc/mkinitcpio.conf
- `sudo mkinitcpio -P`