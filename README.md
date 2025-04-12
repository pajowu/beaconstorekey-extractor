# Extracting BeaconStore key for decrypting searchpartyd data

This repository describes the process and provides the tools that allows extracting the aes key used by Apples searchpartyd (the deamon amongst other things powering FindMy on macOS) to encrypt its files.
_This procedure should work at least for macOS 15 (Sequoia)_

Extracting this key only needs to be done once, it can be used the decrypt the searchpartyd-files afterwards again and again.

> **Warning:** This procedure requires to temporarily disable some of macOS' security features! Use at your own risk.

## Credits

This repo and the description below is derived from seemoolab's [airdrop-keychain-extractor](https://github.com/seemoo-lab/airdrop-keychain-extractor).

## 1. Disable System Integrity Protection

> **Warning:** This steps disables some of macOS' security features! Use at your own risk. Please continue until Step 4 to re-enabled them!

Since macOS 15 (Sequoia), the BeaconStoreKey can only be queried from the keychain by binaries which have the correct `keychain-access-group`-entitlement (`com.apple.icloud.searchpartyuseragent`).
Since this is an Apple-internal entitlement, we have to disable `amfid` that checks binary signatures and enforces the system's policies.

To do this, we first need to disable SIP via macOS' recovery mode. Start up your computer in recover mode. The procedure is described in the apple docs

- [Instructions for Intel-Macs](https://support.apple.com/en-gb/guide/mac-help/mchl338cf9a8/15.0/mac/15.0#mchl69906860)
- [Instructions for Apple-Silicon-Macs](https://support.apple.com/en-gb/guide/mac-help/mchl82829c17/15.0/mac/15.0#mchl5abfbb29)

In recovery mode, open the terminal and enter

```
csrutil enable --without nvram
```

and reboot the Mac. Then, add the following boot parameter via the Terminal

```
sudo nvram boot-args="amfi_get_out_of_my_way=1"
```

and reboot again.

> **Note**: If running the extractor fails on your machine, you might need to disable SIP entirely by rebooting into recovery mode and running
>
> ```
> csrutil disable
> ```

To restore full SIP later, reboot in macOS' recovery mode and run

```
nvram -d boot-args
csrutil enable
```

## 2. Build and run the extractor

We build and run the extraction utility (note that you need a developer certificate for this):

```
git clone https://github.com/pajowu/beaconstorekey-extractor.git
cd beaconstorekey-extractor
make run
```

The program will output the extracted key, which you can use to decrypt the searchpartyd-files

> **Note**: After re-enabling SIP you will have to go through all the steps again to extract the key again, so better save if somewhere now!

## 3. Re-enable the important security features you just disabled

To restore full SIP, reboot in macOS' recovery mode and run

```
nvram -d boot-args
csrutil enable
```

## 4. Decrypt the searchpartyd-files

You can use this key to decrypt the searchpartyd-files using

```
make decrypt
```

This will ask you for the key you extracted in step 2
